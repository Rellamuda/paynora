from fastapi import APIRouter, Header, HTTPException, status
from pydantic import BaseModel
from decimal import Decimal
import uuid
from typing import List
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

class SelectRecipientCurrencyRequest(BaseModel):
    selected_currency: str
    payout_method: str = "LOCAL_BANK"

# In-memory transfer store for local development
TRANSFERS_LIST = [
    {
        "transfer_id": "trf_08d31befd3c1",
        "idempotency_key": "seed_01",
        "source_currency": "NGN",
        "source_amount": "100000.00",
        "recipient_name": "Mike Okafor",
        "source_country": "NG",
        "destination_country": "GB",
        "recipient_currency_mode": "CHOICE",
        "state": TransferState.COMPLETED,
        "estimated_fee": "500.00",
        "created_at": "2026-10-04T18:30:00Z"
    },
    {
        "transfer_id": "trf_a912fc89d02e",
        "idempotency_key": "seed_02",
        "source_currency": "GBP",
        "source_amount": "250.00",
        "recipient_name": "John Doe",
        "source_country": "GB",
        "destination_country": "NG",
        "recipient_currency_mode": "CHOICE",
        "state": TransferState.COMPLETED,
        "estimated_fee": "3.50",
        "created_at": "2026-10-04T14:15:00Z"
    }
]

IDEMPOTENCY_CACHE = {}

@router.get("")
def list_transfers():
    """List all recent cross-border transfers and ledger states."""
    return {
        "transfers": TRANSFERS_LIST,
        "count": len(TRANSFERS_LIST)
    }

@router.get("/{transfer_id}")
def get_transfer(transfer_id: str):
    """Retrieve details and status for a specific transfer by ID."""
    for tx in TRANSFERS_LIST:
        if tx["transfer_id"] == transfer_id:
            return tx
    raise HTTPException(status_code=404, detail="Transfer not found")

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
        "state": TransferState.PROCESSING,
        "estimated_fee": "500.00",
        "created_at": "2026-10-05T08:00:00Z"
    }

    IDEMPOTENCY_CACHE[idempotency_key] = response_data
    TRANSFERS_LIST.insert(0, response_data)
    event_publisher.publish_event("TransferCreated", response_data)

    return response_data

@router.post("/{transfer_id}/confirm")
def confirm_transfer(transfer_id: str):
    """Confirm and settle an in-flight transfer."""
    for tx in TRANSFERS_LIST:
        if tx["transfer_id"] == transfer_id:
            tx["state"] = TransferState.COMPLETED
            event_publisher.publish_event("TransferConfirmed", {"transfer_id": transfer_id, "state": "COMPLETED"})
            return {"status": "SUCCESS", "transfer": tx}
    raise HTTPException(status_code=404, detail="Transfer not found")

@router.post("/{transfer_id}/recipient-currency")
def select_recipient_currency(transfer_id: str, payload: SelectRecipientCurrencyRequest):
    """Allow recipient to choose their preferred payout currency (local vs original sender currency)."""
    for tx in TRANSFERS_LIST:
        if tx["transfer_id"] == transfer_id:
            tx["selected_recipient_currency"] = payload.selected_currency.upper()
            tx["payout_method"] = payload.payout_method
            tx["state"] = TransferState.RECIPIENT_CURRENCY_SELECTED
            event_publisher.publish_event("RecipientCurrencySelected", {
                "transfer_id": transfer_id,
                "currency": payload.selected_currency
            })
            return {
                "status": "SUCCESS",
                "transfer_id": transfer_id,
                "selected_currency": payload.selected_currency.upper(),
                "state": TransferState.RECIPIENT_CURRENCY_SELECTED
            }
    raise HTTPException(status_code=404, detail="Transfer not found")
