from decimal import Decimal
from datetime import datetime, timedelta
from typing import Dict, Any, Optional
import uuid

FX_QUOTES: Dict[str, Dict[str, Any]] = {}

# Initial FX Rates relative to USD base
MOCK_RATES = {
    ("NGN", "GBP"): Decimal("0.00052"),
    ("GBP", "NGN"): Decimal("1923.07"),
    ("USD", "NGN"): Decimal("1500.00"),
    ("NGN", "USD"): Decimal("0.000666"),
    ("GBP", "USD"): Decimal("1.28"),
    ("USD", "GBP"): Decimal("0.78125")
}

class FXEngine:
    @staticmethod
    def generate_quote(
        source_currency: str,
        destination_currency: str,
        source_amount: str
    ) -> Dict[str, Any]:
        src = source_currency.upper()
        dst = destination_currency.upper()
        amount = Decimal(source_amount)

        rate_key = (src, dst)
        if rate_key not in MOCK_RATES:
            # Fallback default cross-rate multiplier
            rate = Decimal("1.0000")
        else:
            rate = MOCK_RATES[rate_key]

        # Calculate fixed 0.5% FX spread fee
        fee = (amount * Decimal("0.005")).quantize(Decimal("0.01"))
        net_amount = amount - fee
        destination_amount = (net_amount * rate).quantize(Decimal("0.01"))

        quote_id = f"fxq_{uuid.uuid4().hex[:12]}"
        expires_at = (datetime.utcnow() + timedelta(minutes=10)).isoformat() + "Z"

        quote = {
            "quote_id": quote_id,
            "source_currency": src,
            "destination_currency": dst,
            "source_amount": str(amount),
            "fee": str(fee),
            "exchange_rate": str(rate),
            "destination_amount": str(destination_amount),
            "expires_at": expires_at,
            "is_locked": True
        }
        FX_QUOTES[quote_id] = quote
        return quote

    @staticmethod
    def get_quote(quote_id: str) -> Optional[Dict[str, Any]]:
        return FX_QUOTES.get(quote_id)
