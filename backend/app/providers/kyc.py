import uuid
from typing import Dict, Any

class MockKYCProvider:
    """
    Mock identity verification provider simulating document verification and liveness checks.
    """
    @staticmethod
    def verify_identity(user_id: str, document_type: str, document_number: str) -> Dict[str, Any]:
        session_id = f"kyc_sess_{uuid.uuid4().hex[:10]}"
        # Mock deterministic rule: reject if document number contains "REJECT"
        if "REJECT" in document_number.upper():
            return {
                "session_id": session_id,
                "status": "REJECTED",
                "reason": "Document invalid or altered.",
                "confidence_score": 0.12
            }
        return {
            "session_id": session_id,
            "status": "APPROVED",
            "reason": "Identity document verified successfully.",
            "confidence_score": 0.98
        }
