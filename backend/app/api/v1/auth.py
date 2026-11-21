from fastapi import APIRouter, HTTPException, Depends, Header, status
from typing import Optional
from app.auth.schemas import (
    UserRegisterRequest,
    UserLoginRequest,
    OTPVerifyRequest,
    TokenResponse,
    UserProfileResponse
)
from app.auth.store import UserStore, USERS_DB, generate_account_identifiers, persist_users_db
from app.auth.security import verify_password, create_access_token, decode_access_token
from app.events.kafka import event_publisher

router = APIRouter(prefix="/auth", tags=["Authentication"])


def _sync_virtual_account_to_user(user: dict) -> dict:
    try:
        from app.providers.virtual_accounts import get_user_virtual_account
        va = get_user_virtual_account(user.get("user_id", ""))
        if va and va.get("account_number"):
            user["account_number"] = va["account_number"]
            user["bank_name"] = va.get("bank_name")
            user["virtual_account_assigned"] = True
            user["virtual_account_provider"] = va.get("provider")
            return user
    except Exception:
        pass
    user.setdefault("bank_name", None)
    user.setdefault("virtual_account_assigned", False)
    user.setdefault("virtual_account_provider", None)
    return user


def _ensure_user_identifiers(user: dict) -> dict:
    if not user.get("account_number") or not user.get("paynora_tag") or not user.get("wallet_address"):
        ids = generate_account_identifiers(
            user.get("email", "customer@paynora.com"),
            user.get("first_name", "user"),
            user.get("country_iso", "NG"),
        )
        user.setdefault("account_number", ids["account_number"])
        user.setdefault("tag", ids["tag"])
        user.setdefault("paynora_tag", ids["paynora_tag"])
        user.setdefault("wallet_address", ids["wallet_address"])
    user.setdefault("phone", "+2348000000000")
    user.setdefault("country_iso", "NG")
    user.setdefault("is_email_verified", True)
    user.setdefault("is_phone_verified", True)
    user.setdefault("kyc_status", "VERIFIED")
    user.setdefault("account_capabilities", ["VIEW_ACCOUNT", "SEND_MONEY", "RECEIVE_MONEY", "CONVERT_CURRENCY", "PAY_BILLS"])
    return _sync_virtual_account_to_user(user)


def get_current_user(authorization: Optional[str] = Header(None)) -> dict:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required. Please log in.",
        )

    token = authorization.split(" ")[1]
    payload = decode_access_token(token)
    if not payload or not payload.get("sub"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Your session has expired. Please log in again.",
        )
    sub = payload.get("sub")
    user = UserStore.get_by_id(sub)
    if not user:
        email = payload.get("email", "customer@paynora.com") if payload else "customer@paynora.com"
        first_name = payload.get("first_name", "SendMoni") if payload else "SendMoni"
        last_name = payload.get("last_name", "Customer") if payload else "Customer"
        country_iso = (payload.get("country_iso", "NG") if payload else "NG").upper()
        user = _ensure_user_identifiers({
            "user_id": sub or "usr_demo_customer",
            "email": email,
            "first_name": first_name,
            "last_name": last_name,
            "phone": payload.get("phone", "+2348000000000") if payload else "+2348000000000",
            "country_iso": country_iso,
            "account_number": payload.get("account_number") if payload else None,
            "paynora_tag": payload.get("paynora_tag") if payload else None,
            "wallet_address": payload.get("wallet_address") if payload else None,
            "roles": ["CUSTOMER"],
        })
        USERS_DB[user["user_id"]] = user
        persist_users_db()
    return _ensure_user_identifiers(user)


@router.post("/register", response_model=UserProfileResponse, status_code=status.HTTP_201_CREATED)
async def register_user(payload: UserRegisterRequest):
    try:
        user = UserStore.create_user(
            first_name=payload.first_name,
            last_name=payload.last_name,
            email=payload.email,
            phone=payload.phone,
            country_iso=payload.country_iso,
            password=payload.password
        )
        # Immediately auto-provision a real Nigerian Dedicated Virtual Account (NUBAN) on onboarding
        if (user.get("country_iso") or "NG").upper() == "NG":
            try:
                from app.providers.virtual_accounts import provision_virtual_account
                clean_bvn = (payload.bvn or "").strip()
                va_res = None
                if len(clean_bvn) == 11 and clean_bvn.isdigit():
                    va_res = await provision_virtual_account(
                        user=user,
                        preferred_provider="FLUTTERWAVE",
                        preferred_bank="titan-paystack",
                        bvn=clean_bvn,
                    )
                else:
                    va_res = await provision_virtual_account(
                        user=user,
                        preferred_provider="PAYSTACK",
                        preferred_bank="titan-paystack",
                    )
                    if va_res.get("status") != "SUCCESS":
                        va_res = await provision_virtual_account(
                            user=user,
                            preferred_provider="PAYSTACK",
                            preferred_bank="wema-bank",
                        )
                if va_res and va_res.get("status") == "SUCCESS" and va_res.get("account_number"):
                    user["account_number"] = va_res["account_number"]
                    user["bank_name"] = va_res.get("bank_name")
                    user["virtual_account_assigned"] = True
                    user["virtual_account_provider"] = va_res.get("provider")
                    persist_users_db()
            except Exception:
                pass

        _ensure_user_identifiers(user)
        event_publisher.publish_event("UserCreated", {
            "user_id": user["user_id"],
            "email": user["email"],
            "account_number": user["account_number"],
            "bank_name": user.get("bank_name"),
            "virtual_account_assigned": user.get("virtual_account_assigned", False),
            "paynora_tag": user["paynora_tag"],
            "wallet_address": user["wallet_address"],
        })
        return user
    except ValueError as err:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(err))


@router.post("/verify-otp")
def verify_otp(payload: OTPVerifyRequest):
    success = UserStore.verify_otp(payload.email, payload.otp_code)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid OTP code or email address."
        )
    return {"status": "verified", "message": "Email and phone successfully verified."}


@router.post("/login", response_model=TokenResponse)
def login(payload: UserLoginRequest):
    user = UserStore.get_by_email(payload.email)
    if not user or not verify_password(payload.password, user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email address or password."
        )
    _ensure_user_identifiers(user)
    access_token = create_access_token(data={
        "sub": user["user_id"],
        "email": user["email"],
        "first_name": user["first_name"],
        "last_name": user["last_name"],
        "phone": user.get("phone", ""),
        "country_iso": user.get("country_iso", "NG"),
        "account_number": user["account_number"],
        "paynora_tag": user["paynora_tag"],
        "wallet_address": user["wallet_address"],
        "roles": user["roles"]
    })
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user["user_id"],
        "email": user["email"],
        "first_name": user["first_name"],
        "last_name": user["last_name"],
        "country_iso": user.get("country_iso", "NG"),
        "account_number": user["account_number"],
        "bank_name": user.get("bank_name"),
        "virtual_account_assigned": bool(user.get("virtual_account_assigned", False)),
        "virtual_account_provider": user.get("virtual_account_provider"),
        "paynora_tag": user["paynora_tag"],
        "wallet_address": user["wallet_address"],
        "roles": user["roles"]
    }


@router.delete("/account")
def delete_my_account(current_user: dict = Depends(get_current_user)):
    """
    In-App Account & Personal Data Deletion endpoint.
    Required by Apple App Store Guideline 5.1.1(v) and Google Play User Data Policy.
    """
    user_id = current_user.get("user_id")
    if user_id:
        UserStore.delete_user(user_id)
    event_publisher.publish_event("UserAccountDeleted", {"user_id": user_id})
    return {
        "status": "DELETED",
        "user_id": user_id,
        "message": "Your SendMoni account, wallets, and personal data have been permanently deleted."
    }
