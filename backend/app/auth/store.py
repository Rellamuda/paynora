from typing import Dict, Any, Optional
import hashlib
import re
import uuid
from app.auth.security import hash_password, verify_password
from app.storage import load_section, save_section

# Persistent auth user database (survives container rebuilds & server restarts)
USERS_DB: Dict[str, Dict[str, Any]] = load_section("users_db", {})
OTP_STORE: Dict[str, str] = load_section("otp_store", {})


def persist_users_db() -> None:
    save_section("users_db", USERS_DB)
    save_section("otp_store", OTP_STORE)


def generate_account_identifiers(email: str, first_name: str, country_iso: str) -> Dict[str, str]:
    """
    Generate deterministic, unique 10-digit PayNora Account Number, @paynora_tag,
    and Global Wallet Routing Address (PN-<ISO>-<10-digit>) for an onboarded user.
    """
    email_clean = (email or "user@paynora.com").lower().strip()
    digest = int(hashlib.sha256(email_clean.encode("utf-8")).hexdigest()[:12], 16)
    eight_digits = f"{digest % 100000000:08d}"
    account_number = f"90{eight_digits}"
    clean_first = re.sub(r"[^a-z0-9]", "", (first_name or "user").lower()) or "user"
    tag_bare = f"{clean_first}{account_number[-3:]}"
    c_iso = (country_iso or "NG").upper()
    return {
        "account_number": account_number,
        "tag": tag_bare,
        "paynora_tag": f"@{tag_bare}",
        "wallet_address": f"PN-{c_iso}-{account_number}",
    }


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
        c_iso = (country_iso or "NG").upper()
        ids = generate_account_identifiers(email_clean, first_name, c_iso)
        user_record = {
            "user_id": user_id,
            "first_name": first_name.strip(),
            "last_name": last_name.strip(),
            "email": email_clean,
            "phone": phone.strip(),
            "country_iso": c_iso,
            "account_number": ids["account_number"],
            "tag": ids["tag"],
            "paynora_tag": ids["paynora_tag"],
            "wallet_address": ids["wallet_address"],
            "hashed_password": hash_password(password),
            "is_email_verified": False,
            "is_phone_verified": False,
            "kyc_status": "NOT_STARTED",
            "roles": ["CUSTOMER"],
            "account_capabilities": [
                "VIEW_ACCOUNT",
                "SEND_MONEY",
                "RECEIVE_MONEY",
                "CONVERT_CURRENCY",
                "PAY_BILLS",
            ],
            "created_at": "2026-10-04T11:35:00Z"
        }
        USERS_DB[user_id] = user_record
        OTP_STORE[email_clean] = "123456"
        persist_users_db()
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
                persist_users_db()
            return True
        return False

    @staticmethod
    def delete_user(user_id: str) -> bool:
        from app.wallets.models import USER_WALLETS, persist_wallets_db
        USER_WALLETS.pop(user_id, None)
        persist_wallets_db()
        removed = USERS_DB.pop(user_id, None)
        if removed and removed.get("email"):
            OTP_STORE.pop(removed["email"], None)
        persist_users_db()
        return removed is not None


# Seed official Apple App Store & Google Play Store Reviewer Test Account
def _seed_store_reviewer_account() -> None:
    reviewer_email = "reviewer@paynora.com"
    if any(u.get("email") == reviewer_email for u in USERS_DB.values()):
        return
    USERS_DB["usr_store_reviewer"] = {
        "user_id": "usr_store_reviewer",
        "first_name": "AppStore",
        "last_name": "Reviewer",
        "email": reviewer_email,
        "phone": "+2348099999999",
        "country_iso": "NG",
        "account_number": "9088888888",
        "tag": "reviewer888",
        "paynora_tag": "@reviewer888",
        "wallet_address": "PN-NG-9088888888",
        "hashed_password": hash_password("PayNoraReview2026!"),
        "is_email_verified": True,
        "is_phone_verified": True,
        "kyc_status": "VERIFIED",
        "roles": ["CUSTOMER"],
        "account_capabilities": [
            "VIEW_ACCOUNT",
            "SEND_MONEY",
            "RECEIVE_MONEY",
            "CONVERT_CURRENCY",
            "PAY_BILLS",
        ],
        "created_at": "2026-10-04T11:35:00Z",
    }
    persist_users_db()


_seed_store_reviewer_account()
