from fastapi import APIRouter, Depends, status
from pydantic import BaseModel
from typing import Dict, Any
from app.api.v1.auth import get_current_user
from app.beneficiaries.store import BeneficiaryStore

router = APIRouter(prefix="/beneficiaries", tags=["Beneficiaries"])

class CreateBeneficiaryPayload(BaseModel):
    name: str
    country_iso: str
    currency: str
    account_details: Dict[str, Any]

@router.get("")
def list_beneficiaries(current_user: dict = Depends(get_current_user)):
    user_id = current_user["user_id"]
    beneficiaries = BeneficiaryStore.get_user_beneficiaries(user_id)
    return {
        "user_id": user_id,
        "count": len(beneficiaries),
        "beneficiaries": beneficiaries
    }

@router.post("", status_code=status.HTTP_201_CREATED)
def create_beneficiary(
    payload: CreateBeneficiaryPayload,
    current_user: dict = Depends(get_current_user)
):
    user_id = current_user["user_id"]
    ben = BeneficiaryStore.add_beneficiary(
        user_id=user_id,
        name=payload.name,
        country_iso=payload.country_iso,
        currency=payload.currency,
        account_details=payload.account_details
    )
    return ben
