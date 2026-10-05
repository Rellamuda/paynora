from typing import List, Dict, Any, Optional
from enum import Enum

class CorridorLifecycle(str, Enum):
    NOT_CONFIGURED = "NOT_CONFIGURED"
    CONFIGURED = "CONFIGURED"
    PROVIDER_SETUP = "PROVIDER_SETUP"
    TESTING = "TESTING"
    COMPLIANCE_REVIEW = "COMPLIANCE_REVIEW"
    READY_FOR_APPROVAL = "READY_FOR_APPROVAL"
    APPROVED = "APPROVED"
    ACTIVE = "ACTIVE"
    SUSPENDED = "SUSPENDED"
    DEACTIVATED = "DEACTIVATED"

INITIAL_CORRIDORS: List[Dict[str, Any]] = [
    {
        "corridor_id": "crd_ng_gb",
        "source_country": "NG",
        "destination_country": "GB",
        "source_currency": "NGN",
        "destination_currencies": ["GBP", "NGN"],
        "status": CorridorLifecycle.ACTIVE,
        "payment_methods": ["BANK_TRANSFER", "DEBIT_CARD"],
        "payout_methods": ["UK_FASTER_PAYMENTS", "DIRECT_DEPOSIT"],
        "min_amount": "1000.00",
        "max_amount": "10000000.00",
        "base_fee": "500.00",
        "spread_percentage": "0.50",
        "estimated_settlement": "INSTANT"
    },
    {
        "corridor_id": "crd_gb_ng",
        "source_country": "GB",
        "destination_country": "NG",
        "source_currency": "GBP",
        "destination_currencies": ["NGN", "GBP"],
        "status": CorridorLifecycle.ACTIVE,
        "payment_methods": ["OPEN_BANKING", "DEBIT_CARD"],
        "payout_methods": ["NIBSS_INSTANT_PAYMENT"],
        "min_amount": "5.00",
        "max_amount": "25000.00",
        "base_fee": "2.50",
        "spread_percentage": "0.50",
        "estimated_settlement": "INSTANT"
    },
    {
        "corridor_id": "crd_us_ng",
        "source_country": "US",
        "destination_country": "NG",
        "source_currency": "USD",
        "destination_currencies": ["NGN", "USD"],
        "status": CorridorLifecycle.ACTIVE,
        "payment_methods": ["ACH", "CARD"],
        "payout_methods": ["NIBSS_INSTANT_PAYMENT"],
        "min_amount": "10.00",
        "max_amount": "50000.00",
        "base_fee": "3.00",
        "spread_percentage": "0.50",
        "estimated_settlement": "SAME_DAY"
    },
    {
        "corridor_id": "crd_ca_ng",
        "source_country": "CA",
        "destination_country": "NG",
        "source_currency": "CAD",
        "destination_currencies": ["NGN", "CAD"],
        "status": CorridorLifecycle.ACTIVE,
        "payment_methods": ["INTERAC", "CARD"],
        "payout_methods": ["NIBSS_INSTANT_PAYMENT"],
        "min_amount": "10.00",
        "max_amount": "25000.00",
        "base_fee": "3.50",
        "spread_percentage": "0.50",
        "estimated_settlement": "SAME_DAY"
    },
    {
        "corridor_id": "crd_ae_ng",
        "source_country": "AE",
        "destination_country": "NG",
        "source_currency": "AED",
        "destination_currencies": ["NGN", "AED"],
        "status": CorridorLifecycle.ACTIVE,
        "payment_methods": ["UAEPGS", "CARD"],
        "payout_methods": ["NIBSS_INSTANT_PAYMENT"],
        "min_amount": "50.00",
        "max_amount": "100000.00",
        "base_fee": "10.00",
        "spread_percentage": "0.50",
        "estimated_settlement": "INSTANT"
    },
    {
        "corridor_id": "crd_gh_ng",
        "source_country": "GH",
        "destination_country": "NG",
        "source_currency": "GHS",
        "destination_currencies": ["NGN"],
        "status": CorridorLifecycle.ACTIVE,
        "payment_methods": ["MTN_MOMO", "VODACASH", "BANK"],
        "payout_methods": ["NIBSS_INSTANT_PAYMENT"],
        "min_amount": "20.00",
        "max_amount": "50000.00",
        "base_fee": "5.00",
        "spread_percentage": "0.60",
        "estimated_settlement": "INSTANT"
    },
    {
        "corridor_id": "crd_za_ng",
        "source_country": "ZA",
        "destination_country": "NG",
        "source_currency": "ZAR",
        "destination_currencies": ["NGN"],
        "status": CorridorLifecycle.ACTIVE,
        "payment_methods": ["EFT", "CARD"],
        "payout_methods": ["NIBSS_INSTANT_PAYMENT"],
        "min_amount": "100.00",
        "max_amount": "250000.00",
        "base_fee": "25.00",
        "spread_percentage": "0.60",
        "estimated_settlement": "INSTANT"
    },
    {
        "corridor_id": "crd_de_ng",
        "source_country": "DE",
        "destination_country": "NG",
        "source_currency": "EUR",
        "destination_currencies": ["NGN", "EUR"],
        "status": CorridorLifecycle.ACTIVE,
        "payment_methods": ["SEPA_INSTANT", "SOFORT"],
        "payout_methods": ["NIBSS_INSTANT_PAYMENT"],
        "min_amount": "10.00",
        "max_amount": "30000.00",
        "base_fee": "2.50",
        "spread_percentage": "0.50",
        "estimated_settlement": "INSTANT"
    },
    {
        "corridor_id": "crd_fr_ng",
        "source_country": "FR",
        "destination_country": "NG",
        "source_currency": "EUR",
        "destination_currencies": ["NGN", "EUR"],
        "status": CorridorLifecycle.ACTIVE,
        "payment_methods": ["SEPA_INSTANT", "CARTE_BANCAIRE"],
        "payout_methods": ["NIBSS_INSTANT_PAYMENT"],
        "min_amount": "10.00",
        "max_amount": "30000.00",
        "base_fee": "2.50",
        "spread_percentage": "0.50",
        "estimated_settlement": "INSTANT"
    },
    {
        "corridor_id": "crd_sa_ng",
        "source_country": "SA",
        "destination_country": "NG",
        "source_currency": "SAR",
        "destination_currencies": ["NGN"],
        "status": CorridorLifecycle.ACTIVE,
        "payment_methods": ["MADA", "SARIE"],
        "payout_methods": ["NIBSS_INSTANT_PAYMENT"],
        "min_amount": "50.00",
        "max_amount": "100000.00",
        "base_fee": "12.00",
        "spread_percentage": "0.55",
        "estimated_settlement": "INSTANT"
    },
    {
        "corridor_id": "crd_cn_ng",
        "source_country": "CN",
        "destination_country": "NG",
        "source_currency": "CNY",
        "destination_currencies": ["NGN"],
        "status": CorridorLifecycle.ACTIVE,
        "payment_methods": ["ALIPAY", "WECHAT_PAY", "UNIONPAY"],
        "payout_methods": ["NIBSS_INSTANT_PAYMENT"],
        "min_amount": "100.00",
        "max_amount": "200000.00",
        "base_fee": "20.00",
        "spread_percentage": "0.55",
        "estimated_settlement": "SAME_DAY"
    }
]

class CorridorEngine:
    @staticmethod
    def get_all_corridors() -> List[Dict[str, Any]]:
        return INITIAL_CORRIDORS

    @staticmethod
    def get_corridor(source_country: str, dest_country: str) -> Optional[Dict[str, Any]]:
        src = source_country.upper()
        dst = dest_country.upper()
        for crd in INITIAL_CORRIDORS:
            if crd["source_country"] == src and crd["destination_country"] == dst:
                return crd
        return None

    @staticmethod
    def update_corridor_status(corridor_id: str, new_status: CorridorLifecycle) -> Optional[Dict[str, Any]]:
        for crd in INITIAL_CORRIDORS:
            if crd["corridor_id"] == corridor_id:
                crd["status"] = new_status
                return crd
        return None
