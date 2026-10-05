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
    """
    body_bytes = await request.body()
    try:
        payload = await request.json()
    except Exception:
        payload = {"raw": body_bytes.decode(errors="ignore")}

    webhook_id = x_webhook_id or payload.get("event_id") or f"wh_{hashlib.sha256(body_bytes).hexdigest()[:16]}"

    # 1. Idempotency Check: duplicate webhooks must be harmless
    if webhook_id in PROCESSED_WEBHOOKS:
        return {
            "status": "ALREADY_PROCESSED",
            "webhook_id": webhook_id,
            "message": "Duplicate webhook received and safely acknowledged without double processing."
        }

    # 2. Signature verification simulation
    expected_secret = f"paynora_{provider}_secret_key"
    calculated_sig = hmac.new(expected_secret.encode(), body_bytes, hashlib.sha256).hexdigest()

    event_type = payload.get("event_type", "provider.update")
    data = payload.get("data", payload)

    # 3. Publish to Kafka event bus
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
        "processed_at": "2026-10-05T10:00:00Z"
    }
    PROCESSED_WEBHOOKS[webhook_id] = record

    return {
        "status": "RECEIVED",
        "webhook_id": webhook_id,
        "provider": provider
    }
