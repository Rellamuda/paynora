import redis
from app.config import settings

class RedisClient:
    def __init__(self):
        self.client = None

    def connect(self):
        try:
            self.client = redis.Redis(
                host=settings.REDIS_HOST,
                port=settings.REDIS_PORT,
                decode_responses=True,
                socket_timeout=5
            )
        except Exception as e:
            print(f"Redis connection error: {e}")

    def ping(self) -> bool:
        if not self.client:
            self.connect()
        try:
            return self.client.ping()
        except Exception:
            return False

redis_client = RedisClient()
