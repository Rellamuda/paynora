from typing import Dict, Any, List
from datetime import datetime
import uuid

AUDIT_LOGS: List[Dict[str, Any]] = []

class AuditLogger:
    @staticmethod
    def log_action(
        actor_id: str,
        action: str,
        resource: str,
        previous_state: Dict[str, Any] = None,
        new_state: Dict[str, Any] = None,
        ip_address: str = "127.0.0.1"
    ) -> Dict[str, Any]:
        log_entry = {
            "audit_id": f"aud_{uuid.uuid4().hex[:12]}",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "actor_id": actor_id,
            "action": action,
            "resource": resource,
            "previous_state": previous_state,
            "new_state": new_state,
            "ip_address": ip_address
        }
        AUDIT_LOGS.append(log_entry)
        return log_entry

    @staticmethod
    def get_audit_logs() -> List[Dict[str, Any]]:
        return AUDIT_LOGS
