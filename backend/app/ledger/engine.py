from decimal import Decimal
from typing import List, Dict, Any
import uuid

class DoubleEntryLedgerEngine:
    """
    Deterministic immutable double-entry accounting engine.
    Enforces total debits == total credits with Decimal precision.
    """
    @staticmethod
    def validate_transaction(entries: List[Dict[str, Any]]) -> bool:
        total_debits = Decimal('0.00000000')
        total_credits = Decimal('0.00000000')

        for entry in entries:
            amount = Decimal(str(entry.get("amount", "0")))
            if amount <= Decimal('0'):
                raise ValueError("Ledger entry amount must be strictly positive.")
            
            entry_type = entry.get("type", "").upper()
            if entry_type == "DEBIT":
                total_debits += amount
            elif entry_type == "CREDIT":
                total_credits += amount
            else:
                raise ValueError(f"Invalid entry type: {entry_type}. Must be DEBIT or CREDIT.")

        if total_debits != total_credits:
            raise ValueError(f"Unbalanced Ledger Transaction! Debits: {total_debits} != Credits: {total_credits}")

        return True

    @staticmethod
    def create_transfer_entries(
        sender_account_id: str,
        settlement_account_id: str,
        amount: Decimal,
        currency: str
    ) -> List[Dict[str, Any]]:
        """
        Creates balanced debit/credit entries for funding/transfer movement:
        Debit: Settlement Account (Asset)
        Credit: Customer Wallet Account (Liability)
        """
        tx_id = str(uuid.uuid4())
        entries = [
            {
                "transaction_id": tx_id,
                "account_id": settlement_account_id,
                "type": "DEBIT",
                "amount": str(amount),
                "currency": currency
            },
            {
                "transaction_id": tx_id,
                "account_id": sender_account_id,
                "type": "CREDIT",
                "amount": str(amount),
                "currency": currency
            }
        ]
        DoubleEntryLedgerEngine.validate_transaction(entries)
        return entries
