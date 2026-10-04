from enum import Enum
from typing import Set

class TransferState(str, Enum):
    DRAFT = "DRAFT"
    AWAITING_CONFIRMATION = "AWAITING_CONFIRMATION"
    AWAITING_COMPLIANCE = "AWAITING_COMPLIANCE"
    AWAITING_FUNDING = "AWAITING_FUNDING"
    PROCESSING = "PROCESSING"
    PAYMENT_INITIATED = "PAYMENT_INITIATED"
    PAYMENT_PENDING = "PAYMENT_PENDING"
    FX_PENDING = "FX_PENDING"
    SETTLEMENT_PENDING = "SETTLEMENT_PENDING"
    AWAITING_RECIPIENT = "AWAITING_RECIPIENT"
    RECIPIENT_CURRENCY_SELECTED = "RECIPIENT_CURRENCY_SELECTED"
    PAYOUT_PROCESSING = "PAYOUT_PROCESSING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    CANCELLED = "CANCELLED"
    REFUNDED = "REFUNDED"

VALID_TRANSITIONS = {
    TransferState.DRAFT: {TransferState.AWAITING_CONFIRMATION, TransferState.CANCELLED},
    TransferState.AWAITING_CONFIRMATION: {TransferState.AWAITING_COMPLIANCE, TransferState.CANCELLED},
    TransferState.AWAITING_COMPLIANCE: {TransferState.AWAITING_FUNDING, TransferState.FAILED, TransferState.CANCELLED},
    TransferState.AWAITING_FUNDING: {TransferState.PROCESSING, TransferState.FAILED, TransferState.CANCELLED},
    TransferState.PROCESSING: {TransferState.PAYMENT_INITIATED, TransferState.FAILED},
    TransferState.PAYMENT_INITIATED: {TransferState.PAYMENT_PENDING, TransferState.FX_PENDING, TransferState.FAILED},
    TransferState.PAYMENT_PENDING: {TransferState.FX_PENDING, TransferState.FAILED},
    TransferState.FX_PENDING: {TransferState.SETTLEMENT_PENDING, TransferState.AWAITING_RECIPIENT, TransferState.FAILED},
    TransferState.AWAITING_RECIPIENT: {TransferState.RECIPIENT_CURRENCY_SELECTED, TransferState.FAILED},
    TransferState.RECIPIENT_CURRENCY_SELECTED: {TransferState.PAYOUT_PROCESSING, TransferState.FAILED},
    TransferState.PAYOUT_PROCESSING: {TransferState.COMPLETED, TransferState.FAILED, TransferState.REFUNDED},
    TransferState.COMPLETED: set(),
    TransferState.FAILED: {TransferState.REFUNDED},
    TransferState.CANCELLED: set(),
    TransferState.REFUNDED: set()
}

class TransferStateMachine:
    @staticmethod
    def can_transition(current_state: TransferState, next_state: TransferState) -> bool:
        allowed = VALID_TRANSITIONS.get(current_state, set())
        return next_state in allowed

    @staticmethod
    def transition(current_state: TransferState, next_state: TransferState) -> TransferState:
        if not TransferStateMachine.can_transition(current_state, next_state):
            raise ValueError(f"Illegal state transition from {current_state} to {next_state}")
        return next_state
