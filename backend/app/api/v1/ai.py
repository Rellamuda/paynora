from fastapi import APIRouter, Depends
from pydantic import BaseModel
from app.api.v1.auth import get_current_user
from app.ai.assistant import AIFinancialAssistantEngine

router = APIRouter(prefix="/ai", tags=["AI Financial Assistant"])

class AIPromptPayload(BaseModel):
    prompt: str

@router.post("/chat")
def ai_assistant_chat(
    payload: AIPromptPayload,
    current_user: dict = Depends(get_current_user)
):
    user_id = current_user["user_id"]
    response = AIFinancialAssistantEngine.process_prompt(user_id, payload.prompt)
    return response
