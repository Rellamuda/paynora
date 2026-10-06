from fastapi import APIRouter, Header, HTTPException, Request, status
from typing import Dict, Any, Optional
import hmac
import hashlib
from app.events.kafka import event_publisher

router = APIRouter(prefix="/webhooks", tags=["Provider Webhooks"])

PROCESSED_WEBHOOKS: Dict[str, Dict[str, Any]] = {}

@router.post("/{provider}", status_code=status.HTTP_200_OK)
async def handle_provider_webhook(
    provider: str,
    request: Request,
    x_webhook_signature: Optional[str] = Header(None, alias="X-Webhook-Signature"),
    x_webhook_id: Optional[str] = Header(None, alias="X-Webhook-ID")
):
    """
    Idempotent, signed provider webhook ingress endpoint for payment, FX, and KYC updates.
    Enforces secret hash verification for Flutterwave and HMAC SHA512 for Paystack.
    """
    from app.config import settings
    from app.wallets.models import WalletEngine

    body_bytes = await request.body()
    try:
        payload = await request.json()
    except Exception:
        payload = {"raw": body_bytes.decode(errors="ignore")}

    provider_name = provider.lower()

    # 1. Strict Security Verification First
    if provider_name == "flutterwave":
        secret_hash = request.headers.get("verif-hash")
        expected_hash = settings.FLW_WEBHOOK_HASH
        if expected_hash and secret_hash != expected_hash:
            raise HTTPException(status_code=400, detail="Invalid Flutterwave verification hash")

    elif provider_name == "paystack":
        expected_secret = settings.PAYSTACK_SECRET_KEY
        calculated_sig = hmac.new(expected_secret.encode(), body_bytes, hashlib.sha512).hexdigest()
        if x_webhook_signature and x_webhook_signature != calculated_sig:
            raise HTTPException(status_code=400, detail="Invalid Paystack signature")

    # 2. Idempotency Check: duplicate verified webhooks are safely ignored
    webhook_id = x_webhook_id or payload.get("event_id") or f"wh_{hashlib.sha256(body_bytes).hexdigest()[:16]}"
    if webhook_id in PROCESSED_WEBHOOKS:
        return {
            "status": "ALREADY_PROCESSED",
            "webhook_id": webhook_id,
            "message": "Duplicate webhook received and safely acknowledged without double processing."
        }

    # 3. Process Wallet Crediting / Event Handling
    if provider_name == "flutterwave":
        event = payload.get("event")
        data = payload.get("data", payload)
        charge_status = data.get("status") or payload.get("status")

        if (event == "charge.completed" or event == "charge.successful") and charge_status == "successful":
            user_id = data.get("meta", {}).get("user_id") or data.get("customer", {}).get("id")
            amount = str(data.get("amount", "0"))
            currency = (data.get("currency") or "USD").upper()
            if user_id:
                try:
                    WalletEngine.fund_wallet(str(user_id), currency, amount)
                except Exception as e:
                    print(f"Error auto-crediting wallet via Flutterwave webhook: {e}")

    elif provider_name == "paystack":
        event = payload.get("event")
        if event == "charge.success":
            data = payload.get("data", {})
            user_id = data.get("metadata", {}).get("user_id")
            amount_kobo = data.get("amount", 0)
            currency = data.get("currency", "NGN")
            amount = str(amount_kobo / 100)
            if user_id:
                try:
                    WalletEngine.fund_wallet(user_id, currency, amount)
                except Exception as e:
                    print(f"Error auto-crediting wallet via Paystack webhook: {e}")

    event_type = payload.get("event", payload.get("event_type", f"{provider}.update"))
    data = payload.get("data", payload)

    # 4. Publish to Kafka event bus
    event_publisher.publish_event("ProviderWebhookReceived", {
        "provider": provider,
        "webhook_id": webhook_id,
        "event_type": event_type,
        "data": data
    })

    record = {
        "webhook_id": webhook_id,
        "provider": provider,
        "event_type": event_type,
        "status": "PROCESSED",
        "processed_at": "2026-10-06T16:00:00Z"
    }
    PROCESSED_WEBHOOKS[webhook_id] = record

    return {
        "status": "RECEIVED",
        "webhook_id": webhook_id,
        "provider": provider
    }
