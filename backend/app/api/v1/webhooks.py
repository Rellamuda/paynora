import asyncio
import hashlib
import hmac
from typing import Any, Dict, List, Optional

import httpx
from fastapi import APIRouter, Header, HTTPException, Request, status

from app.events.kafka import event_publisher

router = APIRouter(prefix="/webhooks", tags=["Provider Webhooks"])

PROCESSED_WEBHOOKS: Dict[str, Dict[str, Any]] = {}


async def _forward_webhook_to_apps(urls: List[str], body_bytes: bytes, forward_headers: Dict[str, str]) -> None:
    """
    Forward the exact signed webhook payload to sibling apps (e.g. Knot, JobHub, Properties & Autos)
    that share the same Paystack / Flutterwave business account.
    """
    if not urls:
        return
    async with httpx.AsyncClient(timeout=15.0) as client:
        for url in urls:
            try:
                await client.post(url, content=body_bytes, headers=forward_headers)
            except Exception as e:
                print(f"[WebhookForwarder] Forward to {url} failed: {e}")


def _parse_forward_urls(raw: str) -> List[str]:
    return [u.strip() for u in (raw or "").split(",") if u.strip().startswith("http")]


def _resolve_user_id_for_paystack(data: Dict[str, Any]) -> Optional[str]:
    meta = data.get("metadata") or {}
    if isinstance(meta, dict) and meta.get("user_id"):
        return str(meta["user_id"])

    # Match Dedicated Virtual Account (NUBAN) inbound transfer
    auth = data.get("authorization") or {}
    nuban = auth.get("receiver_bank_account_number")
    if nuban:
        from app.providers.virtual_accounts import find_user_id_by_nuban
        uid = find_user_id_by_nuban(str(nuban))
        if uid:
            return uid

    # Fallback: match customer email in SendMoni UserStore
    cust = data.get("customer") or {}
    email = cust.get("email")
    if email:
        from app.auth.store import UserStore
        user = UserStore.get_by_email(str(email))
        if user:
            return user["user_id"]
    return None


def _resolve_user_id_for_flutterwave(data: Dict[str, Any]) -> Optional[str]:
    meta = data.get("meta") or {}
    if isinstance(meta, dict) and meta.get("user_id"):
        return str(meta["user_id"])

    tx_ref = str(data.get("tx_ref") or "")
    if tx_ref.startswith("sm_va_"):
        return tx_ref[len("sm_va_"):]

    cust = data.get("customer") or {}
    email = cust.get("email")
    if email:
        from app.auth.store import UserStore
        user = UserStore.get_by_email(str(email))
        if user:
            return user["user_id"]
    return None


@router.post("/{provider}", status_code=status.HTTP_200_OK)
async def handle_provider_webhook(
    provider: str,
    request: Request,
    x_webhook_signature: Optional[str] = Header(None, alias="X-Webhook-Signature"),
    x_paystack_signature: Optional[str] = Header(None, alias="x-paystack-signature"),
    x_webhook_id: Optional[str] = Header(None, alias="X-Webhook-ID"),
):
    """
    Idempotent, signed provider webhook ingress + Multi-App Webhook Forwarder.
    - Credits SendMoni wallets automatically on card deposits AND Dedicated Virtual Account (NUBAN) transfers.
    - Preserves & forwards the exact raw payload + signature headers to sibling apps (Knot, JobHub, Properties & Autos).
    """
    from app.config import settings
    from app.wallets.models import WalletEngine

    body_bytes = await request.body()
    try:
        payload = await request.json()
    except Exception:
        payload = {"raw": body_bytes.decode(errors="ignore")}

    provider_name = provider.lower()

    # 1. Strict Signature Verification
    if provider_name == "flutterwave":
        secret_hash = request.headers.get("verif-hash")
        expected_hash = settings.FLW_WEBHOOK_HASH
        if expected_hash and secret_hash != expected_hash:
            raise HTTPException(status_code=400, detail="Invalid Flutterwave verification hash")

    elif provider_name == "paystack":
        expected_secret = settings.PAYSTACK_SECRET_KEY
        incoming_sig = x_paystack_signature or x_webhook_signature
        if expected_secret and incoming_sig:
            calculated_sig = hmac.new(expected_secret.encode(), body_bytes, hashlib.sha512).hexdigest()
            if not hmac.compare_digest(incoming_sig, calculated_sig):
                raise HTTPException(status_code=400, detail="Invalid Paystack signature")

    # 2. Multi-App Forwarder (non-blocking background fan-out to sibling apps)
    if provider_name == "paystack":
        fwd_urls = _parse_forward_urls(settings.PAYSTACK_FORWARD_URLS)
        if fwd_urls:
            fwd_headers = {"Content-Type": "application/json"}
            if x_paystack_signature:
                fwd_headers["x-paystack-signature"] = x_paystack_signature
            asyncio.create_task(_forward_webhook_to_apps(fwd_urls, body_bytes, fwd_headers))
    elif provider_name == "flutterwave":
        fwd_urls = _parse_forward_urls(settings.FLW_FORWARD_URLS)
        if fwd_urls:
            fwd_headers = {"Content-Type": "application/json"}
            verif_hash = request.headers.get("verif-hash")
            if verif_hash:
                fwd_headers["verif-hash"] = verif_hash
            asyncio.create_task(_forward_webhook_to_apps(fwd_urls, body_bytes, fwd_headers))

    # 3. Idempotency Check
    data_obj = payload.get("data") if isinstance(payload, dict) else {}
    ref_id = (data_obj or {}).get("reference") or (data_obj or {}).get("id")
    webhook_id = x_webhook_id or payload.get("event_id") or (f"{provider_name}_{ref_id}" if ref_id else f"wh_{hashlib.sha256(body_bytes).hexdigest()[:16]}")
    if webhook_id in PROCESSED_WEBHOOKS:
        return {
            "status": "ALREADY_PROCESSED",
            "webhook_id": webhook_id,
            "message": "Duplicate webhook received and safely acknowledged without double processing.",
        }

    # 4. Process SendMoni Wallet Crediting (Checkout + Dedicated Virtual Account NUBAN)
    credited_user_id = None
    if provider_name == "flutterwave":
        event = payload.get("event")
        data = payload.get("data", payload)
        charge_status = data.get("status") or payload.get("status")
        if event in ("charge.completed", "charge.successful") and str(charge_status).lower() == "successful":
            user_id = _resolve_user_id_for_flutterwave(data)
            amount = str(data.get("amount", "0"))
            currency = (data.get("currency") or "NGN").upper()
            if user_id:
                try:
                    WalletEngine.fund_wallet(str(user_id), currency, amount)
                    credited_user_id = str(user_id)
                    from app.notifications.service import NotificationService
                    NotificationService.dispatch(
                        user_id=str(user_id),
                        title="Instant Deposit Credited",
                        message=f"Your {currency} wallet has been credited with {currency} {amount} via Flutterwave.",
                        notification_type="CREDIT_ALERT",
                        data={"amount": amount, "currency": currency, "provider": "flutterwave"},
                    )
                except Exception as e:
                    print(f"Error auto-crediting wallet via Flutterwave webhook: {e}")

    elif provider_name == "paystack":
        event = payload.get("event")
        if event == "charge.success":
            data = payload.get("data", {})
            user_id = _resolve_user_id_for_paystack(data)
            amount_kobo = data.get("amount", 0)
            currency = (data.get("currency") or "NGN").upper()
            amount = f"{(amount_kobo / 100):.2f}"
            if user_id:
                try:
                    WalletEngine.fund_wallet(user_id, currency, amount)
                    credited_user_id = user_id
                    channel = data.get("channel", "paystack")
                    from app.notifications.service import NotificationService
                    NotificationService.dispatch(
                        user_id=user_id,
                        title="Bank Transfer Received" if channel == "dedicated_nuban" else "Instant Deposit Credited",
                        message=f"Your {currency} wallet has been credited with {currency} {amount} via Paystack ({channel}).",
                        notification_type="CREDIT_ALERT",
                        data={"amount": amount, "currency": currency, "provider": "paystack", "channel": channel},
                    )
                except Exception as e:
                    print(f"Error auto-crediting wallet via Paystack webhook: {e}")

    record = {
        "webhook_id": webhook_id,
        "provider": provider_name,
        "credited_user_id": credited_user_id,
        "status": "PROCESSED",
    }
    PROCESSED_WEBHOOKS[webhook_id] = record
    event_publisher.publish_event("ProviderWebhookProcessed", record)

    return {
        "status": "ACCEPTED",
        "webhook_id": webhook_id,
        "provider": provider_name,
        "credited_user_id": credited_user_id,
        "message": "Webhook verified, processed, and forwarded successfully.",
    }
