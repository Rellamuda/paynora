from decimal import Decimal
from typing import Dict, Any, List
import uuid

# In-memory wallet store for local execution
USER_WALLETS: Dict[str, List[Dict[str, Any]]] = {}

class WalletEngine:
    """
    PayNora Double Currency Wallet Engine:
    Each user in each country is provisioned strictly TWO wallets:
    1. Country's Local Currency (e.g., NGN, GHS, KES, GBP, EUR, CAD, etc.)
    2. USD (Global Reserve Currency)
    """

    @staticmethod
    def initialize_default_wallets(user_id: str, primary_currency: str = "NGN") -> List[Dict[str, Any]]:
        local_curr = (primary_currency or "NGN").upper()
        second_curr = "EUR" if local_curr == "USD" else "USD"
        allowed = {local_curr, second_curr}

        if user_id not in USER_WALLETS:
            wallets = [
                {
                    "wallet_id": f"wlt_{uuid.uuid4().hex[:10]}",
                    "user_id": user_id,
                    "currency": local_curr,
                    "available_balance": "500000.00" if local_curr == "NGN" else "2500.00",
                    "pending_balance": "0.00",
                    "status": "ACTIVE",
                    "created_at": "2026-10-04T11:40:00Z"
                },
                {
                    "wallet_id": f"wlt_{uuid.uuid4().hex[:10]}",
                    "user_id": user_id,
                    "currency": second_curr,
                    "available_balance": "1250.00",
                    "pending_balance": "0.00",
                    "status": "ACTIVE",
                    "created_at": "2026-10-04T11:40:00Z"
                }
            ]
            USER_WALLETS[user_id] = wallets
        else:
            # Enforce strictly the Double Currency model: prune all other currency wallets
            USER_WALLETS[user_id] = [w for w in USER_WALLETS[user_id] if w["currency"] in allowed]
            existing = {w["currency"] for w in USER_WALLETS[user_id]}
            for curr in (local_curr, second_curr):
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
    def get_user_wallets(user_id: str, primary_currency: str = "NGN") -> List[Dict[str, Any]]:
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
