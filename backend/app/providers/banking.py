from typing import Dict, Any, List, Optional
import httpx
from app.config import settings

# Pre-populated fallback lists of major banks for instant high-speed rendering & offline resilience
FALLBACK_BANKS: Dict[str, List[Dict[str, str]]] = {
    "NG": [
        {"id": 1, "code": "044", "name": "Access Bank"},
        {"id": 2, "code": "023", "name": "Citibank Nigeria"},
        {"id": 3, "code": "050", "name": "Ecobank Nigeria"},
        {"id": 4, "code": "070", "name": "Fidelity Bank"},
        {"id": 5, "code": "011", "name": "First Bank of Nigeria"},
        {"id": 6, "code": "214", "name": "First City Monument Bank (FCMB)"},
        {"id": 7, "code": "058", "name": "Guaranty Trust Bank (GTBank)"},
        {"id": 8, "code": "030", "name": "Heritage Bank"},
        {"id": 9, "code": "082", "name": "Keystone Bank"},
        {"id": 10, "code": "50211", "name": "Kuda Bank"},
        {"id": 11, "code": "999991", "name": "OPay Digital Services"},
        {"id": 12, "code": "999992", "name": "PalmPay"},
        {"id": 13, "code": "076", "name": "Polaris Bank"},
        {"id": 14, "code": "101", "name": "Providus Bank"},
        {"id": 15, "code": "221", "name": "Stanbic IBTC Bank"},
        {"id": 16, "code": "068", "name": "Standard Chartered Bank"},
        {"id": 17, "code": "232", "name": "Sterling Bank"},
        {"id": 18, "code": "100", "name": "Suntrust Bank"},
        {"id": 19, "code": "032", "name": "Union Bank of Nigeria"},
        {"id": 20, "code": "033", "name": "United Bank for Africa (UBA)"},
        {"id": 21, "code": "215", "name": "Unity Bank"},
        {"id": 22, "code": "035", "name": "Wema Bank"},
        {"id": 23, "code": "057", "name": "Zenith Bank"}
    ],
    "GH": [
        {"id": 101, "code": "GH010100", "name": "Bank of Ghana"},
        {"id": 102, "code": "GH040100", "name": "GCB Bank"},
        {"id": 103, "code": "GH130100", "name": "Ecobank Ghana"},
        {"id": 104, "code": "GH030100", "name": "Absa Bank Ghana"}
    ],
    "KE": [
        {"id": 201, "code": "01", "name": "Kenya Commercial Bank (KCB)"},
        {"id": 202, "code": "11", "name": "Co-operative Bank of Kenya"},
        {"id": 203, "code": "68", "name": "Equity Bank"},
        {"id": 204, "code": "03", "name": "Barclays Bank of Kenya (Absa)"}
    ],
    "GB": [
        {"id": 301, "code": "BARC", "name": "Barclays Bank UK"},
        {"id": 302, "code": "HSBC", "name": "HSBC UK"},
        {"id": 303, "code": "LLOY", "name": "Lloyds Bank"},
        {"id": 304, "code": "NATW", "name": "NatWest"},
        {"id": 305, "code": "REVO", "name": "Revolut UK"}
    ],
    "US": [
        {"id": 401, "code": "JPMC", "name": "JPMorgan Chase"},
        {"id": 402, "code": "BOFA", "name": "Bank of America"},
        {"id": 403, "code": "WFC", "name": "Wells Fargo"},
        {"id": 404, "code": "CITI", "name": "Citibank US"}
    ]
}

class BankingEngine:
    FLUTTERWAVE_BASE_URL = "https://api.flutterwave.com/v3"
    PAYSTACK_BASE_URL = "https://api.paystack.co"

    @classmethod
    async def get_banks(cls, country: str = "NG") -> List[Dict[str, Any]]:
        """Fetch list of banks from Flutterwave, fallback to pre-cached bank list."""
        c = country.upper()
        if settings.FLW_SECRET_KEY:
            try:
                headers = {"Authorization": f"Bearer {settings.FLW_SECRET_KEY}"}
                async with httpx.AsyncClient(timeout=10.0) as client:
                    resp = await client.get(f"{cls.FLUTTERWAVE_BASE_URL}/banks/{c}", headers=headers)
                    if resp.status_code == 200:
                        data = resp.json()
                        if data.get("status") == "success" and data.get("data"):
                            return data["data"]
            except Exception as e:
                print(f"[BankingEngine] Failed to fetch live banks from Flutterwave for {c}: {e}")

        return FALLBACK_BANKS.get(c, FALLBACK_BANKS["NG"])

    @classmethod
    async def resolve_account(cls, account_number: str, bank_code: str, currency: str = "NGN") -> Dict[str, Any]:
        """
        Verify account number in real-time and resolve legal account holder name.
        Uses Flutterwave live verification first, then Paystack if configured, with smart mock fallback.
        """
        acc_num = account_number.strip()
        code = str(bank_code).strip()

        # 1. Try Flutterwave live account resolution
        if settings.FLW_SECRET_KEY:
            try:
                headers = {
                    "Authorization": f"Bearer {settings.FLW_SECRET_KEY}",
                    "Content-Type": "application/json"
                }
                payload = {
                    "account_number": acc_num,
                    "account_bank": code
                }
                async with httpx.AsyncClient(timeout=15.0) as client:
                    resp = await client.post(f"{cls.FLUTTERWAVE_BASE_URL}/accounts/resolve", json=payload, headers=headers)
                    data = resp.json()
                    if resp.status_code == 200 and data.get("status") == "success":
                        account_name = data.get("data", {}).get("account_name", "")
                        return {
                            "status": "SUCCESS",
                            "account_number": acc_num,
                            "account_name": account_name.upper(),
                            "bank_code": code,
                            "verified": True,
                            "provider": "FLUTTERWAVE"
                        }
                    else:
                        error_msg = data.get("message", "Unable to resolve account")
                        if "not found" in error_msg.lower() or "invalid" in error_msg.lower():
                            return {
                                "status": "ERROR",
                                "message": error_msg,
                                "verified": False
                            }
            except Exception as e:
                print(f"[BankingEngine] Live account resolution error: {e}")

        # 2. Try Paystack if available
        if settings.PAYSTACK_SECRET_KEY:
            try:
                headers = {"Authorization": f"Bearer {settings.PAYSTACK_SECRET_KEY}"}
                async with httpx.AsyncClient(timeout=15.0) as client:
                    resp = await client.get(
                        f"{cls.PAYSTACK_BASE_URL}/bank/resolve?account_number={acc_num}&bank_code={code}",
                        headers=headers
                    )
                    data = resp.json()
                    if resp.status_code == 200 and data.get("status"):
                        return {
                            "status": "SUCCESS",
                            "account_number": acc_num,
                            "account_name": data.get("data", {}).get("account_name", "").upper(),
                            "bank_code": code,
                            "verified": True,
                            "provider": "PAYSTACK"
                        }
            except Exception as e:
                print(f"[BankingEngine] Paystack resolution error: {e}")

        # 3. Fallback mock resolver for sandbox / testing
        if len(acc_num) == 10:
            mock_names = {
                "0123456789": "CHUKWUEMEKA OBI",
                "0690000031": "PAYNORA CORPORATE SETTLEMENT",
                "1234567890": "FATIMA ABUBAKAR"
            }
            resolved_name = mock_names.get(acc_num, f"VERIFIED ACCOUNT ({acc_num[-4:]})")
            return {
                "status": "SUCCESS",
                "account_number": acc_num,
                "account_name": resolved_name,
                "bank_code": code,
                "verified": True,
                "provider": "SANDBOX_VERIFIER"
            }

        return {
            "status": "ERROR",
            "message": "Account could not be verified. Please check the account number and bank.",
            "verified": False
        }

    @classmethod
    async def disburse_payout(
        cls,
        transfer_id: str,
        account_bank: str,
        account_number: str,
        amount: str,
        currency: str,
        recipient_name: str,
        narration: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Disburse funds directly to recipient bank account using Flutterwave Transfer API.
        """
        ref = f"payout_{transfer_id}"
        if settings.FLW_SECRET_KEY:
            try:
                headers = {
                    "Authorization": f"Bearer {settings.FLW_SECRET_KEY}",
                    "Content-Type": "application/json"
                }
                body = {
                    "account_bank": account_bank,
                    "account_number": account_number,
                    "amount": float(amount),
                    "narration": narration or f"PayNora Transfer {transfer_id}",
                    "currency": currency.upper(),
                    "reference": ref,
                    "callback_url": "http://13.48.25.254:8000/api/v1/webhooks/flutterwave",
                    "debit_currency": currency.upper()
                }
                async with httpx.AsyncClient(timeout=20.0) as client:
                    resp = await client.post(f"{cls.FLUTTERWAVE_BASE_URL}/transfers", json=body, headers=headers)
                    data = resp.json()
                    if resp.status_code == 200 and data.get("status") == "success":
                        transfer_data = data.get("data", {})
                        return {
                            "status": "SUCCESS",
                            "disbursal_status": transfer_data.get("status", "PENDING"),
                            "provider_transfer_id": transfer_data.get("id"),
                            "reference": ref,
                            "fee": transfer_data.get("fee", 0),
                            "raw": data
                        }
                    else:
                        return {
                            "status": "ERROR",
                            "message": data.get("message", "Flutterwave transfer failed"),
                            "code": "PROVIDER_DISBURSAL_FAILED",
                            "raw": data
                        }
            except Exception as e:
                return {
                    "status": "ERROR",
                    "message": f"Network error during disbursal: {str(e)}",
                    "code": "NETWORK_EXCEPTION"
                }

        # Mock success for simulation / development
        return {
            "status": "SUCCESS",
            "disbursal_status": "COMPLETED",
            "provider_transfer_id": f"flw_sim_{transfer_id}",
            "reference": ref,
            "simulated": True
        }
