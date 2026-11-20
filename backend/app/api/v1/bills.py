"""
PayNora Bills & Utilities — NIGERIA ONLY.

Airtime, Mobile Data and Electricity are available only to Nigerian-resident accounts (NGN wallet)
and only for Nigerian phone numbers and Nigerian electricity meters.

- Mobile network: verified live (HLR / MNP lookup, so ported numbers are detected correctly) when a
  lookup key is configured; otherwise detected from the NCC numbering prefix and clearly flagged as
  unverified so the user can change it before paying. The network is re-checked server-side at purchase.
- Electricity: the meter is validated live against every Nigerian electricity company via Flutterwave.
  The company that recognises the meter is the detected company, and the customer name / address come
  from the utility itself. No guessing, no placeholder names.
"""
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from decimal import Decimal
import uuid
import random
import re
import httpx
from app.api.v1.auth import get_current_user
from app.wallets.models import WalletEngine, resolve_local_currency, persist_wallets_db
from app.storage import load_section, save_section
from app.config import settings
from app.providers.bill_lookup import (
    lookup_mobile_network,
    verify_meter,
    get_power_billers,
    flw_configured,
    NG_PREFIX_MAP,
    to_e164,
)

router = APIRouter(prefix="/bills", tags=["Bills & Utilities (Nigeria)"])
FLW_BASE = "https://api.flutterwave.com/v3"
FLW_BILLS_URL = f"{FLW_BASE}/bills"

SUPPORTED_COUNTRY = "NG"
NG_OPERATORS: List[Dict[str, str]] = [
    {"id": "mtn_ng", "name": "MTN Nigeria", "code": "MTN", "icon": "🟡"},
    {"id": "airtel_ng", "name": "Airtel Nigeria", "code": "AIRTEL", "icon": "🔴"},
    {"id": "glo_ng", "name": "Globacom (Glo)", "code": "GLO", "icon": "🟢"},
    {"id": "9mobile_ng", "name": "9mobile", "code": "9MOBILE", "icon": "🟢"},
]
NG_OPERATOR_CODES = {o["code"] for o in NG_OPERATORS}

# Static NG electricity companies (used only for display / manual selection when live list is unavailable)
NG_DISCOS: List[Dict[str, str]] = [
    {"code": "IKEDC", "name": "Ikeja Electric (IKEDC)"},
    {"code": "EKEDC", "name": "Eko Electricity (EKEDC)"},
    {"code": "AEDC", "name": "Abuja Electricity (AEDC)"},
    {"code": "IBEDC", "name": "Ibadan Electricity (IBEDC)"},
    {"code": "EEDC", "name": "Enugu Electricity (EEDC)"},
    {"code": "PHED", "name": "Port Harcourt Electricity (PHED)"},
    {"code": "KEDCO", "name": "Kano Electricity (KEDCO)"},
    {"code": "KAEDCO", "name": "Kaduna Electric (KAEDCO)"},
    {"code": "JED", "name": "Jos Electricity (JED)"},
    {"code": "BEDC", "name": "Benin Electricity (BEDC)"},
    {"code": "YEDC", "name": "Yola Electricity (YEDC)"},
]

# Fallback NGN data plans (used only when the live Flutterwave data catalogue is unavailable)
_FALLBACK_PLAN_PRICES = ["350.00", "600.00", "1500.00", "3500.00", "6500.00", "10000.00"]
_FALLBACK_PLAN_SPECS = [
    ("1gb_1d", "1GB Daily", "1GB", "1 Day"),
    ("2_5gb_2d", "2.5GB 2-Day", "2.5GB", "2 Days"),
    ("6gb_7d", "6GB Weekly", "6GB", "7 Days"),
    ("12gb_30d", "12GB Monthly", "12GB", "30 Days"),
    ("25gb_30d", "25GB Monthly", "25GB", "30 Days"),
    ("40gb_30d", "40GB Monthly", "40GB", "30 Days"),
]
_DATA_CATALOG_CACHE: Dict[str, Dict[str, Any]] = {}  # plan_id -> flutterwave item


# ---------------------------------------------------------------------------
# Nigeria lock
# ---------------------------------------------------------------------------
NIGERIA_ONLY_MSG = "Airtime, Data and Electricity payments are currently available in Nigeria only."


def _require_nigeria_request(country_iso: Optional[str]) -> None:
    if (country_iso or SUPPORTED_COUNTRY).upper() != SUPPORTED_COUNTRY:
        raise HTTPException(status_code=400, detail=NIGERIA_ONLY_MSG)


def _require_nigerian_user(current_user: dict) -> None:
    if (current_user.get("country_iso") or "").upper() != SUPPORTED_COUNTRY:
        raise HTTPException(status_code=403, detail=NIGERIA_ONLY_MSG + " Your account is registered outside Nigeria.")


def _require_nigerian_phone(phone: str) -> str:
    e164 = to_e164(phone, SUPPORTED_COUNTRY) or ""
    digits = re.sub(r"\D", "", e164)
    if not (digits.startswith("234") and len(digits) == 13):
        raise HTTPException(status_code=400, detail="Enter a valid 11-digit Nigerian phone number (e.g. 0803 123 4567).")
    return e164


def _ng_prefix_operator(phone: str) -> Optional[str]:
    e164 = to_e164(phone, SUPPORTED_COUNTRY) or ""
    d = re.sub(r"\D", "", e164)
    local = "0" + d[3:] if d.startswith("234") else d
    return NG_PREFIX_MAP.get(local[:4])


def _operator_name(code: str) -> str:
    return next((o["name"] for o in NG_OPERATORS if o["code"] == code), code)


# ---------------------------------------------------------------------------
# Request Schemas
# ---------------------------------------------------------------------------
class AirtimePurchaseRequest(BaseModel):
    phone_number: str
    operator_code: Optional[str] = None
    amount: str
    country_iso: str = SUPPORTED_COUNTRY


class DataBundlePurchaseRequest(BaseModel):
    phone_number: str
    operator_code: Optional[str] = None
    plan_id: str
    amount: str
    country_iso: str = SUPPORTED_COUNTRY


class ValidateMeterRequest(BaseModel):
    disco_code: Optional[str] = None  # optional manual company (Flutterwave biller_code)
    meter_number: str
    meter_type: str = "PREPAID"
    country_iso: str = SUPPORTED_COUNTRY


class ElectricityPaymentRequest(BaseModel):
    disco_code: Optional[str] = None
    meter_number: str
    meter_type: str = "PREPAID"
    amount: str
    customer_name: Optional[str] = None
    country_iso: str = SUPPORTED_COUNTRY


class AirtimeReversalRequest(BaseModel):
    transaction_id: str


class AirtimeToCashRequest(BaseModel):
    phone_number: str
    operator_code: Optional[str] = None
    airtime_amount: str
    category: str = "AIRTIME"  # AIRTIME, DATA, or ELECTRICITY
    share_pin: Optional[str] = None
    country_iso: str = SUPPORTED_COUNTRY


AIRTIME_TRANSACTIONS: Dict[str, Dict[str, Any]] = load_section("bills_transactions", {})
AIRTIME_TO_CASH_PAYOUT_RATE = Decimal("0.90")  # 90% cash payout (10% conversion fee)


def persist_bills_db() -> None:
    save_section("bills_transactions", AIRTIME_TRANSACTIONS)


def _local_wallet(user_id: str) -> Dict[str, Any]:
    wallets = WalletEngine.get_user_wallets(user_id)
    local_ccy = resolve_local_currency(user_id)
    w = next((w for w in wallets if w["currency"] == local_ccy), wallets[0] if wallets else None)
    if not w:
        raise HTTPException(status_code=400, detail="Local currency wallet not found.")
    return w


def _debit_local_wallet(user_id: str, amount: Decimal) -> Dict[str, Any]:
    w = _local_wallet(user_id)
    bal = Decimal(w["available_balance"])
    if bal < amount:
        raise HTTPException(status_code=400, detail=f"Insufficient {w['currency']} wallet balance.")
    w["available_balance"] = f"{(bal - amount):.2f}"
    persist_wallets_db()
    return w


def _credit_local_wallet(user_id: str, amount: Decimal) -> Dict[str, Any]:
    w = _local_wallet(user_id)
    w["available_balance"] = f"{(Decimal(w['available_balance']) + amount):.2f}"
    persist_wallets_db()
    return w


# ---------------------------------------------------------------------------
# Flutterwave bill payment
# ---------------------------------------------------------------------------
async def _call_flw_bills(customer: str, amount: Decimal, biller_type: str, reference: str) -> Optional[Dict[str, Any]]:
    """
    Execute a live bill payment via Flutterwave /v3/bills.
    - Airtime uses type="AIRTIME"
    - Data & Electricity use the exact item["biller_name"] from /v3/bill-categories
    Returns provider data on success, {"_error": msg} on rejection, or None when no live key is configured.
    """
    if not flw_configured():
        return None
    body = {
        "country": SUPPORTED_COUNTRY,
        "customer": customer,
        "amount": float(amount),
        "recurrence": "ONCE",
        "type": biller_type,
        "reference": reference,
    }
    headers = {"Authorization": f"Bearer {settings.FLW_SECRET_KEY}", "Content-Type": "application/json"}
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(FLW_BILLS_URL, json=body, headers=headers)
            data = resp.json()
        if resp.status_code in (200, 201) and data.get("status") == "success":
            return data.get("data") or {}
        msg = str(data.get("message") or "The bill provider rejected this payment.")
        if "insufficient funds in your wallet" in msg.lower():
            msg = "Flutterwave merchant wallet has insufficient NGN funds to vend this bill. Please top up your Flutterwave business wallet."
        return {"_error": msg}
    except Exception as e:
        return {"_error": f"Could not reach the bill provider ({e}). You have not been charged."}


# ---------------------------------------------------------------------------
# Network verification used by the app AND re-run at purchase time
# ---------------------------------------------------------------------------
async def _resolve_network(phone: str, user_selected: Optional[str]) -> Dict[str, Any]:
    """
    Decide which network to vend on:
      1. Live HLR result (handles ported numbers) always wins.
      2. Otherwise the network the user confirmed / selected in the app.
      3. Otherwise the NCC numbering prefix.
    """
    net = await lookup_mobile_network(phone, SUPPORTED_COUNTRY, NG_OPERATORS)
    selected = (user_selected or "").upper() or None
    if selected and selected not in NG_OPERATOR_CODES:
        raise HTTPException(status_code=400, detail="Unsupported network. Choose MTN, Airtel, Glo or 9mobile.")

    if net.get("detected") and net.get("verified") and net.get("operator_code") in NG_OPERATOR_CODES:
        code = net["operator_code"]
        return {
            "operator_code": code,
            "operator_name": _operator_name(code),
            "network_verified": True,
            "network_method": net.get("method"),
            "ported": net.get("ported"),
            "operator_corrected": bool(selected and selected != code),
        }
    code = selected or (net.get("operator_code") if net.get("detected") else None)
    if not code:
        raise HTTPException(status_code=400, detail="Please select the mobile network for this number.")
    return {
        "operator_code": code,
        "operator_name": _operator_name(code),
        "network_verified": False,
        "network_method": "USER_CONFIRMED" if selected else "NUMBER_PREFIX",
        "ported": None,
        "operator_corrected": False,
    }


# ---------------------------------------------------------------------------
# Data plans (live Flutterwave catalogue with fallback)
# ---------------------------------------------------------------------------
async def _live_data_plans(operator_code: str) -> List[Dict[str, Any]]:
    if not settings.FLW_SECRET_KEY:
        return []
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.get(
                f"{FLW_BASE}/bill-categories",
                params={"data_bundle": 1, "country": SUPPORTED_COUNTRY},
                headers={"Authorization": f"Bearer {settings.FLW_SECRET_KEY}"},
            )
            data = resp.json()
    except Exception:
        return []
    if data.get("status") != "success":
        return []
    op = operator_code.upper()
    keys = {"9MOBILE": ("9MOBILE", "ETISALAT")}.get(op, (op,))
    plans = []
    for item in data.get("data") or []:
        name = str(item.get("name") or item.get("biller_name") or "")
        if not any(k in name.upper() for k in keys):
            continue
        try:
            amount = Decimal(str(item.get("amount") or 0))
        except Exception:
            continue
        if amount <= 0:
            continue
        plan_id = f"flw_{item.get('item_code')}"
        _DATA_CATALOG_CACHE[plan_id] = item
        plans.append({
            "id": plan_id,
            "name": name,
            "allowance": name.replace(op, "").strip() or name,
            "validity": item.get("validity_period") and f"{item['validity_period']} days" or "",
            "amount": f"{amount:.2f}",
            "currency": "NGN",
            "live": True,
        })
    plans.sort(key=lambda p: Decimal(p["amount"]))
    return plans


def _fallback_data_plans(operator_code: str) -> List[Dict[str, Any]]:
    op = operator_code.upper()
    return [
        {"id": f"{op.lower()}_{pid}", "name": f"{op} {label}", "allowance": allow, "validity": validity,
         "amount": price, "currency": "NGN", "live": False}
        for (pid, label, allow, validity), price in zip(_FALLBACK_PLAN_SPECS, _FALLBACK_PLAN_PRICES)
    ]


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------
@router.get("/availability")
def bills_availability():
    return {"supported_countries": [SUPPORTED_COUNTRY], "message": NIGERIA_ONLY_MSG}


@router.get("/detect-operator")
async def detect_operator_endpoint(phone: str, country: str = SUPPORTED_COUNTRY):
    """Detect the CURRENT network of a Nigerian number (live HLR lookup handles ported numbers)."""
    _require_nigeria_request(country)
    digits = re.sub(r"\D", "", phone or "")
    if len(digits) < 10:
        return {"detected": False, "reason": "INCOMPLETE_NUMBER", "message": "Enter the full 11-digit number."}
    _require_nigerian_phone(phone)
    return await lookup_mobile_network(phone, SUPPORTED_COUNTRY, NG_OPERATORS)


@router.get("/operators")
def get_telco_operators(country: str = SUPPORTED_COUNTRY):
    _require_nigeria_request(country)
    return {"country": SUPPORTED_COUNTRY, "count": len(NG_OPERATORS), "operators": NG_OPERATORS}


@router.get("/data-plans")
async def get_data_plans(operator_code: str = "MTN", country: str = SUPPORTED_COUNTRY):
    _require_nigeria_request(country)
    op = operator_code.upper()
    if op not in NG_OPERATOR_CODES:
        raise HTTPException(status_code=400, detail="Unsupported network.")
    plans = await _live_data_plans(op)
    live = bool(plans)
    if not plans:
        plans = _fallback_data_plans(op)
    return {"operator": op, "country": SUPPORTED_COUNTRY, "live_catalog": live, "count": len(plans), "plans": plans}


@router.get("/electricity-providers")
async def get_electricity_providers(country: str = SUPPORTED_COUNTRY):
    """Nigerian electricity companies (live Flutterwave list when available) for manual selection."""
    _require_nigeria_request(country)
    billers = await get_power_billers(SUPPORTED_COUNTRY)
    if billers:
        seen, providers = set(), []
        for b in billers:
            if b["biller_code"] in seen:
                continue
            seen.add(b["biller_code"])
            providers.append({"code": b["biller_code"], "name": b["biller_name"] or b["name"]})
        return {"country": SUPPORTED_COUNTRY, "live": True, "count": len(providers), "providers": providers}
    return {"country": SUPPORTED_COUNTRY, "live": False, "count": len(NG_DISCOS), "providers": NG_DISCOS}


@router.post("/validate-meter")
async def validate_electricity_meter(payload: ValidateMeterRequest):
    """
    Auto-detect the electricity company AND the real meter owner by validating the meter live
    against every Nigerian electricity company.
    """
    _require_nigeria_request(payload.country_iso)
    meter = re.sub(r"\D", "", payload.meter_number)
    if not (10 <= len(meter) <= 13):
        raise HTTPException(status_code=400, detail="Nigerian meter numbers are 10–13 digits. Please check the number.")
    result = await verify_meter(meter, payload.meter_type, SUPPORTED_COUNTRY, payload.disco_code)
    if result["status"] == "UNAVAILABLE":
        raise HTTPException(status_code=503, detail=result["message"])
    if result["status"] != "VALID":
        raise HTTPException(status_code=404, detail=result["message"])
    return result


@router.post("/airtime")
async def purchase_airtime(payload: AirtimePurchaseRequest, current_user: dict = Depends(get_current_user)):
    _require_nigeria_request(payload.country_iso)
    _require_nigerian_user(current_user)
    _require_nigerian_phone(payload.phone_number)
    user_id = current_user["user_id"]
    amount = Decimal(payload.amount)
    if amount < Decimal("50"):
        raise HTTPException(status_code=400, detail="Minimum airtime amount is ₦50.")

    net = await _resolve_network(payload.phone_number, payload.operator_code)
    local_wallet = _debit_local_wallet(user_id, amount)
    tx_id = f"air_{uuid.uuid4().hex[:10]}"

    flw_res = await _call_flw_bills(payload.phone_number, amount, "AIRTIME", tx_id)
    if flw_res and "_error" in flw_res:
        _credit_local_wallet(user_id, amount)
        raise HTTPException(status_code=400, detail=f"{flw_res['_error']} Your wallet has been refunded.")

    record = {
        "status": "SUCCESSFUL",
        "category": "AIRTIME",
        "transaction_id": tx_id,
        "user_id": user_id,
        "provider_reference": (flw_res or {}).get("flw_ref", tx_id),
        "phone_number": payload.phone_number,
        "operator": net["operator_code"],
        **net,
        "amount": f"{amount:.2f}",
        "currency": local_wallet["currency"],
        "wallet_balance_after": local_wallet["available_balance"],
        "live_provider": flw_res is not None,
        "reversible": True,
        "reversed": False,
        "message": f"{net['operator_name']} airtime of ₦{amount:.2f} sent to {payload.phone_number}.",
    }
    AIRTIME_TRANSACTIONS[tx_id] = record
    persist_bills_db()
    return record


@router.post("/data")
async def purchase_data_bundle(payload: DataBundlePurchaseRequest, current_user: dict = Depends(get_current_user)):
    _require_nigeria_request(payload.country_iso)
    _require_nigerian_user(current_user)
    _require_nigerian_phone(payload.phone_number)
    user_id = current_user["user_id"]
    amount = Decimal(payload.amount)
    if amount <= Decimal("0"):
        raise HTTPException(status_code=400, detail="Data bundle amount must be greater than zero.")

    net = await _resolve_network(payload.phone_number, payload.operator_code)
    catalog_item = _DATA_CATALOG_CACHE.get(payload.plan_id)
    if not catalog_item and flw_configured():
        await _live_data_plans(net["operator_code"])
        catalog_item = _DATA_CATALOG_CACHE.get(payload.plan_id)
    if catalog_item and not any(k in str(catalog_item.get("name", "")).upper()
                                for k in ({"9MOBILE": ("9MOBILE", "ETISALAT")}.get(net["operator_code"], (net["operator_code"],)))):
        raise HTTPException(
            status_code=409,
            detail=f"This number is on {net['operator_name']}. Please choose a {net['operator_name']} data plan.",
        )
    if flw_configured() and not catalog_item:
        raise HTTPException(status_code=400, detail="This data plan is no longer available. Please reload the plans.")

    local_wallet = _debit_local_wallet(user_id, amount)
    tx_id = f"dat_{uuid.uuid4().hex[:10]}"
    biller_type = (catalog_item or {}).get("biller_name") or payload.plan_id
    flw_res = await _call_flw_bills(payload.phone_number, amount, biller_type, tx_id)
    if flw_res and "_error" in flw_res:
        _credit_local_wallet(user_id, amount)
        raise HTTPException(status_code=400, detail=f"{flw_res['_error']} Your wallet has been refunded.")

    record = {
        "status": "SUCCESSFUL",
        "category": "DATA",
        "transaction_id": tx_id,
        "user_id": user_id,
        "provider_reference": (flw_res or {}).get("flw_ref", tx_id),
        "phone_number": payload.phone_number,
        "operator": net["operator_code"],
        **net,
        "plan_id": payload.plan_id,
        "amount": f"{amount:.2f}",
        "currency": local_wallet["currency"],
        "wallet_balance_after": local_wallet["available_balance"],
        "live_provider": flw_res is not None,
        "reversible": True,
        "reversed": False,
        "message": f"{net['operator_name']} data bundle activated on {payload.phone_number}.",
    }
    AIRTIME_TRANSACTIONS[tx_id] = record
    persist_bills_db()
    return record


@router.post("/electricity")
async def purchase_electricity(payload: ElectricityPaymentRequest, current_user: dict = Depends(get_current_user)):
    _require_nigeria_request(payload.country_iso)
    _require_nigerian_user(current_user)
    user_id = current_user["user_id"]
    amount = Decimal(payload.amount)
    if amount < Decimal("500"):
        raise HTTPException(status_code=400, detail="Minimum electricity payment is ₦500.")

    meter = re.sub(r"\D", "", payload.meter_number)
    verified = await verify_meter(meter, payload.meter_type, SUPPORTED_COUNTRY, payload.disco_code)
    if verified["status"] == "UNAVAILABLE":
        raise HTTPException(status_code=503, detail=verified["message"] + " You have not been charged.")
    if verified["status"] != "VALID":
        raise HTTPException(status_code=404, detail=verified["message"])

    local_wallet = _debit_local_wallet(user_id, amount)
    tx_id = f"pwr_{uuid.uuid4().hex[:10]}"
    flw_res = await _call_flw_bills(meter, amount, verified["biller_name"], tx_id)
    if flw_res and "_error" in flw_res:
        _credit_local_wallet(user_id, amount)
        raise HTTPException(status_code=400, detail=f"{flw_res['_error']} Your wallet has been refunded.")

    provider_token = (flw_res or {}).get("recharge_token") or (flw_res or {}).get("token") or (flw_res or {}).get("extra")
    if provider_token:
        token_formatted = str(provider_token)
    elif flw_res is None:
        raw = "".join(str(random.randint(0, 9)) for _ in range(20))
        token_formatted = "-".join(raw[i:i + 4] for i in range(0, 20, 4)) + " (TEST MODE)"
    else:
        token_formatted = "Token will be sent by SMS from your electricity company"

    record = {
        "status": "SUCCESSFUL",
        "category": "ELECTRICITY",
        "transaction_id": tx_id,
        "user_id": user_id,
        "provider_reference": (flw_res or {}).get("flw_ref", tx_id),
        "disco": verified["biller_code"],
        "disco_name": verified["disco_name"],
        "operator": verified["biller_code"],
        "operator_name": verified["disco_name"],
        "phone_number": meter,
        "meter_number": meter,
        "meter_type": payload.meter_type.upper(),
        "customer_name": verified["customer_name"],
        "address": verified.get("address", ""),
        "amount": f"{amount:.2f}",
        "currency": local_wallet["currency"],
        "wallet_balance_after": local_wallet["available_balance"],
        "token": token_formatted,
        "units": (flw_res or {}).get("units", ""),
        "live_provider": flw_res is not None,
        "reversible": True,
        "reversed": False,
        "message": f"Electricity payment of ₦{amount:.2f} to {verified['disco_name']} for {verified['customer_name']}.",
    }
    AIRTIME_TRANSACTIONS[tx_id] = record
    persist_bills_db()
    return record


@router.get("/airtime/recent")
def get_recent_airtime_purchases(current_user: dict = Depends(get_current_user)):
    user_id = current_user["user_id"]
    items = [tx for tx in reversed(list(AIRTIME_TRANSACTIONS.values())) if tx.get("user_id") == user_id]
    return {"count": len(items), "transactions": items[:25]}


@router.post("/airtime/reverse")
def reverse_airtime_purchase(payload: AirtimeReversalRequest, current_user: dict = Depends(get_current_user)):
    user_id = current_user["user_id"]
    tx = AIRTIME_TRANSACTIONS.get(payload.transaction_id)
    if not tx or tx.get("user_id") != user_id:
        raise HTTPException(status_code=404, detail="Bill transaction not found.")
    if tx.get("reversed"):
        raise HTTPException(status_code=400, detail="This purchase has already been reversed to cash.")

    refund_amount = Decimal(tx["amount"])
    local_wallet = _credit_local_wallet(user_id, refund_amount)
    tx["reversed"] = True
    tx["reversible"] = False
    tx["status"] = "REVERSED"
    persist_bills_db()
    cat = tx.get("category", "AIRTIME")
    return {
        "status": "REVERSED",
        "category": cat,
        "transaction_id": tx["transaction_id"],
        "operator": tx.get("operator", ""),
        "phone_number": tx.get("phone_number", ""),
        "refunded_amount": f"{refund_amount:.2f}",
        "currency": local_wallet["currency"],
        "wallet_balance_after": local_wallet["available_balance"],
        "message": f"Reversed ₦{refund_amount:.2f} ({tx.get('operator', '')} {cat.lower()}) back to your wallet.",
    }


@router.post("/airtime-to-cash")
def convert_airtime_to_cash(payload: AirtimeToCashRequest, current_user: dict = Depends(get_current_user)):
    _require_nigeria_request(payload.country_iso)
    _require_nigerian_user(current_user)
    user_id = current_user["user_id"]
    try:
        airtime_amount = Decimal(payload.airtime_amount)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid amount.")
    if airtime_amount <= Decimal("0"):
        raise HTTPException(status_code=400, detail="Amount must be greater than zero.")

    cat = (payload.category or "AIRTIME").upper()
    if cat == "ELECTRICITY":
        meter = re.sub(r"\D", "", payload.phone_number)
        prior = next((t for t in AIRTIME_TRANSACTIONS.values()
                      if t.get("user_id") == user_id and t.get("category") == "ELECTRICITY" and t.get("meter_number") == meter), None)
        op_code = (prior or {}).get("disco") or (payload.operator_code or "ELECTRICITY").upper()
        op_name = (prior or {}).get("disco_name") or op_code
    else:
        _require_nigerian_phone(payload.phone_number)
        op_code = (payload.operator_code or _ng_prefix_operator(payload.phone_number) or "").upper()
        if op_code not in NG_OPERATOR_CODES:
            raise HTTPException(status_code=400, detail="Please select the mobile network for this number.")
        op_name = _operator_name(op_code)

    cash_payout = (airtime_amount * AIRTIME_TO_CASH_PAYOUT_RATE).quantize(Decimal("0.01"))
    conversion_fee = (airtime_amount - cash_payout).quantize(Decimal("0.01"))
    local_wallet = _credit_local_wallet(user_id, cash_payout)
    conv_id = f"a2c_{uuid.uuid4().hex[:10]}"
    return {
        "status": "CONVERTED",
        "category": cat,
        "conversion_id": conv_id,
        "operator": op_code,
        "operator_name": op_name,
        "phone_number": payload.phone_number,
        "airtime_amount": f"{airtime_amount:.2f}",
        "payout_rate": "90%",
        "conversion_fee": f"{conversion_fee:.2f}",
        "cash_credited": f"{cash_payout:.2f}",
        "currency": local_wallet["currency"],
        "wallet_balance_after": local_wallet["available_balance"],
        "message": f"Converted ₦{airtime_amount:.2f} {op_code} {cat.lower()} into ₦{cash_payout:.2f} wallet cash (90% payout).",
    }
