"""
Dedicated Virtual Account (NUBAN) Engine for SendMoni.
Supports both:
  1. Paystack Dedicated Virtual Accounts (Paystack-Titan / Wema Bank) — primary for Nigeria
  2. Flutterwave Permanent Virtual Account Numbers (Wema / Sterling / Providus) — failover / secondary

Every generated NUBAN is persisted in /data/paynora_state.json so inbound bank transfers
from OPay, GTBank, Access, Zenith, Kuda, etc. are automatically matched and credited via webhook.
"""
from typing import Any, Dict, Optional
import httpx

from app.config import settings
from app.storage import load_section, save_section

VIRTUAL_ACCOUNTS_DB: Dict[str, Dict[str, Any]] = load_section("virtual_accounts_db", {})


def persist_virtual_accounts_db() -> None:
    save_section("virtual_accounts_db", VIRTUAL_ACCOUNTS_DB)


def get_user_virtual_account(user_id: str) -> Optional[Dict[str, Any]]:
    return VIRTUAL_ACCOUNTS_DB.get(user_id)


def find_user_id_by_nuban(account_number: str) -> Optional[str]:
    acc = (account_number or "").strip()
    if not acc:
        return None
    for uid, va in VIRTUAL_ACCOUNTS_DB.items():
        if str(va.get("account_number", "")).strip() == acc:
            return uid
    return None


async def _create_paystack_dva(user: Dict[str, Any], preferred_bank: str = "titan-paystack") -> Dict[str, Any]:
    if not settings.PAYSTACK_SECRET_KEY:
        return {"status": "ERROR", "message": "Paystack secret key is not configured."}
    headers = {
        "Authorization": f"Bearer {settings.PAYSTACK_SECRET_KEY}",
        "Content-Type": "application/json",
    }
    email = user.get("email", "")
    first_name = user.get("first_name", "SendMoni")
    last_name = user.get("last_name", "Customer")
    phone = user.get("phone", "+2348000000000")

    async with httpx.AsyncClient(timeout=25.0) as client:
        # 1. Create or fetch Paystack customer
        cust_resp = await client.post(
            "https://api.paystack.co/customer",
            headers=headers,
            json={
                "email": email,
                "first_name": first_name,
                "last_name": last_name,
                "phone": phone,
            },
        )
        cust_data = cust_resp.json()
        if not cust_data.get("status"):
            return {"status": "ERROR", "message": cust_data.get("message", "Could not register customer on Paystack.")}
        customer_code = cust_data["data"]["customer_code"]

        # 2. Request Dedicated Virtual Account (Paystack-Titan or Wema Bank)
        dva_resp = await client.post(
            "https://api.paystack.co/dedicated_account",
            headers=headers,
            json={
                "customer": customer_code,
                "preferred_bank": preferred_bank,
            },
        )
        dva_data = dva_resp.json()
        if not dva_data.get("status"):
            return {
                "status": "ERROR",
                "message": dva_data.get("message", "Paystack could not assign a Dedicated Virtual Account."),
            }
        d = dva_data["data"]
        bank_obj = d.get("bank") or {}
        return {
            "status": "SUCCESS",
            "provider": "PAYSTACK",
            "bank_name": bank_obj.get("name") or ("Paystack-Titan" if "titan" in preferred_bank else "Wema Bank"),
            "bank_slug": bank_obj.get("slug") or preferred_bank,
            "account_number": d.get("account_number"),
            "account_name": d.get("account_name") or f"SendMoni / {first_name} {last_name}",
            "currency": d.get("currency", "NGN"),
            "customer_code": customer_code,
            "assigned": True,
        }


async def _create_flutterwave_va(user: Dict[str, Any], bvn: Optional[str] = None) -> Dict[str, Any]:
    if not settings.FLW_SECRET_KEY:
        return {"status": "ERROR", "message": "Flutterwave secret key is not configured."}
    if not bvn or len(bvn.strip()) != 11 or not bvn.strip().isdigit():
        return {
            "status": "ERROR",
            "message": "An 11-digit BVN is required by CBN to issue a permanent Flutterwave Virtual Account.",
        }
    headers = {
        "Authorization": f"Bearer {settings.FLW_SECRET_KEY}",
        "Content-Type": "application/json",
    }
    user_id = user["user_id"]
    first_name = user.get("first_name", "SendMoni")
    last_name = user.get("last_name", "Customer")
    payload = {
        "email": user.get("email", ""),
        "is_permanent": True,
        "bvn": bvn.strip(),
        "tx_ref": f"sm_va_{user_id}",
        "phonenumber": user.get("phone", "+2348000000000"),
        "firstname": first_name,
        "lastname": last_name,
        "narration": f"SendMoni {first_name} {last_name}",
    }
    async with httpx.AsyncClient(timeout=25.0) as client:
        resp = await client.post(
            "https://api.flutterwave.com/v3/virtual-account-numbers",
            headers=headers,
            json=payload,
        )
        data = resp.json()
        if resp.status_code not in (200, 201) or data.get("status") != "success":
            return {
                "status": "ERROR",
                "message": data.get("message", "Flutterwave could not create a permanent Virtual Account."),
            }
        d = data.get("data") or {}
        return {
            "status": "SUCCESS",
            "provider": "FLUTTERWAVE",
            "bank_name": d.get("bank_name") or "Wema Bank",
            "bank_slug": "flutterwave-va",
            "account_number": d.get("account_number"),
            "account_name": f"SendMoni / {first_name} {last_name}",
            "currency": "NGN",
            "order_ref": d.get("order_ref"),
            "assigned": True,
        }


async def provision_virtual_account(
    user: Dict[str, Any],
    preferred_provider: str = "PAYSTACK",
    preferred_bank: str = "titan-paystack",
    bvn: Optional[str] = None,
) -> Dict[str, Any]:
    user_id = user["user_id"]
    existing = VIRTUAL_ACCOUNTS_DB.get(user_id)
    if existing and existing.get("account_number"):
        return existing

    prov = (preferred_provider or "PAYSTACK").upper()
    if prov == "FLUTTERWAVE":
        res = await _create_flutterwave_va(user, bvn=bvn)
        if res.get("status") != "SUCCESS" and settings.PAYSTACK_SECRET_KEY:
            fallback = await _create_paystack_dva(user, preferred_bank=preferred_bank)
            if fallback.get("status") == "SUCCESS":
                res = fallback
    else:
        res = await _create_paystack_dva(user, preferred_bank=preferred_bank)
        if res.get("status") != "SUCCESS" and bvn and settings.FLW_SECRET_KEY:
            fallback = await _create_flutterwave_va(user, bvn=bvn)
            if fallback.get("status") == "SUCCESS":
                res = fallback

    if res.get("status") == "SUCCESS" and res.get("account_number"):
        record = {
            "user_id": user_id,
            **res,
        }
        VIRTUAL_ACCOUNTS_DB[user_id] = record
        persist_virtual_accounts_db()
        return record
    return res
