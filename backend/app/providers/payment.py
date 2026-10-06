from typing import Dict, Any, Optional, List
from decimal import Decimal, InvalidOperation
import uuid
import httpx
from app.config import settings

# ---------------------------------------------------------------------------
# Smart Gateway Routing Table
# ---------------------------------------------------------------------------
# For every currency:
#   recommended -> gateway with best coverage / success rate / cost for it
#   supported   -> gateways that can actually process the currency
#   min / max   -> per-transaction limits (major units). Max values are set
#                  conservatively below the gateway's account-level single
#                  charge caps (e.g. Flutterwave rejected GBP > 3,719).
#   reason      -> short human-readable explanation shown in the UI
GATEWAY_ROUTING: Dict[str, Dict[str, Any]] = {
    # --- Paystack home markets (native local rails, highest success rates) ---
    "NGN": {"recommended": "PAYSTACK", "supported": ["PAYSTACK", "FLUTTERWAVE"], "min": 100, "max": 5_000_000,
            "reason": "Best Nigerian card, bank transfer & USSD success rates"},
    "GHS": {"recommended": "PAYSTACK", "supported": ["PAYSTACK", "FLUTTERWAVE"], "min": 1, "max": 50_000,
            "reason": "Native Ghana card & mobile money rails"},
    "ZAR": {"recommended": "PAYSTACK", "supported": ["PAYSTACK", "FLUTTERWAVE"], "min": 10, "max": 60_000,
            "reason": "Native South African card & EFT rails"},
    "KES": {"recommended": "PAYSTACK", "supported": ["PAYSTACK", "FLUTTERWAVE"], "min": 10, "max": 450_000,
            "reason": "Native Kenya card & M-Pesa rails"},
    # --- Global currencies (Flutterwave international card acquiring) ---
    "USD": {"recommended": "FLUTTERWAVE", "supported": ["FLUTTERWAVE"], "min": 1, "max": 4_500,
            "reason": "Global multi-currency card acquiring"},
    "GBP": {"recommended": "FLUTTERWAVE", "supported": ["FLUTTERWAVE"], "min": 1, "max": 3_500,
            "reason": "Global multi-currency card acquiring"},
    "EUR": {"recommended": "FLUTTERWAVE", "supported": ["FLUTTERWAVE"], "min": 1, "max": 4_000,
            "reason": "Global multi-currency card acquiring"},
    "CAD": {"recommended": "FLUTTERWAVE", "supported": ["FLUTTERWAVE"], "min": 1, "max": 6_000,
            "reason": "Global multi-currency card acquiring"},
    # --- Wider Africa (Flutterwave mobile money coverage) ---
    "UGX": {"recommended": "FLUTTERWAVE", "supported": ["FLUTTERWAVE"], "min": 500, "max": 15_000_000,
            "reason": "Uganda mobile money coverage"},
    "TZS": {"recommended": "FLUTTERWAVE", "supported": ["FLUTTERWAVE"], "min": 500, "max": 10_000_000,
            "reason": "Tanzania mobile money coverage"},
    "RWF": {"recommended": "FLUTTERWAVE", "supported": ["FLUTTERWAVE"], "min": 100, "max": 5_000_000,
            "reason": "Rwanda mobile money coverage"},
    "XAF": {"recommended": "FLUTTERWAVE", "supported": ["FLUTTERWAVE"], "min": 100, "max": 2_500_000,
            "reason": "Francophone Central Africa mobile money"},
    "XOF": {"recommended": "FLUTTERWAVE", "supported": ["FLUTTERWAVE"], "min": 100, "max": 2_500_000,
            "reason": "Francophone West Africa mobile money"},
    "ZMW": {"recommended": "FLUTTERWAVE", "supported": ["FLUTTERWAVE"], "min": 5, "max": 100_000,
            "reason": "Zambia mobile money coverage"},
    "EGP": {"recommended": "FLUTTERWAVE", "supported": ["FLUTTERWAVE"], "min": 10, "max": 200_000,
            "reason": "Egypt card acquiring"},
}

DEFAULT_ROUTE: Dict[str, Any] = {
    "recommended": "FLUTTERWAVE", "supported": ["FLUTTERWAVE"], "min": 1, "max": 4_500,
    "reason": "Global multi-currency coverage",
}


class GatewayRoutingError(ValueError):
    """Raised when a currency / amount / gateway combination cannot be processed."""


class PaymentGatewayRouter:
    """
    Industry-Standard Smart Dual Gateway Engine:
    - Paystack: Primary for fast Nigerian Naira (NGN), Ghana Cedi (GHS), South African Rand (ZAR), and Kenya Shilling (KES) card/bank rails.
    - Flutterwave: Primary for Global Multi-Currency (USD, GBP, EUR, CAD, etc.), Francophone/East African Mobile Money, and global card collections.
    """

    PAYSTACK_BASE_URL = "https://api.paystack.co"
    FLUTTERWAVE_BASE_URL = "https://api.flutterwave.com/v3"

    @classmethod
    def get_route(cls, currency: str) -> Dict[str, Any]:
        curr = (currency or "").upper()
        route = GATEWAY_ROUTING.get(curr, DEFAULT_ROUTE)
        return {"currency": curr, **route}

    @classmethod
    def routing_table(cls) -> List[Dict[str, Any]]:
        return [{"currency": c, **r} for c, r in GATEWAY_ROUTING.items()]

    @classmethod
    def select_gateway(cls, currency: str, requested_gateway: Optional[str] = None) -> str:
        """
        Determines the optimal gateway based on currency and coverage.
        A requested gateway is honoured only if it supports the currency;
        otherwise the recommended gateway is used.
        """
        route = cls.get_route(currency)
        if requested_gateway:
            req = requested_gateway.upper()
            if req in route["supported"]:
                return req
        return route["recommended"]

    @classmethod
    def validate_amount(cls, currency: str, amount: str) -> Decimal:
        route = cls.get_route(currency)
        try:
            value = Decimal(str(amount).replace(",", "").strip())
        except (InvalidOperation, AttributeError):
            raise GatewayRoutingError("Please enter a valid amount.")
        if value <= 0:
            raise GatewayRoutingError("Amount must be greater than zero.")
        if value < Decimal(str(route["min"])):
            raise GatewayRoutingError(f"Minimum deposit is {route['min']:,} {route['currency']}.")
        if value > Decimal(str(route["max"])):
            raise GatewayRoutingError(
                f"Maximum single deposit is {route['max']:,} {route['currency']}. "
                f"Please split larger amounts into multiple deposits."
            )
        return value

    @classmethod
    async def initialize_deposit(
        cls,
        email: str,
        amount: str,
        currency: str,
        user_id: str,
        gateway: Optional[str] = None,
        callback_url: Optional[str] = None
    ) -> Dict[str, Any]:
        route = cls.get_route(currency)
        try:
            validated = cls.validate_amount(currency, amount)
        except GatewayRoutingError as e:
            return {"status": "ERROR", "gateway": cls.select_gateway(currency, gateway),
                    "code": "AMOUNT_OUT_OF_RANGE", "message": str(e), "route": route}

        primary = cls.select_gateway(currency, gateway)
        result = await cls._initialize_with_gateway(primary, email, validated, currency, user_id, callback_url)
        result["route"] = route
        result["recommended_gateway"] = route["recommended"]
        if result.get("status") == "SUCCESS":
            return result

        # Automatic failover to the other gateway if it supports this currency
        fallbacks = [g for g in route["supported"] if g != primary]
        for alt in fallbacks:
            alt_result = await cls._initialize_with_gateway(alt, email, validated, currency, user_id, callback_url)
            if alt_result.get("status") == "SUCCESS":
                alt_result["route"] = route
                alt_result["recommended_gateway"] = route["recommended"]
                alt_result["failover_from"] = primary
                alt_result["failover_reason"] = result.get("message")
                return alt_result
        return result

    @classmethod
    async def _initialize_with_gateway(
        cls,
        chosen_gateway: str,
        email: str,
        validated: Decimal,
        currency: str,
        user_id: str,
        callback_url: Optional[str] = None
    ) -> Dict[str, Any]:
        tx_ref = f"paynora_{uuid.uuid4().hex[:12]}"
        numeric_amount = float(validated)
        amount = format(validated, "f")

        if chosen_gateway == "PAYSTACK":
            # Paystack expects amount in minor units (kobo/cents: multiply by 100)
            paystack_amount = int((validated * 100).quantize(Decimal("1")))
            headers = {
                "Authorization": f"Bearer {settings.PAYSTACK_SECRET_KEY}",
                "Content-Type": "application/json"
            }
            body = {
                "email": email,
                "amount": paystack_amount,
                "currency": currency.upper(),
                "reference": tx_ref,
                "callback_url": callback_url or "http://13.48.25.254/payment-callback",
                "metadata": {
                    "user_id": user_id,
                    "platform": "PayNora Smart Rails"
                }
            }
            try:
                async with httpx.AsyncClient(timeout=15.0) as client:
                    resp = await client.post(f"{cls.PAYSTACK_BASE_URL}/transaction/initialize", json=body, headers=headers)
                    data = resp.json()
                    if resp.status_code == 200 and data.get("status"):
                        return {
                            "status": "SUCCESS",
                            "gateway": "PAYSTACK",
                            "reference": tx_ref,
                            "checkout_url": data["data"]["authorization_url"],
                            "access_code": data["data"]["access_code"],
                            "public_key": settings.PAYSTACK_PUBLIC_KEY,
                            "amount": amount,
                            "currency": currency.upper()
                        }
                    else:
                        return {
                            "status": "ERROR",
                            "gateway": "PAYSTACK",
                            "message": data.get("message", "Paystack initialization failed"),
                            "raw": data
                        }
            except Exception as e:
                return {
                    "status": "ERROR",
                    "gateway": "PAYSTACK",
                    "message": f"Network error contacting Paystack: {str(e)}"
                }

        else: # FLUTTERWAVE
            headers = {
                "Authorization": f"Bearer {settings.FLW_SECRET_KEY}",
                "Content-Type": "application/json"
            }
            body = {
                "tx_ref": tx_ref,
                "amount": str(numeric_amount),
                "currency": currency.upper(),
                "redirect_url": callback_url or "http://13.48.25.254/payment-callback",
                "customer": {
                    "email": email,
                    "name": email.split("@")[0]
                },
                "customizations": {
                    "title": "PayNora Wallet Deposit",
                    "description": f"Funding {currency.upper()} Wallet Balance"
                },
                "meta": {
                    "user_id": user_id,
                    "service": "PayNora Global Engine"
                }
            }
            try:
                async with httpx.AsyncClient(timeout=15.0) as client:
                    resp = await client.post(f"{cls.FLUTTERWAVE_BASE_URL}/payments", json=body, headers=headers)
                    data = resp.json()
                    if resp.status_code == 200 and data.get("status") == "success":
                        return {
                            "status": "SUCCESS",
                            "gateway": "FLUTTERWAVE",
                            "reference": tx_ref,
                            "checkout_url": data["data"]["link"],
                            "public_key": settings.FLW_PUBLIC_KEY,
                            "amount": amount,
                            "currency": currency.upper()
                        }
                    else:
                        return {
                            "status": "ERROR",
                            "gateway": "FLUTTERWAVE",
                            "message": data.get("message", "Flutterwave initialization failed"),
                            "raw": data
                        }
            except Exception as e:
                return {
                    "status": "ERROR",
                    "gateway": "FLUTTERWAVE",
                    "message": f"Network error contacting Flutterwave: {str(e)}"
                }

    @classmethod
    async def verify_transaction(cls, reference: str, gateway: str) -> Dict[str, Any]:
        """
        Verify transaction state with the respective processor.
        """
        if gateway.upper() == "PAYSTACK":
            headers = {"Authorization": f"Bearer {settings.PAYSTACK_SECRET_KEY}"}
            async with httpx.AsyncClient(timeout=15.0) as client:
                resp = await client.get(f"{cls.PAYSTACK_BASE_URL}/transaction/verify/{reference}", headers=headers)
                data = resp.json()
                if resp.status_code == 200 and data.get("status") and data["data"]["status"] == "success":
                    return {
                        "verified": True,
                        "gateway": "PAYSTACK",
                        "reference": reference,
                        "amount": str(data["data"]["amount"] / 100),
                        "currency": data["data"]["currency"],
                        "paid_at": data["data"].get("paid_at")
                    }
                return {"verified": False, "gateway": "PAYSTACK", "raw": data}
        else: # FLUTTERWAVE
            headers = {"Authorization": f"Bearer {settings.FLW_SECRET_KEY}"}
            # For flutterwave reference verification
            async with httpx.AsyncClient(timeout=15.0) as client:
                resp = await client.get(f"{cls.FLUTTERWAVE_BASE_URL}/transactions/verify_by_reference?tx_ref={reference}", headers=headers)
                data = resp.json()
                if resp.status_code == 200 and data.get("status") == "success" and data["data"]["status"] == "successful":
                    return {
                        "verified": True,
                        "gateway": "FLUTTERWAVE",
                        "reference": reference,
                        "amount": str(data["data"]["amount"]),
                        "currency": data["data"]["currency"],
                        "paid_at": data["data"].get("created_at")
                    }
                return {"verified": False, "gateway": "FLUTTERWAVE", "raw": data}

class MockPaymentProvider:
    """
    Vendor-agnostic mock payment provider interface (maintained for unit tests).
    """
    @staticmethod
    def create_payment_charge(amount: str, currency: str, reference: str) -> Dict[str, Any]:
        provider_tx_id = f"pay_tx_{uuid.uuid4().hex[:10]}"
        return {
            "provider_tx_id": provider_tx_id,
            "status": "SUCCESS",
            "amount": amount,
            "currency": currency,
            "reference": reference,
            "provider_name": "SmartDualGatewayEngine"
        }

    @staticmethod
    def process_payout(amount: str, currency: str, recipient_details: Dict[str, Any]) -> Dict[str, Any]:
        payout_id = f"pyo_{uuid.uuid4().hex[:10]}"
        return {
            "payout_id": payout_id,
            "status": "COMPLETED",
            "amount": amount,
            "currency": currency,
            "recipient_name": recipient_details.get("name", "Recipient")
        }
