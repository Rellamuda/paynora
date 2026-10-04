from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List

class UserRegisterRequest(BaseModel):
    first_name: str = Field(..., min_length=1)
    last_name: str = Field(..., min_length=1)
    email: EmailStr
    phone: str = Field(..., min_length=5)
    country_iso: str = Field("NG", min_length=2, max_length=2)
    password: str = Field(..., min_length=8)

class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str

class OTPVerifyRequest(BaseModel):
    email: EmailStr
    otp_code: str = Field(..., min_length=6, max_length=6)

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    email: str
    roles: List[str]

class UserProfileResponse(BaseModel):
    user_id: str
    first_name: str
    last_name: str
    email: str
    phone: str
    country_iso: str
    is_email_verified: bool
    is_phone_verified: bool
    kyc_status: str
    roles: List[str]
    account_capabilities: List[str]
