import re
from typing import Dict, Any
from app.fx.engine import FXEngine
from app.wallets.models import WalletEngine

class AIFinancialAssistantEngine:
    """
    AI Financial Assistant Engine.
    Strict Hierarchy: AI proposes intent -> Backend validates -> Explicit User Confirmation Required.
    AI NEVER directly mutates ledger balances or database state.
    """
    @staticmethod
    def process_prompt(user_id: str, prompt: str) -> Dict[str, Any]:
        prompt_clean = prompt.strip()
        
        # 1. Balance Inquiries
        if "balance" in prompt_clean.lower() or "how much" in prompt_clean.lower():
            wallets = WalletEngine.get_user_wallets(user_id)
            return {
                "intent": "INQUIRE_BALANCE",
                "message": "Here are your active multi-currency balances:",
                "data": {"wallets": wallets},
                "requires_confirmation": False
            }

        # 2. Transfer Intent ("Send ₦1,000,000 to John in London" or "Send 500000 NGN to John")
        send_match = re.search(r"send\s+(?:₦|NGN\s*)?([\d,]+)\s*(?:NGN)?\s+to\s+([A-Za-z\s]+)", prompt_clean, re.IGNORECASE)
        if send_match:
            raw_amount = send_match.group(1).replace(",", "")
            recipient_name = send_match.group(2).strip()

            # Execute typed tool: Obtain FX Quote for requested transfer
            fx_quote = FXEngine.generate_quote("NGN", "GBP", raw_amount)

            return {
                "intent": "PROPOSE_TRANSFER",
                "message": f"I've prepared a transfer proposal of ₦{raw_amount} for {recipient_name} in London (UK).",
                "proposed_action": {
                    "action": "CREATE_TRANSFER",
                    "source_currency": "NGN",
                    "source_amount": raw_amount,
                    "recipient_name": recipient_name,
                    "destination_country": "GB",
                    "recipient_currency_mode": "CHOICE",
                    "fx_quote": fx_quote
                },
                "requires_confirmation": True
            }

        # 3. Default fallback assistance
        return {
            "intent": "GENERAL_ASSISTANCE",
            "message": f"I can help you send money globally, check wallet balances, or obtain FX rates. (Received: '{prompt}')",
            "requires_confirmation": False
        }
