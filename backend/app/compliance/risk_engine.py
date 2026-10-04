from decimal import Decimal
from typing import Dict, Any, List

class RiskPolicyEngine:
    """
    Risk Assessment Engine evaluating transaction amount, velocity, corridor risk, and customer KYC level.
    """
    @staticmethod
    def evaluate_transaction_risk(
        user_id: str,
        amount: Decimal,
        currency: str,
        source_country: str,
        destination_country: str,
        kyc_status: str
    ) -> Dict[str, Any]:
        risk_score = 0.0
        reasons: List[str] = []

        # 1. Amount Threshold Checks
        if amount > Decimal("5000000"):  # > 5,000,000 NGN
            risk_score += 40.0
            reasons.append("High monetary value transaction threshold exceeded.")
        elif amount > Decimal("1000000"):
            risk_score += 15.0
            reasons.append("Moderate monetary value threshold.")

        # 2. Corridor Risk Evaluation
        if source_country.upper() != destination_country.upper():
            risk_score += 10.0
            reasons.append("Cross-border international payment corridor.")

        # 3. KYC Status Weighting
        if kyc_status != "APPROVED":
            risk_score += 30.0
            reasons.append("Customer identity verification not fully approved.")

        # Risk Classification
        if risk_score >= 50.0:
            risk_level = "HIGH"
            requires_manual_review = True
        elif risk_score >= 20.0:
            risk_level = "MEDIUM"
            requires_manual_review = False
        else:
            risk_level = "LOW"
            requires_manual_review = False

        return {
            "risk_score": min(risk_score, 100.0),
            "risk_level": risk_level,
            "requires_manual_review": requires_manual_review,
            "risk_factors": reasons
        }
