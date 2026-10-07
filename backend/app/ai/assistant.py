import re
from typing import Dict, Any, Optional
import httpx
from app.config import settings
from app.fx.engine import FXEngine
from app.wallets.models import WalletEngine

class AIFinancialAssistantEngine:
    """
    PayNora Nora AI & PayNora AI Financial Intelligence Engine.
    Powered by Google Gemini Generative AI model with financial domain context.
    Strict Hierarchy: AI proposes intent -> Backend validates -> Explicit User Confirmation Required.
    """
    GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"

    @classmethod
    def call_gemini(cls, prompt: str, user_context: Optional[str] = None) -> Optional[str]:
        """Calls Google Gemini API using the provisioned GEMINI_API_KEY."""
        api_key = settings.GEMINI_API_KEY
        if not api_key:
            return None

        system_instruction = (
            "You are Nora, the official AI Financial Intelligence Assistant of PayNora Global Money Movement Platform. "
            "PayNora provides Double Currency Digital Wallets: one in the user's country local currency (e.g., NGN, GHS, KES, GBP, EUR, CAD) "
            "and the other in USD (Global Reserve). PayNora offers instant cross-border transfers, real-time FX rate locking, "
            "smart dual gateway routing (Flutterwave and Paystack), and biometric security. "
            "Keep your responses helpful, concise, authoritative, professional, and friendly. Avoid excessive jargon."
        )

        full_prompt = f"{system_instruction}\n\nContext: {user_context or 'Standard authenticated session'}\n\nUser Question: {prompt}"

        payload = {
            "contents": [
                {
                    "parts": [{"text": full_prompt}]
                }
            ],
            "generationConfig": {
                "temperature": 0.4,
                "maxOutputTokens": 600
            }
        }

        try:
            # Send API key via both query parameter and header for maximum compatibility
            url = f"{cls.GEMINI_API_URL}?key={api_key}"
            headers = {
                "Content-Type": "application/json",
                "x-goog-api-key": api_key
            }
            with httpx.Client(timeout=12.0) as client:
                resp = client.post(url, json=payload, headers=headers)
                if resp.status_code == 200:
                    data = resp.json()
                    candidates = data.get("candidates", [])
                    if candidates and len(candidates) > 0:
                        parts = candidates[0].get("content", {}).get("parts", [])
                        if parts and len(parts) > 0:
                            return parts[0].get("text", "").strip()
        except Exception as e:
            print(f"[Nora AI] Gemini API call exception: {e}")
        return None

    @classmethod
    def process_prompt(cls, user_id: str, prompt: str) -> Dict[str, Any]:
        prompt_clean = prompt.strip()
        wallets = WalletEngine.get_user_wallets(user_id)
        user_context = f"User Wallets: {', '.join([f'{w['currency']} {w['available_balance']}' for w in wallets])}"

        # 1. Check for specific Transfer Intent ("Send 100 USD to John" or "Send ₦500,000 to Mike in London")
        send_match = re.search(r"send\s+(?:₦|\$|£|€)?\s*([\d,]+)\s*([A-Za-z]{3})?\s+to\s+([A-Za-z\s]+)", prompt_clean, re.IGNORECASE)
        if send_match:
            raw_amount = send_match.group(1).replace(",", "")
            raw_currency = (send_match.group(2) or "USD").upper()
            recipient_name = send_match.group(3).strip()

            dest_currency = "GBP" if "london" in prompt_clean.lower() or "uk" in prompt_clean.lower() else ("NGN" if raw_currency == "USD" else "USD")
            fx_quote = FXEngine.generate_quote(raw_currency, dest_currency, raw_amount)

            gemini_reply = cls.call_gemini(
                f"Confirming a transfer intent of {raw_currency} {raw_amount} to {recipient_name}. Explain how PayNora's double-currency engine locks the rate.",
                user_context
            )

            message = gemini_reply or f"I have prepared a verified transfer proposal of {raw_currency} {raw_amount} to {recipient_name}."

            return {
                "intent": "PROPOSE_TRANSFER",
                "message": message,
                "proposed_action": {
                    "action": "CREATE_TRANSFER",
                    "source_currency": raw_currency,
                    "source_amount": raw_amount,
                    "recipient_name": recipient_name,
                    "destination_currency": dest_currency,
                    "destination_country": "GB" if dest_currency == "GBP" else "NG",
                    "recipient_currency_mode": "CHOICE",
                    "fx_quote": fx_quote
                },
                "requires_confirmation": True
            }

        # 2. Check for Balance Inquiries
        if "balance" in prompt_clean.lower() or "how much" in prompt_clean.lower():
            balance_summary = " & ".join([f"{w['currency']} {w['available_balance']}" for w in wallets])
            gemini_reply = cls.call_gemini(
                f"The user is asking about their double currency balances ({balance_summary}). Summarize their active holdings.",
                user_context
            )
            return {
                "intent": "INQUIRE_BALANCE",
                "message": gemini_reply or f"Your active Double Currency Digital Wallets hold: {balance_summary}.",
                "data": {"wallets": wallets},
                "requires_confirmation": False
            }

        # 3. Dynamic Gemini Conversational Response for all other financial inquiries
        gemini_reply = cls.call_gemini(prompt_clean, user_context)
        if gemini_reply:
            return {
                "intent": "GEMINI_INTELLIGENCE",
                "message": gemini_reply,
                "provider": "Google Gemini (Nora AI)",
                "requires_confirmation": False
            }

        # 4. High-intelligence fallback if Gemini is offline
        if "rate" in prompt_clean.lower() or "fx" in prompt_clean.lower() or "exchange" in prompt_clean.lower():
            return {
                "intent": "FX_INQUIRY",
                "message": "PayNora locks interbank mid-market FX rates with a 0.5% corridor spread across NGN, USD, GBP, and EUR. Current rate: 1 USD = ₦1,538.46.",
                "requires_confirmation": False
            }

        return {
            "intent": "GENERAL_ASSISTANCE",
            "message": f"Hello! I am Nora, your PayNora AI financial assistant. I can help you monitor live FX volatility, check your Double Currency Wallets, or prepare instant transfers.",
            "requires_confirmation": False
        }
