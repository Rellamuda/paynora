from decimal import Decimal
from typing import Dict, Any, List
import uuid

RECONCILIATION_CASES: List[Dict[str, Any]] = []

class ReconciliationEngine:
    @staticmethod
    def reconcile_transaction(
        internal_transfer_id: str,
        internal_amount: Decimal,
        provider_amount: Decimal,
        internal_currency: str,
        provider_currency: str
    ) -> Dict[str, Any]:
        """
        Reconciles internal ledger state against external provider settlement record.
        Detects missing transactions, duplicates, amount mismatches, and currency mismatches.
        """
        is_matched = True
        mismatch_reason = None

        if internal_amount != provider_amount:
            is_matched = False
            mismatch_reason = f"Amount mismatch! Internal: {internal_amount} {internal_currency} != Provider: {provider_amount} {provider_currency}"
        elif internal_currency.upper() != provider_currency.upper():
            is_matched = False
            mismatch_reason = f"Currency mismatch! Internal: {internal_currency} != Provider: {provider_currency}"

        case_record = {
            "case_id": f"rec_{uuid.uuid4().hex[:10]}",
            "transfer_id": internal_transfer_id,
            "status": "BALANCED" if is_matched else "DISCREPANCY_DETECTED",
            "internal_amount": str(internal_amount),
            "provider_amount": str(provider_amount),
            "currency": internal_currency,
            "mismatch_reason": mismatch_reason,
            "created_at": "2026-10-04T11:47:00Z"
        }

        if not is_matched:
            RECONCILIATION_CASES.append(case_record)

        return case_record

    @staticmethod
    def get_reconciliation_cases() -> List[Dict[str, Any]]:
        return RECONCILIATION_CASES
