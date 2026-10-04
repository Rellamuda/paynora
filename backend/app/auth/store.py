from typing import Dict, Any, Optional
import uuid
from app.auth.security import hash_password, verify_password

# In-memory auth user database for testing and MVP core
USERS_DB: Dict[str, Dict[str, Any]] = {}
OTP_STORE: Dict[str, str] = {}

class UserStore:
    @staticmethod
    def create_user(
        first_name: str,
        last_name: str,
        email: str,
        phone: str,
        country_iso: str,
        password: str
    ) -> Dict[str, Any]:
        email_clean = email.lower().strip()
        for u in USERS_DB.values():
            if u["email"] == email_clean:
                raise ValueError("An account with this email address already exists.")

        user_id = f"usr_{uuid.uuid4().hex[:12]}"
        user_record = {
            "user_id": user_id,
            "first_name": first_name,
            "last_name": last_name,
            "email": email_clean,
            "phone": phone,
            "country_iso": country_iso.upper(),
            "hashed_password": hash_password(password),
            "is_email_verified": False,
            "is_phone_verified": False,
            "kyc_status": "NOT_STARTED",
            "roles": ["CUSTOMER"],
            "account_capabilities": ["VIEW_ACCOUNT"],
            "created_at": "2026-10-04T11:35:00Z"
        }
        USERS_DB[user_id] = user_record
        # Create default OTP (fixed 123456 for dev testing)
        OTP_STORE[email_clean] = "123456"
        return user_record

    @staticmethod
    def get_by_email(email: str) -> Optional[Dict[str, Any]]:
        email_clean = email.lower().strip()
        for u in USERS_DB.values():
            if u["email"] == email_clean:
                return u
        return None

    @staticmethod
    def get_by_id(user_id: str) -> Optional[Dict[str, Any]]:
        return USERS_DB.get(user_id)

    @staticmethod
    def verify_otp(email: str, otp_code: str) -> bool:
        email_clean = email.lower().strip()
        expected_otp = OTP_STORE.get(email_clean)
        if expected_otp and expected_otp == otp_code:
            user = UserStore.get_by_email(email_clean)
            if user:
                user["is_email_verified"] = True
                user["is_phone_verified"] = True
            return True
        return False
