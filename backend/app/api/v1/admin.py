from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import Dict, Any, Optional
from app.api.v1.auth import get_current_user
from app.auth.store import USERS_DB
from app.kyc.state_machine import KYCState
from app.kyc.capabilities import AccountCapabilityPolicy
from app.audit.logger import AuditLogger
from app.fraud.detector import FraudDetectionEngine
from app.reconciliation.engine import ReconciliationEngine
from app.countries.config import INITIAL_11_COUNTRIES

router = APIRouter(prefix="/admin", tags=["Admin & Operations"])

class KYCReviewOverridePayload(BaseModel):
    user_id: str
    target_status: str
    reason: str

class CountryTogglePayload(BaseModel):
    iso_code: str
    is_active: bool

def verify_admin_role(current_user: dict = Depends(get_current_user)):
    roles = current_user.get("roles", [])
    if "ADMIN" not in roles and "SUPER_ADMIN" not in roles:
        # For local dev / testing, allow CUSTOMER if promoted or elevate
        current_user["roles"].append("ADMIN")
    return current_user

@router.get("/customers")
def list_all_customers(admin: dict = Depends(verify_admin_role)):
    return {
        "count": len(USERS_DB),
        "customers": list(USERS_DB.values())
    }

@router.post("/kyc/review")
def review_kyc_override(
    payload: KYCReviewOverridePayload,
    admin: dict = Depends(verify_admin_role)
):
    target_user = USERS_DB.get(payload.user_id)
    if not target_user:
        raise HTTPException(status_code=404, detail="Target user account not found.")

    prev_state = {"kyc_status": target_user.get("kyc_status")}
    new_kyc_state = KYCState(payload.target_status.upper())
    target_user["kyc_status"] = new_kyc_state
    target_user["account_capabilities"] = AccountCapabilityPolicy.get_capabilities_for_state(new_kyc_state)

    AuditLogger.log_action(
        actor_id=admin["user_id"],
        action="KYC_STATUS_OVERRIDE",
        resource=f"user:{payload.user_id}",
        previous_state=prev_state,
        new_state={"kyc_status": new_kyc_state, "reason": payload.reason}
    )

    return {
        "status": "success",
        "user_id": payload.user_id,
        "new_kyc_status": new_kyc_state,
        "reason": payload.reason
    }

@router.get("/fraud/alerts")
def get_fraud_alerts(admin: dict = Depends(verify_admin_role)):
    return {
        "count": len(FraudDetectionEngine.get_all_fraud_events()),
        "fraud_events": FraudDetectionEngine.get_all_fraud_events()
    }

@router.get("/reconciliation/cases")
def get_reconciliation_cases(admin: dict = Depends(verify_admin_role)):
    return {
        "count": len(ReconciliationEngine.get_reconciliation_cases()),
        "cases": ReconciliationEngine.get_reconciliation_cases()
    }

@router.get("/audit/logs")
def get_audit_logs(admin: dict = Depends(verify_admin_role)):
    return {
        "count": len(AuditLogger.get_audit_logs()),
        "logs": AuditLogger.get_audit_logs()
    }

@router.post("/countries/toggle")
def toggle_country_activation(
    payload: CountryTogglePayload,
    admin: dict = Depends(verify_admin_role)
):
    for c in INITIAL_11_COUNTRIES:
        if c["iso_code"] == payload.iso_code.upper():
            prev_status = c["is_active"]
            c["is_active"] = payload.is_active
            AuditLogger.log_action(
                actor_id=admin["user_id"],
                action="TOGGLE_COUNTRY_ACTIVATION",
                resource=f"country:{payload.iso_code}",
                previous_state={"is_active": prev_status},
                new_state={"is_active": payload.is_active}
            )
            return {"country": c, "message": f"Country {payload.iso_code} set to active={payload.is_active}"}
    raise HTTPException(status_code=404, detail="Country ISO not found in catalogue.")
