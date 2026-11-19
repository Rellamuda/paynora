from typing import Dict, List, Any, Optional
import uuid
from app.storage import load_section, save_section

BENEFICIARIES_DB: Dict[str, List[Dict[str, Any]]] = load_section("beneficiaries_db", {})


def persist_beneficiaries_db() -> None:
    save_section("beneficiaries_db", BENEFICIARIES_DB)


class BeneficiaryStore:
    @staticmethod
    def get_user_beneficiaries(user_id: str) -> List[Dict[str, Any]]:
        if user_id not in BENEFICIARIES_DB:
            BENEFICIARIES_DB[user_id] = []
            persist_beneficiaries_db()
        return BENEFICIARIES_DB[user_id]

    @staticmethod
    def add_beneficiary(
        user_id: str,
        name: str,
        country_iso: str,
        currency: str,
        account_details: Dict[str, Any]
    ) -> Dict[str, Any]:
        beneficiaries = BeneficiaryStore.get_user_beneficiaries(user_id)
        ben_id = f"ben_{uuid.uuid4().hex[:10]}"
        new_ben = {
            "beneficiary_id": ben_id,
            "user_id": user_id,
            "name": name,
            "country_iso": country_iso.upper(),
            "currency": currency.upper(),
            "account_details": account_details,
            "created_at": "2026-10-04T11:41:00Z"
        }
        beneficiaries.append(new_ben)
        persist_beneficiaries_db()
        return new_ben
