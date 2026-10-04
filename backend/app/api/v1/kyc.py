from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from app.api.v1.auth import get_current_user
from app.kyc.state_machine import KYCState, KYCStateMachine
from app.kyc.capabilities import AccountCapabilityPolicy
from app.providers.kyc import MockKYCProvider
from app.providers.aml import MockAMLProvider
from app.events.kafka import event_publisher

router = APIRouter(prefix="/kyc", tags=["KYC & Verification"])

class VerificationRequestPayload(BaseModel):
    document_type: str
    document_number: str

@router.get("/status")
def get_kyc_status(current_user: dict = Depends(get_current_user)):
    kyc_state = KYCState(current_user.get("kyc_status", "NOT_STARTED"))
    capabilities = AccountCapabilityPolicy.get_capabilities_for_state(kyc_state)
    return {
        "user_id": current_user["user_id"],
        "kyc_status": kyc_state,
        "capabilities": capabilities
    }

@router.post("/verify")
def submit_identity_verification(
    payload: VerificationRequestPayload,
    current_user: dict = Depends(get_current_user)
):
    user_id = current_user["user_id"]
    full_name = f"{current_user['first_name']} {current_user['last_name']}"

    # 1. AML / Watch-list Screening
    aml_result = MockAMLProvider.screen_customer(full_name, current_user["country_iso"])
    if not aml_result["passed"]:
        current_user["kyc_status"] = KYCState.REJECTED
        event_publisher.publish_event("KYCRejected", {"user_id": user_id, "reason": aml_result["details"]})
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Verification failed compliance check: {aml_result['details']}"
        )

    # 2. Identity Document Verification
    kyc_result = MockKYCProvider.verify_identity(
        user_id=user_id,
        document_type=payload.document_type,
        document_number=payload.document_number
    )

    new_state = KYCState(kyc_result["status"])
    current_user["kyc_status"] = new_state
    new_capabilities = AccountCapabilityPolicy.get_capabilities_for_state(new_state)
    current_user["account_capabilities"] = new_capabilities

    event_publisher.publish_event("KYCCompleted", {
        "user_id": user_id,
        "status": new_state,
        "session_id": kyc_result["session_id"]
    })

    return {
        "user_id": user_id,
        "kyc_status": new_state,
        "capabilities": new_capabilities,
        "verification_result": kyc_result
    }
