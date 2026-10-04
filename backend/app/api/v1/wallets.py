from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import List
from app.api.v1.auth import get_current_user
from app.wallets.models import WalletEngine

router = APIRouter(prefix="/wallets", tags=["Multi-Currency Wallets"])

class ActivateWalletPayload(BaseModel):
    currency: str

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
