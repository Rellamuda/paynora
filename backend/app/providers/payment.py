from typing import Dict, Any, Optional
import uuid
import httpx
from app.config import settings

class PaymentGatewayRouter:
    """
    Industry-Standard Smart Dual Gateway Engine:
    - Paystack: Primary for fast Nigerian Naira (NGN), Ghana Cedi (GHS), South African Rand (ZAR), and Kenya Shilling (KES) card/bank rails.
    - Flutterwave: Primary for Global Multi-Currency (USD, GBP, EUR, CAD, etc.), Francophone/East African Mobile Money, and global card collections.
    """

    PAYSTACK_BASE_URL = "https://api.paystack.co"
    FLUTTERWAVE_BASE_URL = "https://api.flutterwave.com/v3"

    @classmethod
    def select_gateway(cls, currency: str, requested_gateway: Optional[str] = None) -> str:
        """
        Determines the optimal gateway based on currency and coverage.
        """
        if requested_gateway and requested_gateway.upper() in ["PAYSTACK", "FLUTTERWAVE"]:
            return requested_gateway.upper()

        curr = currency.upper()
        # NGN local transactions have highest success rates with Paystack
        if curr == "NGN":
            return "PAYSTACK"
        # International currencies (USD, GBP, EUR, CAD) and broad Africa routed to Flutterwave
        return "FLUTTERWAVE"

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
        chosen_gateway = cls.select_gateway(currency, gateway)
        tx_ref = f"paynora_{uuid.uuid4().hex[:12]}"
        numeric_amount = float(amount)

        if chosen_gateway == "PAYSTACK":
            # Paystack expects amount in minor units (kobo/cents: multiply by 100)
            paystack_amount = int(numeric_amount * 100)
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
                    "description": f"Funding {currency.upper()} Wallet Balance",
                    "logo": "http://13.48.25.254/PayNora.apk"
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
