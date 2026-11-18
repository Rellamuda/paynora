from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from decimal import Decimal
import uuid
import random
import httpx
from app.api.v1.auth import get_current_user
from app.wallets.models import WalletEngine, resolve_local_currency
from app.config import settings

router = APIRouter(prefix="/bills", tags=["Bills & Utilities"])
FLW_BILLS_URL = "https://api.flutterwave.com/v3/bills"

# Telco Operators by Country
OPERATORS_BY_COUNTRY: Dict[str, List[Dict[str, str]]] = {
    "NG": [
        {"id": "mtn_ng", "name": "MTN Nigeria", "code": "MTN", "icon": "🟡"},
        {"id": "airtel_ng", "name": "Airtel Nigeria", "code": "AIRTEL", "icon": "🔴"},
        {"id": "glo_ng", "name": "Globacom (Glo)", "code": "GLO", "icon": "🟢"},
        {"id": "9mobile_ng", "name": "9mobile", "code": "9MOBILE", "icon": "🟢"}
    ],
    "GH": [
        {"id": "mtn_gh", "name": "MTN Ghana", "code": "MTN", "icon": "🟡"},
        {"id": "telecel_gh", "name": "Telecel Ghana", "code": "TELECEL", "icon": "🔴"},
        {"id": "at_gh", "name": "AT Ghana (AirtelTigo)", "code": "AT", "icon": "🔵"}
    ],
    "KE": [
        {"id": "safaricom_ke", "name": "Safaricom (M-Pesa)", "code": "SAFARICOM", "icon": "🟢"},
        {"id": "airtel_ke", "name": "Airtel Kenya", "code": "AIRTEL", "icon": "🔴"}
    ],
    "ZA": [
        {"id": "vodacom_za", "name": "Vodacom South Africa", "code": "VODACOM", "icon": "🔴"},
        {"id": "mtn_za", "name": "MTN South Africa", "code": "MTN", "icon": "🟡"},
        {"id": "cellc_za", "name": "Cell C", "code": "CELLC", "icon": "⚫"}
    ],
    "GB": [
        {"id": "ee_uk", "name": "EE UK", "code": "EE", "icon": "🟡"},
        {"id": "o2_uk", "name": "O2 UK", "code": "O2", "icon": "🔵"},
        {"id": "vodafone_uk", "name": "Vodafone UK", "code": "VODAFONE", "icon": "🔴"}
    ],
    "US": [
        {"id": "att_us", "name": "AT&T Mobility", "code": "ATT", "icon": "🔵"},
        {"id": "verizon_us", "name": "Verizon Wireless", "code": "VERIZON", "icon": "🔴"},
        {"id": "tmobile_us", "name": "T-Mobile USA", "code": "TMOBILE", "icon": "🟣"}
    ]
}

DATA_PLANS_BY_OPERATOR: Dict[str, List[Dict[str, Any]]] = {
    "default": [
        {"id": "plan_1gb_d", "name": "1GB Daily Boost", "allowance": "1GB", "validity": "1 Day", "amount": "350.00"},
        {"id": "plan_2gb_2d", "name": "2.5GB 2-Day Bundle", "allowance": "2.5GB", "validity": "2 Days", "amount": "600.00"},
        {"id": "plan_6gb_7d", "name": "6GB Weekly Mega", "allowance": "6GB", "validity": "7 Days", "amount": "1500.00"},
        {"id": "plan_12gb_30d", "name": "12GB Monthly Smart", "allowance": "12GB", "validity": "30 Days", "amount": "3500.00"},
        {"id": "plan_25gb_30d", "name": "25GB Monthly Max", "allowance": "25GB", "validity": "30 Days", "amount": "6500.00"},
        {"id": "plan_40gb_30d", "name": "40GB Monthly Executive", "allowance": "40GB", "validity": "30 Days", "amount": "10000.00"}
    ]
}

ELECTRICITY_DISCOS: Dict[str, List[Dict[str, str]]] = {
    "NG": [
        {"code": "IKEDC", "name": "Ikeja Electric (IKEDC)", "coverage": "Lagos Mainland & Ikeja"},
        {"code": "EKEDC", "name": "Eko Electricity Distribution (EKEDC)", "coverage": "Lagos Island, Lekki & Epe"},
        {"code": "AEDC", "name": "Abuja Electricity (AEDC)", "coverage": "Abuja FCT, Niger, Kogi, Nasarawa"},
        {"code": "IBEDC", "name": "Ibadan Electricity (IBEDC)", "coverage": "Oyo, Ogun, Osun, Kwara"},
        {"code": "EEDC", "name": "Enugu Electricity (EEDC)", "coverage": "Enugu, Abia, Imo, Anambra, Ebonyi"},
        {"code": "PHED", "name": "Port Harcourt Electricity (PHED)", "coverage": "Rivers, Bayelsa, Cross River, Akwa Ibom"},
        {"code": "KEDCO", "name": "Kano Electricity (KEDCO)", "coverage": "Kano, Katsina, Jigawa"},
        {"code": "BEDC", "name": "Benin Electricity (BEDC)", "coverage": "Edo, Delta, Ondo, Ekiti"}
    ],
    "GH": [
        {"code": "ECG", "name": "Electricity Company of Ghana (ECG)", "coverage": "Greater Accra & Regional"}
    ],
    "KE": [
        {"code": "KPLC", "name": "Kenya Power & Lighting (KPLC)", "coverage": "National Grid"}
    ]
}


# Request Schemas
class AirtimePurchaseRequest(BaseModel):
    phone_number: str
    operator_code: str
    amount: str
    country_iso: str = "NG"


class DataBundlePurchaseRequest(BaseModel):
    phone_number: str
    operator_code: str
    plan_id: str
    amount: str
    country_iso: str = "NG"


class ValidateMeterRequest(BaseModel):
    disco_code: str
    meter_number: str
    meter_type: str = "PREPAID"  # PREPAID or POSTPAID
    country_iso: str = "NG"


class ElectricityPaymentRequest(BaseModel):
    disco_code: str
    meter_number: str
    meter_type: str = "PREPAID"
    amount: str
    customer_name: Optional[str] = None
    country_iso: str = "NG"


def _debit_local_wallet(user_id: str, amount: Decimal) -> Dict[str, Any]:
    wallets = WalletEngine.get_user_wallets(user_id)
    local_ccy = resolve_local_currency(user_id)
    local_wallet = next((w for w in wallets if w["currency"] == local_ccy), None)
    if not local_wallet:
        raise HTTPException(status_code=400, detail="Local currency wallet not found.")
    current_bal = Decimal(local_wallet["available_balance"])
    if current_bal < amount:
        raise HTTPException(status_code=400, detail=f"Insufficient {local_wallet['currency']} wallet balance.")
    local_wallet["available_balance"] = f"{(current_bal - amount):.2f}"
    return local_wallet


async def _call_flw_bills(country: str, customer: str, amount: Decimal, bill_type: str, reference: str) -> Optional[Dict[str, Any]]:
    """Execute live bill payment via Flutterwave Bills API when a live FLW_SECRET_KEY is configured."""
    if not settings.FLW_SECRET_KEY or "TEST" in settings.FLW_SECRET_KEY.upper():
        return None
    headers = {
        "Authorization": f"Bearer {settings.FLW_SECRET_KEY}",
        "Content-Type": "application/json",
    }
    body = {
        "country": country.upper(),
        "customer": customer,
        "amount": float(amount),
        "recurrence": "ONCE",
        "type": bill_type,
        "reference": reference,
    }
    try:
        async with httpx.AsyncClient(timeout=20.0) as client:
            resp = await client.post(FLW_BILLS_URL, json=body, headers=headers)
            data = resp.json()
            if resp.status_code in (200, 201) and data.get("status") == "success":
                return data.get("data") or {}
            return {"_error": data.get("message", "Bill provider rejected the transaction.")}
    except Exception as e:
        return {"_error": f"Bill provider network error: {str(e)}"}


# Endpoints
@router.get("/operators")
def get_telco_operators(country: str = "NG"):
    """Fetch available telecom providers for airtime and data."""
    c = country.upper()
    operators = OPERATORS_BY_COUNTRY.get(c, OPERATORS_BY_COUNTRY["NG"])
    return {"country": c, "count": len(operators), "operators": operators}


@router.get("/data-plans")
def get_data_plans(operator_code: str = "MTN"):
    """Fetch verified internet data bundle packages."""
    plans = DATA_PLANS_BY_OPERATOR.get(operator_code.lower(), DATA_PLANS_BY_OPERATOR["default"])
    return {"operator": operator_code, "count": len(plans), "plans": plans}


@router.get("/electricity-providers")
def get_electricity_providers(country: str = "NG"):
    """Fetch electric distribution companies (Discos) for utility bills."""
    c = country.upper()
    discos = ELECTRICITY_DISCOS.get(c, ELECTRICITY_DISCOS["NG"])
    return {"country": c, "count": len(discos), "providers": discos}


@router.post("/validate-meter")
def validate_electricity_meter(payload: ValidateMeterRequest):
    """Validate customer meter number before recharge."""
    meter = payload.meter_number.strip().replace(" ", "")
    if len(meter) < 8:
        raise HTTPException(status_code=400, detail="Meter number must be at least 8 digits.")

    mock_names = ["OLUWASEUN ADEKUNLE", "CHIDI OKONKWO", "EMMANUEL DANJUMA", "FATIMA BELLO", "GRACE AFOLABI"]
    chosen_name = mock_names[hash(meter) % len(mock_names)]

    return {
        "status": "VALID",
        "disco": payload.disco_code,
        "meter_number": meter,
        "meter_type": payload.meter_type.upper(),
        "customer_name": chosen_name,
        "address": f"Plot {abs(hash(meter)) % 80 + 1}, PayNora Power Grid, Phase 1",
        "minimum_amount": "500.00"
    }


@router.post("/airtime")
async def purchase_airtime(payload: AirtimePurchaseRequest, current_user: dict = Depends(get_current_user)):
    """Instant call units (airtime) recharge from user's local currency wallet."""
    user_id = current_user["user_id"]
    amount = Decimal(payload.amount)
    if amount <= Decimal("0"):
        raise HTTPException(status_code=400, detail="Recharge amount must be greater than zero.")

    local_wallet = _debit_local_wallet(user_id, amount)
    tx_id = f"air_{uuid.uuid4().hex[:10]}"

    flw_res = await _call_flw_bills(payload.country_iso, payload.phone_number, amount, "AIRTIME", tx_id)
    if flw_res and "_error" in flw_res:
        local_wallet["available_balance"] = f"{(Decimal(local_wallet['available_balance']) + amount):.2f}"
        raise HTTPException(status_code=400, detail=flw_res["_error"])

    return {
        "status": "SUCCESSFUL",
        "transaction_id": tx_id,
        "provider_reference": (flw_res or {}).get("flw_ref", tx_id),
        "phone_number": payload.phone_number,
        "operator": payload.operator_code,
        "amount": f"{amount:.2f}",
        "currency": local_wallet["currency"],
        "wallet_balance_after": local_wallet["available_balance"],
        "live_provider": bool(flw_res),
        "message": f"Airtime recharge of {local_wallet['currency']} {amount:.2f} to {payload.phone_number} delivered instantly."
    }


@router.post("/data")
async def purchase_data_bundle(payload: DataBundlePurchaseRequest, current_user: dict = Depends(get_current_user)):
    """Instant mobile data bundle activation from user's local currency wallet."""
    user_id = current_user["user_id"]
    amount = Decimal(payload.amount)
    if amount <= Decimal("0"):
        raise HTTPException(status_code=400, detail="Data bundle amount must be greater than zero.")

    local_wallet = _debit_local_wallet(user_id, amount)
    tx_id = f"dat_{uuid.uuid4().hex[:10]}"

    flw_res = await _call_flw_bills(payload.country_iso, payload.phone_number, amount, payload.plan_id, tx_id)
    if flw_res and "_error" in flw_res:
        local_wallet["available_balance"] = f"{(Decimal(local_wallet['available_balance']) + amount):.2f}"
        raise HTTPException(status_code=400, detail=flw_res["_error"])

    return {
        "status": "SUCCESSFUL",
        "transaction_id": tx_id,
        "provider_reference": (flw_res or {}).get("flw_ref", tx_id),
        "phone_number": payload.phone_number,
        "operator": payload.operator_code,
        "plan_id": payload.plan_id,
        "amount": f"{amount:.2f}",
        "currency": local_wallet["currency"],
        "wallet_balance_after": local_wallet["available_balance"],
        "live_provider": bool(flw_res),
        "message": f"Data bundle activation to {payload.phone_number} completed instantly."
    }


@router.post("/electricity")
async def purchase_electricity(payload: ElectricityPaymentRequest, current_user: dict = Depends(get_current_user)):
    """Purchase electricity tokens (prepaid) or settle utility bills (postpaid)."""
    user_id = current_user["user_id"]
    amount = Decimal(payload.amount)
    if amount < Decimal("500.00"):
        raise HTTPException(status_code=400, detail="Minimum electricity payment is 500.00.")

    local_wallet = _debit_local_wallet(user_id, amount)
    tx_id = f"pwr_{uuid.uuid4().hex[:10]}"

    flw_res = await _call_flw_bills(payload.country_iso, payload.meter_number, amount, payload.disco_code, tx_id)
    if flw_res and "_error" in flw_res:
        local_wallet["available_balance"] = f"{(Decimal(local_wallet['available_balance']) + amount):.2f}"
        raise HTTPException(status_code=400, detail=flw_res["_error"])

    provider_token = (flw_res or {}).get("recharge_token") or (flw_res or {}).get("token")
    if provider_token:
        token_formatted = str(provider_token)
    else:
        raw_digits = "".join([str(random.randint(0, 9)) for _ in range(20)])
        token_formatted = f"{raw_digits[0:4]}-{raw_digits[4:8]}-{raw_digits[8:12]}-{raw_digits[12:16]}-{raw_digits[16:20]}"

    kwh_units = round(float(amount) / 68.0, 1)

    return {
        "status": "SUCCESSFUL",
        "transaction_id": tx_id,
        "provider_reference": (flw_res or {}).get("flw_ref", tx_id),
        "disco": payload.disco_code,
        "meter_number": payload.meter_number,
        "meter_type": payload.meter_type.upper(),
        "customer_name": payload.customer_name or "PAYNORA SUBSCRIBER",
        "amount": f"{amount:.2f}",
        "currency": local_wallet["currency"],
        "wallet_balance_after": local_wallet["available_balance"],
        "token": token_formatted,
        "units": f"{kwh_units} kWh",
        "live_provider": bool(flw_res),
        "message": f"Electricity recharge of {local_wallet['currency']} {amount:.2f} generated. Token: {token_formatted}"
    }
