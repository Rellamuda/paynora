from fastapi import APIRouter, Depends
from app.auth.schemas import UserProfileResponse
from app.api.v1.auth import get_current_user

router = APIRouter(prefix="/users", tags=["Users & Profiles"])

@router.get("/me", response_model=UserProfileResponse)
def get_me(current_user: dict = Depends(get_current_user)):
    """Retrieve authenticated customer profile and capabilities."""
    return current_user
