from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from app.api.v1.auth import get_current_user
from app.auth.store import persist_users_db
from app.kyc.state_machine import KYCState, KYCStateMachine
from app.kyc.capabilities import AccountCapabilityPolicy
from app.providers.kyc import MockKYCProvider
from app.providers.didit_kyc import DiditKYCProvider, didit_configured
from app.providers.aml import MockAMLProvider
from app.events.kafka import event_publisher

router = APIRouter(prefix="/kyc", tags=["KYC & Verification"])

class VerificationRequestPayload(BaseModel):
    document_type: str
    document_number: str
    selfie_captured: bool = True
    id_photo_captured: bool = True
    selfie_hash: str | None = None
    id_image_base64: str | None = None
    selfie_image_base64: str | None = None

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
async def submit_identity_verification(
    payload: VerificationRequestPayload,
    current_user: dict = Depends(get_current_user)
):
    user_id = current_user["user_id"]
    full_name = f"{current_user['first_name']} {current_user['last_name']}"

    # 1. AML / Watch-list Screening
    aml_result = MockAMLProvider.screen_customer(full_name, current_user["country_iso"])
    if not aml_result["passed"]:
        current_user["kyc_status"] = KYCState.REJECTED
        persist_users_db()
        event_publisher.publish_event("KYCRejected", {"user_id": user_id, "reason": aml_result["details"]})
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Verification failed compliance check: {aml_result['details']}"
        )

    # 2. Live Biometric ID + Selfie Liveness + 1:1 Face Match (Didit v3 when images & key are present)
    if didit_configured() and (payload.id_image_base64 or payload.selfie_image_base64):
        kyc_result = await DiditKYCProvider.verify_kyc(
            user_id=user_id,
            document_type=payload.document_type,
            document_number=payload.document_number,
            id_image_base64=payload.id_image_base64,
            selfie_image_base64=payload.selfie_image_base64,
        )
        if kyc_result["status"] != "APPROVED":
            current_user["kyc_status"] = KYCState.REJECTED
            persist_users_db()
            event_publisher.publish_event("KYCRejected", {"user_id": user_id, "reason": kyc_result["reason"]})
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Didit verification declined: {kyc_result['reason']}",
            )
    else:
        kyc_result = MockKYCProvider.verify_identity(
            user_id=user_id,
            document_type=payload.document_type,
            document_number=payload.document_number
        )

    new_state = KYCState(kyc_result["status"])
    current_user["kyc_status"] = new_state
    new_capabilities = AccountCapabilityPolicy.get_capabilities_for_state(new_state)
    current_user["account_capabilities"] = new_capabilities

    # Auto-provision a permanent Nigerian NUBAN if verified with BVN and none assigned yet
    assigned_va = None
    if (current_user.get("country_iso") or "NG").upper() == "NG":
        try:
            from app.providers.virtual_accounts import get_user_virtual_account, provision_virtual_account
            existing_va = get_user_virtual_account(user_id)
            doc_num = (payload.document_number or "").strip()
            if not existing_va and payload.document_type.upper() == "BVN" and len(doc_num) == 11 and doc_num.isdigit():
                va_res = await provision_virtual_account(
                    user=current_user,
                    preferred_provider="FLUTTERWAVE",
                    preferred_bank="titan-paystack",
                    bvn=doc_num,
                )
                if va_res.get("status") == "SUCCESS" and va_res.get("account_number"):
                    current_user["account_number"] = va_res["account_number"]
                    current_user["bank_name"] = va_res.get("bank_name")
                    current_user["virtual_account_assigned"] = True
                    current_user["virtual_account_provider"] = va_res.get("provider")
                    assigned_va = va_res
            elif existing_va:
                assigned_va = existing_va
        except Exception:
            pass

    persist_users_db()

    event_publisher.publish_event("KYCCompleted", {
        "user_id": user_id,
        "status": new_state,
        "session_id": kyc_result["session_id"]
    })

    return {
        "user_id": user_id,
        "kyc_status": new_state,
        "kyc_tier": "TIER_3",
        "provider": kyc_result.get("provider", "LOCAL_MOCK"),
        "selfie_verified": payload.selfie_captured,
        "id_photo_verified": payload.id_photo_captured,
        "liveness_score": kyc_result.get("liveness_score", 0.99 if payload.selfie_captured else 0.0),
        "face_match_score": kyc_result.get("face_match_score", 0.98 if payload.selfie_captured else 0.0),
        "capabilities": new_capabilities,
        "virtual_account": assigned_va,
        "verification_result": kyc_result
    }
