from typing import List
from app.kyc.state_machine import KYCState

class AccountCapabilityPolicy:
    @staticmethod
    def get_capabilities_for_state(state: KYCState) -> List[str]:
        if state == KYCState.APPROVED:
            return [
                "VIEW_ACCOUNT",
                "ADD_FUNDS",
                "HOLD_FUNDS",
                "SEND_MONEY",
                "RECEIVE_MONEY",
                "ADD_BENEFICIARY",
                "EXCHANGE_CURRENCY",
                "WITHDRAW"
            ]
        elif state in [KYCState.SCREENING_IN_PROGRESS, KYCState.PENDING_REVIEW, KYCState.DOCUMENT_SUBMITTED]:
            return ["VIEW_ACCOUNT", "HOLD_FUNDS"]
        else:
            return ["VIEW_ACCOUNT"]
