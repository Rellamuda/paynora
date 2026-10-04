import pytest
from decimal import Decimal
from app.ledger.engine import DoubleEntryLedgerEngine

def test_balanced_ledger_entries():
    sender_id = "acc_cust_123"
    settlement_id = "acc_settle_456"
    amount = Decimal("100000.00")
    currency = "NGN"

    entries = DoubleEntryLedgerEngine.create_transfer_entries(
        sender_account_id=sender_id,
        settlement_account_id=settlement_id,
        amount=amount,
        currency=currency
    )

    assert len(entries) == 2
    assert entries[0]["type"] == "DEBIT"
    assert entries[1]["type"] == "CREDIT"
    assert entries[0]["amount"] == "100000.00"

def test_unbalanced_ledger_rejection():
    unbalanced_entries = [
        {"account_id": "a1", "type": "DEBIT", "amount": "100.00"},
        {"account_id": "a2", "type": "CREDIT", "amount": "99.00"}
    ]
    with pytest.raises(ValueError, match="Unbalanced Ledger Transaction"):
        DoubleEntryLedgerEngine.validate_transaction(unbalanced_entries)
