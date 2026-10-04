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
                    "available_balance": "0.00",
                    "pending_balance": "0.00",
                    "status": "ACTIVE",
                    "created_at": "2026-10-04T11:40:00Z"
                },
                {
                    "wallet_id": f"wlt_{uuid.uuid4().hex[:10]}",
                    "user_id": user_id,
                    "currency": "GBP",
                    "available_balance": "0.00",
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
            "available_balance": "0.00",
            "pending_balance": "0.00",
            "status": "ACTIVE",
            "created_at": "2026-10-04T11:40:00Z"
        }
        wallets.append(new_wallet)
        return new_wallet
