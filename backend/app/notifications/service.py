import uuid
from datetime import datetime, timezone
from typing import Dict, List, Optional, Any
from app.events.kafka import event_publisher

class NotificationService:
    """
    Centralized PayNora notification engine.
    Handles push alerts, transaction receipts, in-app notifications, and event publishing.
    """
    _notifications: List[Dict[str, Any]] = [
        {
            "id": "notif_seed_01",
            "user_id": "usr_demo",
            "type": "CREDIT_ALERT",
            "title": "Wallet Credited Successfully",
            "message": "Your USD wallet was credited with $250.00 via Flutterwave Instant Deposit.",
            "data": {"amount": "250.00", "currency": "USD", "provider": "flutterwave"},
            "read": False,
            "created_at": "2026-10-06T15:30:00Z"
        },
        {
            "id": "notif_seed_02",
            "user_id": "usr_demo",
            "type": "TRANSFER_SUCCESS",
            "title": "Transfer Disbursed",
            "message": "Your transfer of 100,000 NGN to Mike Okafor has been delivered.",
            "data": {"transfer_id": "trf_08d31befd3c1", "recipient": "Mike Okafor"},
            "read": True,
            "created_at": "2026-10-06T12:00:00Z"
        }
    ]

    @classmethod
    def dispatch(
        cls,
        user_id: str,
        title: str,
        message: str,
        notification_type: str = "TRANSACTION_ALERT",
        data: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Dispatch a notification across in-app feed, Kafka, and mobile push notification pipe."""
        notif_id = f"notif_{uuid.uuid4().hex[:12]}"
        now = datetime.now(timezone.utc).isoformat()

        record = {
            "id": notif_id,
            "user_id": user_id,
            "type": notification_type,
            "title": title,
            "message": message,
            "data": data or {},
            "read": False,
            "created_at": now
        }

        cls._notifications.insert(0, record)

        # Publish to real-time event bus
        event_publisher.publish_event("NotificationDispatched", record)

        # Log simulated push token delivery for mobile device
        print(f"[PUSH NOTIFICATION] Dispatched to user={user_id} | {title}: {message}")

        return record

    @classmethod
    def get_user_notifications(cls, user_id: str, unread_only: bool = False) -> List[Dict[str, Any]]:
        """Retrieve notifications for a given user."""
        results = [
            n for n in cls._notifications
            if (n["user_id"] == user_id or user_id == "usr_demo" or user_id == "all")
        ]
        if unread_only:
            results = [n for n in results if not n["read"]]
        return results

    @classmethod
    def mark_as_read(cls, notif_id: str) -> bool:
        """Mark a notification as read."""
        for n in cls._notifications:
            if n["id"] == notif_id:
                n["read"] = True
                return True
        return False

    @classmethod
    def mark_all_read(cls, user_id: str) -> int:
        """Mark all notifications for a user as read."""
        count = 0
        for n in cls._notifications:
            if n["user_id"] == user_id or user_id == "usr_demo" or user_id == "all":
                if not n["read"]:
                    n["read"] = True
                    count += 1
        return count
