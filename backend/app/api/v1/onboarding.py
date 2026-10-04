from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from app.api.v1.auth import get_current_user
from app.onboarding.engine import ProgressiveOnboardingEngine, ONBOARDING_STEPS

router = APIRouter(prefix="/onboarding", tags=["Onboarding"])

class StepAnswerPayload(BaseModel):
    step_id: str
    answer: str

@router.get("/session")
def get_onboarding_session(current_user: dict = Depends(get_current_user)):
    user_id = current_user["user_id"]
    session = ProgressiveOnboardingEngine.get_or_create_session(user_id)
    step_idx = session["current_step_index"]
    current_step = ONBOARDING_STEPS[step_idx] if step_idx < len(ONBOARDING_STEPS) else None

    return {
        "session": session,
        "total_steps": len(ONBOARDING_STEPS),
        "current_step": current_step
    }

@router.post("/step")
def submit_onboarding_step(
    payload: StepAnswerPayload,
    current_user: dict = Depends(get_current_user)
):
    user_id = current_user["user_id"]
    session = ProgressiveOnboardingEngine.submit_step_answer(user_id, payload.step_id, payload.answer)
    return {
        "session": session,
        "message": "Answer saved server-side."
    }
