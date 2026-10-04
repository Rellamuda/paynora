from typing import Dict, List, Any, Optional
import uuid

BENEFICIARIES_DB: Dict[str, List[Dict[str, Any]]] = {}

class BeneficiaryStore:
    @staticmethod
    def get_user_beneficiaries(user_id: str) -> List[Dict[str, Any]]:
        if user_id not in BENEFICIARIES_DB:
            BENEFICIARIES_DB[user_id] = [
                {
                    "beneficiary_id": "ben_john_123",
                    "user_id": user_id,
                    "name": "John Doe",
                    "email": "john.london@example.com",
                    "country_iso": "GB",
                    "currency": "GBP",
                    "account_details": {
                        "sort_code": "10-20-30",
                        "account_number": "87654321"
                    },
                    "created_at": "2026-10-04T11:40:00Z"
                }
            ]
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
        return new_ben
