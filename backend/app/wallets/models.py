from decimal import Decimal
from typing import Dict, Any, List
import uuid

# In-memory wallet store for local execution
USER_WALLETS: Dict[str, List[Dict[str, Any]]] = {}

# Default foreign currencies every user holds alongside their local currency
DEFAULT_FOREIGN_CURRENCIES = ["USD", "GBP"]

COUNTRY_LOCAL_CURRENCY = {
    "NG": "NGN", "GH": "GHS", "KE": "KES", "ZA": "ZAR", "GB": "GBP", "US": "USD",
    "CA": "CAD", "AE": "AED", "DE": "EUR", "FR": "EUR", "SA": "SAR", "CN": "CNY",
}

DEMO_SEED_BALANCES = {"NGN": "500000.00", "USD": "1250.00", "GBP": "800.00"}


def resolve_local_currency(user_id: str) -> str:
    """Derive the user's local currency from their registered country (defaults to NGN)."""
    try:
        from app.auth.store import USERS_DB
        user = USERS_DB.get(user_id) or {}
        return COUNTRY_LOCAL_CURRENCY.get((user.get("country_iso") or "NG").upper(), "NGN")
    except Exception:
        return "NGN"


class WalletEngine:
    """
    PayNora Wallet Engine:
    Each user is provisioned:
    1. Their country's Local Currency wallet (e.g., NGN, GHS, KES)
    2. Default foreign currency wallets: USD and GBP
    (If the local currency is itself USD or GBP, it is not duplicated.)
    """

    @staticmethod
    def initialize_default_wallets(user_id: str, primary_currency: str = None) -> List[Dict[str, Any]]:
        local_curr = (primary_currency or resolve_local_currency(user_id)).upper()
        currencies = [local_curr] + [c for c in DEFAULT_FOREIGN_CURRENCIES if c != local_curr]
        allowed = set(currencies)

        if user_id not in USER_WALLETS:
            USER_WALLETS[user_id] = [
                {
                    "wallet_id": f"wlt_{uuid.uuid4().hex[:10]}",
                    "user_id": user_id,
                    "currency": curr,
                    "available_balance": DEMO_SEED_BALANCES.get(curr, "2500.00"),
                    "pending_balance": "0.00",
                    "status": "ACTIVE",
                    "is_local": curr == local_curr,
                    "created_at": "2026-10-04T11:40:00Z"
                }
                for curr in currencies
            ]
        else:
            USER_WALLETS[user_id] = [w for w in USER_WALLETS[user_id] if w["currency"] in allowed]
            existing = {w["currency"] for w in USER_WALLETS[user_id]}
            for curr in currencies:
                if curr not in existing:
                    USER_WALLETS[user_id].append({
                        "wallet_id": f"wlt_{uuid.uuid4().hex[:10]}",
                        "user_id": user_id,
                        "currency": curr,
                        "available_balance": "0.00",
                        "pending_balance": "0.00",
                        "status": "ACTIVE",
                        "created_at": "2026-10-04T11:40:00Z"
                    })
        return USER_WALLETS[user_id]

    @staticmethod
    def get_user_wallets(user_id: str, primary_currency: str = None) -> List[Dict[str, Any]]:
        return WalletEngine.initialize_default_wallets(user_id, primary_currency)

    @staticmethod
    def activate_currency_wallet(user_id: str, currency: str) -> Dict[str, Any]:
        """In the Double Currency architecture, users have their Local Currency and USD wallets."""
        wallets = WalletEngine.get_user_wallets(user_id)
        currency_upper = currency.upper()
        for w in wallets:
            if w["currency"] == currency_upper:
                return w
        # If user requests another currency, return USD wallet as standard global container
        for w in wallets:
            if w["currency"] == "USD":
                return w
        return wallets[0]

    @staticmethod
    def fund_wallet(user_id: str, currency: str, amount: str) -> Dict[str, Any]:
        wallets = WalletEngine.get_user_wallets(user_id)
        currency_upper = currency.upper()
        add_amount = Decimal(amount)

        target_wallet = None
        for w in wallets:
            if w["currency"] == currency_upper:
                target_wallet = w
                break

        # If depositing an un-held currency, credit into USD wallet
        if not target_wallet:
            for w in wallets:
                if w["currency"] == "USD":
                    target_wallet = w
                    break
            if not target_wallet:
                target_wallet = wallets[0]

        current_bal = Decimal(target_wallet["available_balance"])
        target_wallet["available_balance"] = f"{(current_bal + add_amount):.2f}"
        return target_wallet

    @staticmethod
    def convert_wallet_currency(
        user_id: str,
        from_currency: str,
        to_currency: str,
        from_amount: str,
        to_amount: str
    ) -> Dict[str, Any]:
        wallets = WalletEngine.get_user_wallets(user_id)
        f_curr = from_currency.upper()
        t_curr = to_currency.upper()
        f_amt = Decimal(from_amount)
        t_amt = Decimal(to_amount)

        source_wallet = None
        for w in wallets:
            if w["currency"] == f_curr:
                source_wallet = w
                break

        if not source_wallet or Decimal(source_wallet["available_balance"]) < f_amt:
            raise ValueError(f"Insufficient {f_curr} balance")

        dest_wallet = None
        for w in wallets:
            if w["currency"] == t_curr:
                dest_wallet = w
                break

        if not dest_wallet:
            raise ValueError(f"Destination wallet {t_curr} not available in double-currency configuration")

        # Deduct from source and add to destination
        source_wallet["available_balance"] = f"{(Decimal(source_wallet['available_balance']) - f_amt):.2f}"
        dest_wallet["available_balance"] = f"{(Decimal(dest_wallet['available_balance']) + t_amt):.2f}"

        return {
            "source_wallet": source_wallet,
            "destination_wallet": dest_wallet,
            "from_currency": f_curr,
            "to_currency": t_curr,
            "from_amount": str(f_amt),
            "to_amount": str(t_amt)
        }
