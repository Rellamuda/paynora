from typing import Dict, Any, List
import uuid

FRAUD_EVENTS: List[Dict[str, Any]] = []

class FraudDetectionEngine:
    @staticmethod
    def analyze_event(event_type: str, user_id: str, metadata: Dict[str, Any]) -> Dict[str, Any]:
        is_suspicious = False
        rule_triggered = None

        if event_type == "TRANSFER_ATTEMPT":
            amount = float(metadata.get("amount", 0))
            if amount > 10000000:  # > 10,000,000 NGN
                is_suspicious = True
                rule_triggered = "VELOCITY_SPIKE_LARGE_AMOUNT"
        elif event_type == "LOGIN":
            ip = metadata.get("ip_address", "")
            if ip.startswith("192.168.999"):  # Mock anomalous IP range
                is_suspicious = True
                rule_triggered = "ANOMALOUS_IP_LOCATION"

        fraud_record = {
            "event_id": f"frd_{uuid.uuid4().hex[:10]}",
            "event_type": event_type,
            "user_id": user_id,
            "is_suspicious": is_suspicious,
            "rule_triggered": rule_triggered,
            "metadata": metadata,
            "created_at": "2026-10-04T11:47:00Z"
        }

        if is_suspicious:
            FRAUD_EVENTS.append(fraud_record)

        return fraud_record

    @staticmethod
    def get_all_fraud_events() -> List[Dict[str, Any]]:
        return FRAUD_EVENTS
