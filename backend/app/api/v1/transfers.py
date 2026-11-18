from fastapi import APIRouter, Depends, Header, HTTPException, status
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from decimal import Decimal
import uuid
from typing import List, Dict, Any, Optional
from app.transfers.state_machine import TransferState
from app.events.kafka import event_publisher
from app.notifications.service import NotificationService
from app.receipts.generator import ReceiptGenerator
from app.api.v1.auth import get_current_user
from app.wallets.models import WalletEngine
from app.fx.engine import FXEngine

router = APIRouter(prefix="/transfers", tags=["Transfers"])

class CreateTransferRequest(BaseModel):
    source_currency: str
    source_amount: str
    recipient_name: str
    source_country: str = "NG"
    destination_country: str = "GB"
    recipient_currency_mode: str = "CHOICE"
    destination_currency: str | None = None
    gateway: str | None = None
    payout_method: str | None = None
    narration: str | None = None
    account_details: Dict[str, Any] | None = None

class SelectRecipientCurrencyRequest(BaseModel):
    selected_currency: str
    payout_method: str = "LOCAL_BANK"

class ResolveAccountRequest(BaseModel):
    account_number: str
    account_bank: str
    currency: str = "NGN"

class DisbursePayoutRequest(BaseModel):
    account_bank: str
    account_number: str
    amount: str
    currency: str
    recipient_name: str
    narration: str | None = None

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

@router.get("/banks")
async def list_supported_banks(country: str = "NG"):
    """Fetch commercial banks for real-time account routing and resolution."""
    from app.providers.banking import BankingEngine
    banks = await BankingEngine.get_banks(country)
    return {
        "country": country.upper(),
        "count": len(banks),
        "banks": banks
    }

@router.post("/resolve-account")
async def resolve_bank_account(payload: ResolveAccountRequest):
    """Real-time account resolution endpoint verifying beneficiary legal name."""
    from app.providers.banking import BankingEngine
    result = await BankingEngine.resolve_account(
        account_number=payload.account_number,
        bank_code=payload.account_bank,
        currency=payload.currency
    )
    if result.get("status") == "ERROR":
        raise HTTPException(status_code=400, detail=result.get("message", "Account verification failed"))
    return result

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

@router.get("/{transfer_id}/receipt")
def get_transfer_receipt(transfer_id: str):
    """Retrieve structured financial receipt payload for a transfer."""
    for tx in TRANSFERS_LIST:
        if tx["transfer_id"] == transfer_id:
            return ReceiptGenerator.generate_receipt_data(tx)
    raise HTTPException(status_code=404, detail="Transfer not found")

@router.get("/{transfer_id}/receipt/html", response_class=HTMLResponse)
def get_transfer_receipt_html(transfer_id: str):
    """Retrieve official printable HTML receipt for a transfer."""
    for tx in TRANSFERS_LIST:
        if tx["transfer_id"] == transfer_id:
            data = ReceiptGenerator.generate_receipt_data(tx)
            return ReceiptGenerator.generate_html_receipt(data)
    raise HTTPException(status_code=404, detail="Transfer not found")

@router.post("", status_code=status.HTTP_201_CREATED)
async def create_transfer(
    payload: CreateTransferRequest,
    idempotency_key: str = Header(..., alias="Idempotency-Key"),
    current_user: dict = Depends(get_current_user)
):
    """
    Idempotent transfer creation & bank/mobile-money payout execution endpoint.
    """
    if idempotency_key in IDEMPOTENCY_CACHE:
        return IDEMPOTENCY_CACHE[idempotency_key]

    try:
        amount = Decimal(payload.source_amount)
        if amount <= Decimal('0'):
            raise ValueError("Amount must be positive.")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid transfer amount: {str(e)}")

    user_id = current_user.get("user_id", "usr_demo_customer")
    src_curr = payload.source_currency.upper()
    payout_currency = (payload.destination_currency or src_curr).upper()

    # Check & debit sender's wallet when executing a real payout (account_details provided)
    # or whenever the wallet holds sufficient balance
    wallets = WalletEngine.get_user_wallets(user_id)
    source_wallet = next((w for w in wallets if w["currency"] == src_curr), None)
    debited = False
    if payload.account_details:
        if not source_wallet:
            raise HTTPException(status_code=400, detail=f"You do not have an active {src_curr} wallet.")
        current_bal = Decimal(source_wallet["available_balance"])
        if current_bal < amount:
            raise HTTPException(status_code=400, detail=f"Insufficient {src_curr} wallet balance.")
        source_wallet["available_balance"] = f"{(current_bal - amount):.2f}"
        debited = True
    elif source_wallet and Decimal(source_wallet["available_balance"]) >= amount:
        source_wallet["available_balance"] = f"{(Decimal(source_wallet['available_balance']) - amount):.2f}"
        debited = True

    # Calculate destination payout amount
    if src_curr == payout_currency:
        destination_amount = f"{amount:.2f}"
        estimated_fee = "0.00"
    else:
        fx_quote = FXEngine.generate_quote(src_curr, payout_currency, str(amount))
        destination_amount = fx_quote["destination_amount"]
        estimated_fee = fx_quote["fee"]

    transfer_id = f"trf_{uuid.uuid4().hex[:12]}"
    from app.providers.payment import PaymentGatewayRouter
    payout_route = PaymentGatewayRouter.get_route(payout_currency)
    payout_gateway = PaymentGatewayRouter.select_gateway(payout_currency, payload.gateway)

    transfer_state = TransferState.PROCESSING
    disbursal_info = None

    # If recipient bank/mobile-money account details are provided, disburse immediately
    if payload.account_details and payload.account_details.get("account_number"):
        from app.providers.banking import BankingEngine
        acc_num = str(payload.account_details.get("account_number"))
        bank_code = str(payload.account_details.get("bank_code") or payload.account_details.get("institution") or "044")
        disbursal_info = await BankingEngine.disburse_payout(
            transfer_id=transfer_id,
            account_bank=bank_code,
            account_number=acc_num,
            amount=destination_amount,
            currency=payout_currency,
            recipient_name=payload.recipient_name,
            narration=payload.narration
        )
        if disbursal_info.get("status") == "ERROR":
            # Roll back wallet debit on gateway failure
            if debited and source_wallet:
                source_wallet["available_balance"] = f"{(Decimal(source_wallet['available_balance']) + amount):.2f}"
            raise HTTPException(status_code=400, detail=disbursal_info.get("message", "Bank payout failed."))
        transfer_state = TransferState.COMPLETED

    response_data = {
        "transfer_id": transfer_id,
        "idempotency_key": idempotency_key,
        "source_currency": src_curr,
        "source_amount": str(amount),
        "destination_currency": payout_currency,
        "destination_amount": destination_amount,
        "recipient_name": payload.recipient_name,
        "source_country": payload.source_country.upper(),
        "destination_country": payload.destination_country.upper(),
        "recipient_currency_mode": payload.recipient_currency_mode,
        "payout_method": payload.payout_method or "LOCAL_BANK",
        "payout_gateway": disbursal_info.get("gateway", payout_gateway) if disbursal_info else payout_gateway,
        "payout_gateway_reason": payout_route["reason"],
        "state": transfer_state,
        "estimated_fee": estimated_fee,
        "wallet_balance_after": source_wallet["available_balance"] if source_wallet else None,
        "disbursal": disbursal_info,
        "created_at": "2026-10-06T22:00:00Z"
    }

    IDEMPOTENCY_CACHE[idempotency_key] = response_data
    TRANSFERS_LIST.insert(0, response_data)
    event_publisher.publish_event("TransferCreated", response_data)

    # Dispatch notification alert
    NotificationService.dispatch(
        user_id=user_id,
        title="Transfer Dispatched",
        message=f"Transfer of {src_curr} {payload.source_amount} to {payload.recipient_name} is {transfer_state}.",
        notification_type="DEBIT_ALERT",
        data={"transfer_id": transfer_id, "amount": str(amount), "currency": src_curr}
    )

    return response_data

@router.post("/{transfer_id}/confirm")
def confirm_transfer(transfer_id: str):
    """Confirm and settle an in-flight transfer."""
    for tx in TRANSFERS_LIST:
        if tx["transfer_id"] == transfer_id:
            tx["state"] = TransferState.COMPLETED
            event_publisher.publish_event("TransferConfirmed", {"transfer_id": transfer_id, "state": "COMPLETED"})

            # Dispatch success notification alert
            NotificationService.dispatch(
                user_id="usr_demo",
                title="Transfer Disbursed Successfully",
                message=f"Transfer {transfer_id} to {tx.get('recipient_name', 'recipient')} has completed.",
                notification_type="TRANSFER_SUCCESS",
                data={"transfer_id": transfer_id, "receipt_url": f"/api/v1/transfers/{transfer_id}/receipt"}
            )

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

@router.post("/{transfer_id}/disburse")
async def disburse_transfer(transfer_id: str, payload: DisbursePayoutRequest):
    """Trigger automated real-time disbursal/payout via Flutterwave to recipient bank."""
    from app.providers.banking import BankingEngine
    for tx in TRANSFERS_LIST:
        if tx["transfer_id"] == transfer_id:
            disbursal = await BankingEngine.disburse_payout(
                transfer_id=transfer_id,
                account_bank=payload.account_bank,
                account_number=payload.account_number,
                amount=payload.amount,
                currency=payload.currency,
                recipient_name=payload.recipient_name,
                narration=payload.narration
            )
            tx["disbursal_status"] = disbursal.get("disbursal_status", "PROCESSING")
            tx["payout_reference"] = disbursal.get("reference")
            tx["provider_transfer_id"] = disbursal.get("provider_transfer_id")
            if disbursal.get("status") == "SUCCESS":
                tx["state"] = TransferState.COMPLETED

            NotificationService.dispatch(
                user_id="usr_demo",
                title="Bank Disbursal Initiated",
                message=f"Disbursal of {payload.currency.upper()} {payload.amount} to {payload.recipient_name} ({payload.account_number}) is underway.",
                notification_type="TRANSFER_SUCCESS",
                data={"transfer_id": transfer_id, "reference": disbursal.get("reference")}
            )
            return {"status": "SUCCESS", "transfer": tx, "disbursal": disbursal}
    raise HTTPException(status_code=404, detail="Transfer not found")
