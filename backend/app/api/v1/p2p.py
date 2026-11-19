"""
PayNora App-to-App (P2P) Transfers.

Moves money between two PayNora wallets entirely on the internal ledger:
no bank, no payout gateway, settles instantly.

Flow:
  1. GET  /p2p/lookup?q=<phone | email | @tag>  -> verified recipient (name, country, local currency)
  2. GET  /p2p/quote                           -> what the recipient will receive
  3. POST /p2p/transfer (Idempotency-Key)      -> debit sender, credit recipient atomically
"""
from decimal import Decimal, ROUND_DOWN
from datetime import datetime
from typing import Dict, Any, Optional, List
import re
import threading
import uuid

from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from pydantic import BaseModel, Field

from app.api.v1.auth import get_current_user
from app.auth.store import USERS_DB
from app.config import settings
from app.wallets.models import WalletEngine, resolve_local_currency, resolve_foreign_currency, DEFAULT_FOREIGN_CURRENCIES

router = APIRouter(prefix="/p2p", tags=["App-to-App Transfers"])

# Rates expressed as units of currency per 1 USD (cross rates computed via USD).
USD_RATES: Dict[str, Decimal] = {
    "USD": Decimal("1"),
    "GBP": Decimal("0.78125"),
    "EUR": Decimal("0.92"),
    "NGN": Decimal("1500.00"),
    "GHS": Decimal("15.40"),
    "KES": Decimal("129.00"),
    "ZAR": Decimal("18.20"),
    "CAD": Decimal("1.37"),
    "AED": Decimal("3.6725"),
}

P2P_FEE_RATE = Decimal("0.003")      # 0.3% FX margin only when currency changes
P2P_MAX_SINGLE = Decimal("10000")    # USD-equivalent cap per transfer (pre-KYC tier guard)

_LEDGER_LOCK = threading.Lock()
P2P_TRANSFERS: List[Dict[str, Any]] = []
P2P_IDEMPOTENCY: Dict[str, Dict[str, Any]] = {}

# ---------------------------------------------------------------------------
# Demo directory (development only) so lookups work on a fresh in-memory DB.
# ---------------------------------------------------------------------------
_DEMO_USERS = [
    {"user_id": "usr_demo_chidi", "first_name": "Chidi", "last_name": "Amadi", "email": "chidi@paynora.com",
     "phone": "+2348031234567", "tag": "chidi", "country_iso": "NG"},
    {"user_id": "usr_demo_sarah", "first_name": "Sarah", "last_name": "Thompson", "email": "sarah@paynora.com",
     "phone": "+447700900123", "tag": "sarah", "country_iso": "GB"},
    {"user_id": "usr_demo_kwame", "first_name": "Kwame", "last_name": "Mensah", "email": "kwame@paynora.com",
     "phone": "+233241234567", "tag": "kwame", "country_iso": "GH"},
]


def _seed_demo_directory() -> None:
    if settings.ENV.lower() == "production":
        return
    for u in _DEMO_USERS:
        if u["user_id"] not in USERS_DB:
            USERS_DB[u["user_id"]] = {
                **u,
                "is_email_verified": True,
                "is_phone_verified": True,
                "kyc_status": "VERIFIED",
                "roles": ["CUSTOMER"],
                "account_capabilities": ["VIEW_ACCOUNT", "SEND_MONEY", "RECEIVE_MONEY"],
                "created_at": "2026-10-04T11:35:00Z",
            }


_seed_demo_directory()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _digits(s: str) -> str:
    return re.sub(r"\D", "", s or "")


def _find_user(query: str) -> Optional[Dict[str, Any]]:
    q = (query or "").strip()
    if not q:
        return None
    if q.startswith("@"):
        tag = q[1:].lower()
        return next((u for u in USERS_DB.values() if (u.get("tag") or "").lower() == tag), None)
    if "@" in q:
        email = q.lower()
        return next((u for u in USERS_DB.values() if (u.get("email") or "").lower() == email), None)
    d = _digits(q)
    if len(d) < 7:
        return None
    # Match on trailing 10 digits so 0803..., 234803..., +234803... all resolve.
    tail = d[-10:]
    return next((u for u in USERS_DB.values() if _digits(u.get("phone", "")).endswith(tail)), None)


def _mask_name(user: Dict[str, Any]) -> str:
    first = (user.get("first_name") or "").strip()
    last = (user.get("last_name") or "").strip()
    return f"{first} {last}".strip().upper() or "PAYNORA USER"


def _rate(src: str, dst: str) -> Decimal:
    if src not in USD_RATES or dst not in USD_RATES:
        raise HTTPException(status_code=400, detail=f"Currency pair {src}/{dst} is not supported yet.")
    return USD_RATES[dst] / USD_RATES[src]


def _wallet(user_id: str, currency: str) -> Optional[Dict[str, Any]]:
    return next((w for w in WalletEngine.get_user_wallets(user_id) if w["currency"] == currency), None)


def _q2(x: Decimal) -> Decimal:
    return x.quantize(Decimal("0.01"), rounding=ROUND_DOWN)


def _build_quote(src: str, amount: Decimal, recipient: Dict[str, Any], receive_mode: str) -> Dict[str, Any]:
    recipient_local = resolve_local_currency(recipient["user_id"])
    recipient_foreign = resolve_foreign_currency(recipient_local)
    if receive_mode == "LOCAL":
        dst = recipient_local
    else:
        # Recipient has strictly 2 wallets: their Local Currency + their Foreign Currency (USD, or GBP for US users).
        held = {recipient_local, recipient_foreign}
        dst = src if src in held else recipient_foreign

    if src == dst:
        fee = Decimal("0.00")
        rate = Decimal("1")
    else:
        fee = _q2(amount * P2P_FEE_RATE)
        rate = _rate(src, dst)
    receive = _q2((amount - fee) * rate)
    return {
        "source_currency": src,
        "source_amount": str(_q2(amount)),
        "fee": str(fee),
        "exchange_rate": str(rate.quantize(Decimal("0.000001"))),
        "destination_currency": dst,
        "destination_amount": str(receive),
        "receive_mode": receive_mode,
        "settlement": "INSTANT",
    }


# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------
class P2PTransferRequest(BaseModel):
    recipient_user_id: str
    source_currency: str = Field(..., min_length=3, max_length=3)
    amount: str
    receive_mode: str = "LOCAL"   # LOCAL | ORIGINAL
    note: Optional[str] = Field(None, max_length=120)


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------
@router.get("/lookup")
def lookup_recipient(q: str = Query(..., min_length=3), current_user: dict = Depends(get_current_user)):
    """Find a PayNora user by phone number, email, or @tag."""
    user = _find_user(q)
    if not user:
        return {"found": False, "query": q}
    if user["user_id"] == current_user["user_id"]:
        raise HTTPException(status_code=400, detail="You cannot send money to yourself.")
    return {
        "found": True,
        "user_id": user["user_id"],
        "display_name": _mask_name(user),
        "tag": f"@{user['tag']}" if user.get("tag") else None,
        "country_iso": (user.get("country_iso") or "NG").upper(),
        "local_currency": resolve_local_currency(user["user_id"]),
        "verified": user.get("kyc_status") == "VERIFIED",
    }


@router.get("/quote")
def quote_p2p(
    recipient_user_id: str,
    source_currency: str,
    amount: str,
    receive_mode: str = "LOCAL",
    current_user: dict = Depends(get_current_user),
):
    recipient = USERS_DB.get(recipient_user_id)
    if not recipient:
        raise HTTPException(status_code=404, detail="Recipient not found.")
    try:
        amt = Decimal(amount)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid amount.")
    if amt <= 0:
        raise HTTPException(status_code=400, detail="Amount must be greater than zero.")
    return _build_quote(source_currency.upper(), amt, recipient, receive_mode.upper())


@router.post("/transfer", status_code=status.HTTP_201_CREATED)
def p2p_transfer(
    payload: P2PTransferRequest,
    idempotency_key: str = Header(..., alias="Idempotency-Key"),
    current_user: dict = Depends(get_current_user),
):
    """Instant wallet-to-wallet transfer between two PayNora users."""
    cache_key = f"{current_user['user_id']}:{idempotency_key}"
    if cache_key in P2P_IDEMPOTENCY:
        return P2P_IDEMPOTENCY[cache_key]

    sender_id = current_user["user_id"]
    recipient = USERS_DB.get(payload.recipient_user_id)
    if not recipient:
        raise HTTPException(status_code=404, detail="Recipient not found.")
    if recipient["user_id"] == sender_id:
        raise HTTPException(status_code=400, detail="You cannot send money to yourself.")

    src = payload.source_currency.upper()
    mode = payload.receive_mode.upper()
    if mode not in ("LOCAL", "ORIGINAL"):
        raise HTTPException(status_code=400, detail="receive_mode must be LOCAL or ORIGINAL.")
    try:
        amount = Decimal(payload.amount)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid amount.")
    if amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be greater than zero.")
    if amount / USD_RATES.get(src, Decimal("1")) > P2P_MAX_SINGLE:
        raise HTTPException(status_code=400, detail="Amount exceeds the single-transfer limit.")

    quote = _build_quote(src, amount, recipient, mode)
    dst = quote["destination_currency"]
    receive_amount = Decimal(quote["destination_amount"])

    with _LEDGER_LOCK:
        sender_wallet = _wallet(sender_id, src)
        if not sender_wallet:
            raise HTTPException(status_code=400, detail=f"You don't have a {src} wallet.")
        if Decimal(sender_wallet["available_balance"]) < amount:
            raise HTTPException(status_code=400, detail=f"Insufficient {src} balance.")
        recipient_wallet = _wallet(recipient["user_id"], dst)
        if not recipient_wallet:
            raise HTTPException(status_code=400, detail=f"Recipient cannot receive {dst}.")

        sender_wallet["available_balance"] = f"{Decimal(sender_wallet['available_balance']) - amount:.2f}"
        recipient_wallet["available_balance"] = f"{Decimal(recipient_wallet['available_balance']) + receive_amount:.2f}"

    record = {
        "transfer_id": f"p2p_{uuid.uuid4().hex[:12]}",
        "type": "APP_TO_APP",
        "state": "COMPLETED",
        "sender_user_id": sender_id,
        "recipient_user_id": recipient["user_id"],
        "recipient_name": _mask_name(recipient),
        **quote,
        "note": payload.note,
        "created_at": datetime.utcnow().isoformat() + "Z",
    }
    P2P_TRANSFERS.insert(0, record)
    P2P_IDEMPOTENCY[cache_key] = record

    try:
        from app.notifications.service import NotificationService
        NotificationService.dispatch(
            user_id=recipient["user_id"],
            title="Money Received",
            message=f"You received {dst} {receive_amount} on PayNora.",
            notification_type="CREDIT_ALERT",
            data={"transfer_id": record["transfer_id"]},
        )
    except Exception:
        pass

    return record


@router.get("/transfers")
def list_p2p_transfers(current_user: dict = Depends(get_current_user)):
    uid = current_user["user_id"]
    items = [t for t in P2P_TRANSFERS if uid in (t["sender_user_id"], t["recipient_user_id"])]
    return {"transfers": items, "count": len(items)}
