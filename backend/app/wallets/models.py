from decimal import Decimal
from typing import Dict, Any, List
import uuid

# In-memory wallet store for local execution
USER_WALLETS: Dict[str, List[Dict[str, Any]]] = {}

class WalletEngine:
    @staticmethod
    def initialize_default_wallets(user_id: str, primary_currency: str = "NGN") -> List[Dict[str, Any]]:
        if user_id not in USER_WALLETS:
            wallets = [
                {
                    "wallet_id": f"wlt_{uuid.uuid4().hex[:10]}",
                    "user_id": user_id,
                    "currency": primary_currency.upper(),
                    "available_balance": "500000.00",
                    "pending_balance": "0.00",
                    "status": "ACTIVE",
                    "created_at": "2026-10-04T11:40:00Z"
                },
                {
                    "wallet_id": f"wlt_{uuid.uuid4().hex[:10]}",
                    "user_id": user_id,
                    "currency": "GBP",
                    "available_balance": "1250.00",
                    "pending_balance": "0.00",
                    "status": "ACTIVE",
                    "created_at": "2026-10-04T11:40:00Z"
                }
            ]
            USER_WALLETS[user_id] = wallets
        return USER_WALLETS[user_id]

    @staticmethod
    def get_user_wallets(user_id: str) -> List[Dict[str, Any]]:
        return WalletEngine.initialize_default_wallets(user_id)

    @staticmethod
    def activate_currency_wallet(user_id: str, currency: str) -> Dict[str, Any]:
        wallets = WalletEngine.get_user_wallets(user_id)
        currency_upper = currency.upper()
        for w in wallets:
            if w["currency"] == currency_upper:
                return w

        new_wallet = {
            "wallet_id": f"wlt_{uuid.uuid4().hex[:10]}",
            "user_id": user_id,
            "currency": currency_upper,
            "available_balance": "1500.00",
            "pending_balance": "0.00",
            "status": "ACTIVE",
            "created_at": "2026-10-04T11:40:00Z"
        }
        wallets.append(new_wallet)
        return new_wallet

    @staticmethod
    def fund_wallet(user_id: str, currency: str, amount: str) -> Dict[str, Any]:
        wallets = WalletEngine.get_user_wallets(user_id)
        currency_upper = currency.upper()
        add_amount = Decimal(amount)
        for w in wallets:
            if w["currency"] == currency_upper:
                current_bal = Decimal(w["available_balance"])
                w["available_balance"] = f"{(current_bal + add_amount):.2f}"
                return w
        # If wallet doesn't exist, activate and fund
        new_w = WalletEngine.activate_currency_wallet(user_id, currency_upper)
        new_w["available_balance"] = f"{add_amount:.2f}"
        return new_w

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

        # Deduct from source
        source_wallet["available_balance"] = f"{(Decimal(source_wallet['available_balance']) - f_amt):.2f}"

        # Add to dest wallet (activate if needed)
        dest_wallet = None
        for w in wallets:
            if w["currency"] == t_curr:
                dest_wallet = w
                break

        if not dest_wallet:
            dest_wallet = WalletEngine.activate_currency_wallet(user_id, t_curr)

        dest_wallet["available_balance"] = f"{(Decimal(dest_wallet['available_balance']) + t_amt):.2f}"

        return {
            "source_wallet": source_wallet,
            "destination_wallet": dest_wallet,
            "from_currency": f_curr,
            "to_currency": t_curr,
            "from_amount": str(f_amt),
            "to_amount": str(t_amt)
        }
