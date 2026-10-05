from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import List
from app.api.v1.auth import get_current_user
from app.wallets.models import WalletEngine

router = APIRouter(prefix="/wallets", tags=["Multi-Currency Wallets"])

class ActivateWalletPayload(BaseModel):
    currency: str

class FundWalletPayload(BaseModel):
    currency: str
    amount: str

class ConvertWalletPayload(BaseModel):
    from_currency: str
    to_currency: str
    from_amount: str
    to_amount: str

@router.get("")
def list_wallets(current_user: dict = Depends(get_current_user)):
    """Retrieve all multi-currency digital wallets for authenticated customer."""
    user_id = current_user["user_id"]
    wallets = WalletEngine.get_user_wallets(user_id)
    return {
        "user_id": user_id,
        "count": len(wallets),
        "wallets": wallets
    }

@router.post("", status_code=status.HTTP_201_CREATED)
def activate_wallet(
    payload: ActivateWalletPayload,
    current_user: dict = Depends(get_current_user)
):
    """Activate a new wallet for a supported currency."""
    user_id = current_user["user_id"]
    wallet = WalletEngine.activate_currency_wallet(user_id, payload.currency)
    return wallet

class InitializeDepositPayload(BaseModel):
    currency: str
    amount: str
    gateway: str | None = None
    callback_url: str | None = None

class VerifyDepositPayload(BaseModel):
    reference: str
    gateway: str
    currency: str

@router.post("/deposit/initialize")
async def initialize_deposit(
    payload: InitializeDepositPayload,
    current_user: dict = Depends(get_current_user)
):
    """
    Initiates payment session through Smart Dual Gateway Engine (Paystack / Flutterwave).
    """
    from app.providers.payment import PaymentGatewayRouter
    email = current_user.get("email", "customer@paynora.com")
    user_id = current_user["user_id"]
    
    result = await PaymentGatewayRouter.initialize_deposit(
        email=email,
        amount=payload.amount,
        currency=payload.currency,
        user_id=user_id,
        gateway=payload.gateway,
        callback_url=payload.callback_url
    )
    return result

@router.post("/deposit/verify")
async def verify_deposit(
    payload: VerifyDepositPayload,
    current_user: dict = Depends(get_current_user)
):
    """
    Verifies gateway transaction status and credits wallet if successful.
    """
    from app.providers.payment import PaymentGatewayRouter
    user_id = current_user["user_id"]
    
    verification = await PaymentGatewayRouter.verify_transaction(
        reference=payload.reference,
        gateway=payload.gateway
    )
    if verification.get("verified"):
        wallet = WalletEngine.fund_wallet(user_id, payload.currency, verification.get("amount", "0"))
        return {
            "status": "SUCCESS",
            "message": "Deposit confirmed and credited to wallet",
            "wallet": wallet,
            "verification": verification
        }
    return {
        "status": "PENDING_OR_FAILED",
        "message": "Payment could not be verified as completed",
        "verification": verification
    }

@router.post("/fund")
def fund_wallet(
    payload: FundWalletPayload,
    current_user: dict = Depends(get_current_user)
):
    """Deposit / Fund wallet with simulated local or international rail."""
    user_id = current_user["user_id"]
    try:
        wallet = WalletEngine.fund_wallet(user_id, payload.currency, payload.amount)
        return {"status": "SUCCESS", "wallet": wallet}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/convert")
def convert_wallet_currency(
    payload: ConvertWalletPayload,
    current_user: dict = Depends(get_current_user)
):
    """Instant multi-currency exchange between user wallets."""
    user_id = current_user["user_id"]
    try:
        result = WalletEngine.convert_wallet_currency(
            user_id,
            payload.from_currency,
            payload.to_currency,
            payload.from_amount,
            payload.to_amount
        )
        return {"status": "CONVERTED", **result}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
