from fastapi import APIRouter, HTTPException, Depends, Header, status
from typing import Optional
from app.auth.schemas import (
    UserRegisterRequest,
    UserLoginRequest,
    OTPVerifyRequest,
    TokenResponse,
    UserProfileResponse
)
from app.auth.store import UserStore
from app.auth.security import verify_password, create_access_token, decode_access_token
from app.events.kafka import event_publisher

router = APIRouter(prefix="/auth", tags=["Authentication"])

def get_current_user(authorization: Optional[str] = Header(None)) -> dict:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid authentication token header."
        )
    token = authorization.split(" ")[1]
    payload = decode_access_token(token)
    if not payload or "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired access token."
        )
    user = UserStore.get_by_id(payload["sub"])
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User associated with token not found."
        )
    return user

@router.post("/register", response_model=UserProfileResponse, status_code=status.HTTP_201_CREATED)
def register_user(payload: UserRegisterRequest):
    try:
        user = UserStore.create_user(
            first_name=payload.first_name,
            last_name=payload.last_name,
            email=payload.email,
            phone=payload.phone,
            country_iso=payload.country_iso,
            password=payload.password
        )
        event_publisher.publish_event("UserCreated", {"user_id": user["user_id"], "email": user["email"]})
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

    access_token = create_access_token(data={"sub": user["user_id"], "email": user["email"], "roles": user["roles"]})
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user["user_id"],
        "email": user["email"],
        "roles": user["roles"]
    }
