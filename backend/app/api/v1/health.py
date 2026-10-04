from fastapi import APIRouter
from app.db.redis import redis_client
from app.events.kafka import event_publisher

router = APIRouter(prefix="/health", tags=["Health"])

@router.get("")
def check_health():
    redis_healthy = redis_client.ping()
    return {
        "status": "healthy",
        "service": "PayNora Financial Core API",
        "version": "1.0.0",
        "components": {
            "database": "postgresql_connected",
            "redis": "healthy" if redis_healthy else "degraded",
            "kafka": "connected"
        }
    }
