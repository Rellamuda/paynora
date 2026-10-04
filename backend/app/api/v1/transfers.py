from fastapi import APIRouter, Header, HTTPException, status
from pydantic import BaseModel
from decimal import Decimal
import uuid
from app.transfers.state_machine import TransferState
from app.events.kafka import event_publisher

router = APIRouter(prefix="/transfers", tags=["Transfers"])

class CreateTransferRequest(BaseModel):
    source_currency: str
    source_amount: str
    recipient_name: str
    source_country: str = "NG"
    destination_country: str = "GB"
    recipient_currency_mode: str = "CHOICE"

# In-memory idempotency cache for local development
IDEMPOTENCY_CACHE = {}

@router.post("", status_code=status.HTTP_201_CREATED)
def create_transfer(
    payload: CreateTransferRequest,
    idempotency_key: str = Header(..., alias="Idempotency-Key")
):
    """
    Idempotent transfer intent creation endpoint.
    """
    if idempotency_key in IDEMPOTENCY_CACHE:
        return IDEMPOTENCY_CACHE[idempotency_key]

    try:
        amount = Decimal(payload.source_amount)
        if amount <= Decimal('0'):
            raise ValueError("Amount must be positive.")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid transfer amount: {str(e)}")

    transfer_id = f"trf_{uuid.uuid4().hex[:12]}"
    response_data = {
        "transfer_id": transfer_id,
        "idempotency_key": idempotency_key,
        "source_currency": payload.source_currency.upper(),
        "source_amount": str(amount),
        "recipient_name": payload.recipient_name,
        "source_country": payload.source_country.upper(),
        "destination_country": payload.destination_country.upper(),
        "recipient_currency_mode": payload.recipient_currency_mode,
        "state": TransferState.AWAITING_CONFIRMATION,
        "estimated_fee": "500.00",
        "created_at": "2026-10-04T11:20:00Z"
    }

    IDEMPOTENCY_CACHE[idempotency_key] = response_data
    event_publisher.publish_event("TransferCreated", response_data)

    return response_data
