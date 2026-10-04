from typing import List, Dict, Any, Optional

ONBOARDING_STEPS: List[Dict[str, Any]] = [
    {
        "id": "residence_country",
        "question": "Where do you live?",
        "type": "country",
        "placeholder": "Select your country of residence",
        "options": ["NG", "GB", "US", "CA", "AE", "GH", "ZA", "DE", "FR", "SA", "CN"]
    },
    {
        "id": "date_of_birth",
        "question": "When were you born?",
        "type": "date",
        "placeholder": "YYYY-MM-DD"
    },
    {
        "id": "residential_address",
        "question": "What is your primary residential address?",
        "type": "address",
        "placeholder": "Enter street name, city, and postal code"
    },
    {
        "id": "document_type",
        "question": "Select your verification ID document",
        "type": "select",
        "options": ["NATIONAL_ID", "PASSPORT", "DRIVERS_LICENSE"]
    },
    {
        "id": "document_number",
        "question": "Enter your ID document number",
        "type": "text",
        "placeholder": "e.g. A12345678"
    }
]

ONBOARDING_SESSIONS: Dict[str, Dict[str, Any]] = {}

class ProgressiveOnboardingEngine:
    @staticmethod
    def get_or_create_session(user_id: str) -> Dict[str, Any]:
        if user_id not in ONBOARDING_SESSIONS:
            ONBOARDING_SESSIONS[user_id] = {
                "user_id": user_id,
                "current_step_index": 0,
                "answers": {},
                "is_completed": False
            }
        return ONBOARDING_SESSIONS[user_id]

    @staticmethod
    def submit_step_answer(user_id: str, step_id: str, answer: str) -> Dict[str, Any]:
        session = ProgressiveOnboardingEngine.get_or_create_session(user_id)
        session["answers"][step_id] = answer

        # Progress to next step if matching current step ID
        current_step = ONBOARDING_STEPS[session["current_step_index"]]
        if current_step["id"] == step_id and session["current_step_index"] < len(ONBOARDING_STEPS) - 1:
            session["current_step_index"] += 1
        elif session["current_step_index"] == len(ONBOARDING_STEPS) - 1:
            session["is_completed"] = True

        return session
