from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel
from typing import Optional, Dict, Any
from app.notifications.service import NotificationService

router = APIRouter(prefix="/notifications", tags=["Notifications & Alerts"])

class DispatchNotificationRequest(BaseModel):
    user_id: str
    title: str
    message: str
    type: str = "TRANSACTION_ALERT"
    data: Optional[Dict[str, Any]] = None

@router.get("")
def list_notifications(
    user_id: str = Query("usr_demo", description="Target user ID"),
    unread_only: bool = Query(False, description="Filter only unread alerts")
):
    """Retrieve user notifications and live transaction alerts."""
    items = NotificationService.get_user_notifications(user_id, unread_only=unread_only)
    unread_count = len([n for n in items if not n["read"]])
    return {
        "notifications": items,
        "total": len(items),
        "unread_count": unread_count
    }

@router.post("/{notification_id}/read")
def mark_notification_read(notification_id: str):
    """Mark a single notification as read."""
    success = NotificationService.mark_as_read(notification_id)
    if not success:
        raise HTTPException(status_code=404, detail="Notification not found")
    return {"status": "SUCCESS", "notification_id": notification_id, "read": True}

@router.post("/read-all")
def mark_all_notifications_read(user_id: str = Query("usr_demo")):
    """Mark all notifications for a user as read."""
    updated = NotificationService.mark_all_read(user_id)
    return {"status": "SUCCESS", "user_id": user_id, "marked_count": updated}

@router.post("/dispatch", status_code=status.HTTP_201_CREATED)
def dispatch_notification(payload: DispatchNotificationRequest):
    """Dispatch an alert / push notification to a user."""
    result = NotificationService.dispatch(
        user_id=payload.user_id,
        title=payload.title,
        message=payload.message,
        notification_type=payload.type,
        data=payload.data
    )
    return {"status": "DISPATCHED", "notification": result}
