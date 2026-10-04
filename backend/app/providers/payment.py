from typing import Dict, Any
import uuid

class MockPaymentProvider:
    """
    Vendor-agnostic mock payment provider interface.
    """
    @staticmethod
    def create_payment_charge(amount: str, currency: str, reference: str) -> Dict[str, Any]:
        provider_tx_id = f"pay_tx_{uuid.uuid4().hex[:10]}"
        return {
            "provider_tx_id": provider_tx_id,
            "status": "SUCCESS",
            "amount": amount,
            "currency": currency,
            "reference": reference,
            "provider_name": "MockGlobalPaymentRail"
        }

    @staticmethod
    def process_payout(amount: str, currency: str, recipient_details: Dict[str, Any]) -> Dict[str, Any]:
        payout_id = f"pyo_{uuid.uuid4().hex[:10]}"
        return {
            "payout_id": payout_id,
            "status": "COMPLETED",
            "amount": amount,
            "currency": currency,
            "recipient_name": recipient_details.get("name", "Recipient")
        }
