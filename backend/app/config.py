import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_NAME: str = "PayNora Global Financial Core"
    ENV: str = "development"
    PORT: int = 8000
    HOST: str = "0.0.0.0"

    # PostgreSQL Database
    POSTGRES_HOST: str = os.getenv("POSTGRES_HOST", "localhost")
    POSTGRES_PORT: int = int(os.getenv("POSTGRES_PORT", "5432"))
    POSTGRES_USER: str = os.getenv("POSTGRES_USER", "paynora_user")
    POSTGRES_PASSWORD: str = os.getenv("POSTGRES_PASSWORD", "paynora_password")
    POSTGRES_DB: str = os.getenv("POSTGRES_DB", "paynora_db")

    @property
    def DATABASE_URL(self) -> str:
        return f"postgresql://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"

    # Redis
    REDIS_HOST: str = os.getenv("REDIS_HOST", "localhost")
    REDIS_PORT: int = int(os.getenv("REDIS_PORT", "6379"))

    # Kafka
    KAFKA_BOOTSTRAP_SERVERS: str = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")

    # Security
    JWT_SECRET: str = os.getenv("JWT_SECRET", "super_secret_paynora_jwt_key_2026_dev")
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # Payment Gateways (Smart Dual Engine - Loaded from Environment)
    PAYSTACK_SECRET_KEY: str = os.getenv("PAYSTACK_SECRET_KEY", "")
    PAYSTACK_PUBLIC_KEY: str = os.getenv("PAYSTACK_PUBLIC_KEY", "")
    FLW_SECRET_KEY: str = os.getenv("FLW_SECRET_KEY", "")
    FLW_PUBLIC_KEY: str = os.getenv("FLW_PUBLIC_KEY", "")
    FLW_ENCRYPTION_KEY: str = os.getenv("FLW_ENCRYPTION_KEY", "")
    FLW_WEBHOOK_HASH: str = os.getenv("FLW_WEBHOOK_HASH", "N7xKp9Qv2Lm8Rt4Yz6Hs1Wc5Jf3Bn0Dx8K")
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-3.8-flash")

settings = Settings()
