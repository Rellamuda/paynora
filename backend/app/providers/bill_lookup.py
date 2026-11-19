"""
Real-world provider lookups for Bills:

1. Mobile network (carrier) detection that is SAFE FOR PORTED NUMBERS:
   - Live HLR / MNP lookup via Termii (Africa) or Twilio Lookup v2 (global), when API keys are configured.
   - Fallback: official numbering-plan prefixes (NG / GH / KE only), clearly flagged as NOT verified for porting.
   - Never guesses: if no lookup is possible, returns detected=False so the user picks the network.

2. Electricity meter verification via Flutterwave Bills:
   - Loads the real list of power billers for the country from Flutterwave.
   - Validates the meter against each biller (in parallel). The biller that accepts the meter
     IS the electricity company, and the customer name/address come back from the utility itself.
"""
import asyncio
import re
import time
from typing import Any, Dict, List, Optional

import httpx

from app.config import settings

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------
DIAL_CODES: Dict[str, str] = {
    "NG": "234", "GH": "233", "KE": "254", "ZA": "27", "UG": "256", "TZ": "255", "RW": "250",
    "ZM": "260", "CM": "237", "SN": "221", "CI": "225", "EG": "20", "MA": "212", "ET": "251",
    "GB": "44", "US": "1", "CA": "1", "IN": "91", "AE": "971", "SA": "966", "DE": "49",
    "FR": "33", "IT": "39", "ES": "34", "NL": "31", "IE": "353", "AU": "61", "BR": "55",
}

_CACHE: Dict[str, Any] = {}


def _cache_get(key: str) -> Optional[Any]:
    item = _CACHE.get(key)
    if item and item[0] > time.time():
        return item[1]
    return None


def _cache_set(key: str, value: Any, ttl_seconds: int) -> None:
    _CACHE[key] = (time.time() + ttl_seconds, value)


def _digits(s: str) -> str:
    return re.sub(r"\D", "", s or "")


def to_e164(phone: str, country_iso: str) -> Optional[str]:
    """Normalise a local or international phone number to E.164 (+2348031234567)."""
    raw = (phone or "").strip()
    d = _digits(raw)
    if not d:
        return None
    if raw.startswith("+"):
        return f"+{d}"
    if d.startswith("00"):
        return f"+{d[2:]}"
    cc = DIAL_CODES.get((country_iso or "NG").upper())
    if not cc:
        return f"+{d}"
    if d.startswith(cc) and len(d) > len(cc) + 6:
        return f"+{d}"
    if d.startswith("0"):
        d = d[1:]
    return f"+{cc}{d}"


# ---------------------------------------------------------------------------
# 1. Mobile network detection
# ---------------------------------------------------------------------------
# Official numbering-plan prefixes (initial allocation only — NOT valid for ported numbers)
NG_PREFIX_MAP: Dict[str, str] = {
    "0703": "MTN", "0704": "MTN", "0706": "MTN", "0707": "MTN", "0803": "MTN", "0806": "MTN",
    "0810": "MTN", "0813": "MTN", "0814": "MTN", "0816": "MTN", "0903": "MTN",
    "0906": "MTN", "0913": "MTN", "0916": "MTN", "0702": "MTN",
    "0701": "AIRTEL", "0708": "AIRTEL", "0802": "AIRTEL", "0808": "AIRTEL",
    "0812": "AIRTEL", "0901": "AIRTEL", "0902": "AIRTEL", "0904": "AIRTEL",
    "0907": "AIRTEL", "0912": "AIRTEL", "0911": "AIRTEL",
    "0705": "GLO", "0805": "GLO", "0807": "GLO", "0811": "GLO", "0815": "GLO",
    "0905": "GLO", "0915": "GLO",
    "0809": "9MOBILE", "0817": "9MOBILE", "0818": "9MOBILE", "0908": "9MOBILE", "0909": "9MOBILE",
}
GH_PREFIX_MAP: Dict[str, str] = {
    "024": "MTN", "054": "MTN", "055": "MTN", "059": "MTN", "025": "MTN", "053": "MTN",
    "020": "TELECEL", "050": "TELECEL",
    "027": "AT", "057": "AT", "026": "AT", "056": "AT",
}
KE_PREFIX_MAP: Dict[str, str] = {
    "070": "SAFARICOM", "071": "SAFARICOM", "072": "SAFARICOM", "074": "SAFARICOM",
    "079": "SAFARICOM", "011": "SAFARICOM",
    "073": "AIRTEL", "075": "AIRTEL", "078": "AIRTEL", "010": "AIRTEL",
    "077": "TELKOM",
}

# Keyword -> operator code mapping for carrier names returned by live lookup providers
CARRIER_KEYWORDS: List[tuple] = [
    ("9mobile", "9MOBILE"), ("etisalat", "9MOBILE"), ("emerging markets", "9MOBILE"), ("emts", "9MOBILE"),
    ("airteltigo", "AT"), ("airtel", "AIRTEL"), ("glo", "GLO"), ("mtn", "MTN"),
    ("safaricom", "SAFARICOM"), ("telkom", "TELKOM"), ("telecel", "TELECEL"),
    ("vodacom", "VODACOM"), ("cell c", "CELLC"), ("vodafone", "VODAFONE"),
    ("ee limited", "EE"), ("o2", "O2"), ("hutchison", "THREE"), ("three", "THREE"),
    ("at&t", "ATT"), ("verizon", "VERIZON"), ("t-mobile", "TMOBILE"),
    ("rogers", "ROGERS"), ("fido", "ROGERS"), ("bell", "BELL"), ("virgin plus", "BELL"),
    ("telus", "TELUS"), ("koodo", "TELUS"), ("freedom", "FREEDOM"),
]


def _carrier_to_code(carrier_name: str) -> Optional[str]:
    low = (carrier_name or "").lower()
    for kw, code in CARRIER_KEYWORDS:
        if kw in low:
            return code
    return None


async def _termii_lookup(e164: str, country_iso: str) -> Optional[Dict[str, Any]]:
    """Termii Number Status / Insight API — live network incl. ported status (Africa)."""
    key = getattr(settings, "TERMII_API_KEY", "")
    if not key:
        return None
    base = getattr(settings, "TERMII_BASE_URL", "") or "https://api.ng.termii.com"
    params = {"api_key": key, "phone_number": e164.lstrip("+"), "country_code": country_iso.upper()}
    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            resp = await client.get(f"{base}/api/insight/number/query", params=params)
            data = resp.json()
        rows = data.get("result") if isinstance(data, dict) else None
        row = rows[0] if isinstance(rows, list) and rows else data
        op = (row or {}).get("operatorDetail") or {}
        route = (row or {}).get("routeDetail") or {}
        carrier = op.get("operatorName") or (row or {}).get("network") or (row or {}).get("operator")
        if not carrier:
            return None
        ported_raw = route.get("ported", (row or {}).get("ported"))
        return {
            "carrier_name": carrier,
            "ported": bool(int(ported_raw)) if str(ported_raw).isdigit() else None,
            "method": "LIVE_HLR_TERMII",
        }
    except Exception as e:
        print(f"[CarrierLookup] Termii lookup failed: {e}")
        return None


async def _twilio_lookup(e164: str) -> Optional[Dict[str, Any]]:
    """Twilio Lookup v2 Line Type Intelligence — live carrier (reflects porting), global."""
    sid = getattr(settings, "TWILIO_ACCOUNT_SID", "")
    token = getattr(settings, "TWILIO_AUTH_TOKEN", "")
    if not sid or not token:
        return None
    try:
        async with httpx.AsyncClient(timeout=8.0, auth=(sid, token)) as client:
            resp = await client.get(
                f"https://lookups.twilio.com/v2/PhoneNumbers/{e164}",
                params={"Fields": "line_type_intelligence"},
            )
            data = resp.json()
        lti = data.get("line_type_intelligence") or {}
        carrier = lti.get("carrier_name")
        if not carrier:
            return None
        return {"carrier_name": carrier, "ported": None, "line_type": lti.get("type"), "method": "LIVE_HLR_TWILIO"}
    except Exception as e:
        print(f"[CarrierLookup] Twilio lookup failed: {e}")
        return None


def _prefix_detect(e164: str, country_iso: str) -> Optional[str]:
    c = country_iso.upper()
    cc = DIAL_CODES.get(c, "")
    d = _digits(e164)
    local = "0" + d[len(cc):] if cc and d.startswith(cc) else d
    if c == "NG":
        return NG_PREFIX_MAP.get(local[:4])
    if c == "GH":
        return GH_PREFIX_MAP.get(local[:3])
    if c == "KE":
        return KE_PREFIX_MAP.get(local[:3])
    return None


def _country_from_e164(e164: str, fallback: str) -> str:
    d = _digits(e164)
    # Prefer the user's country when its code matches (e.g. US vs CA both +1)
    fb = fallback.upper()
    if DIAL_CODES.get(fb) and d.startswith(DIAL_CODES[fb]):
        return fb
    for iso, cc in sorted(DIAL_CODES.items(), key=lambda kv: -len(kv[1])):
        if d.startswith(cc):
            return iso
    return fb


async def lookup_mobile_network(phone: str, country_iso: str, operators: List[Dict[str, str]]) -> Dict[str, Any]:
    """
    Detect the CURRENT mobile network of a phone number.
    Order: live HLR (Termii -> Twilio) -> numbering-plan prefix (flagged unverified) -> not detected.
    """
    e164 = to_e164(phone, country_iso)
    if not e164 or len(_digits(e164)) < 10:
        return {"detected": False, "reason": "INCOMPLETE_NUMBER", "message": "Enter the full phone number."}

    c = _country_from_e164(e164, country_iso)
    cache_key = f"carrier:{e164}"
    cached = _cache_get(cache_key)
    if cached:
        return cached

    live = await _termii_lookup(e164, c) if c in ("NG", "GH", "KE", "ZA", "UG", "TZ", "RW", "ZM", "CM", "SN", "CI") else None
    if not live:
        live = await _twilio_lookup(e164)

    def _op_details(code: Optional[str], carrier_name: Optional[str]) -> Dict[str, str]:
        match = next((o for o in operators if o["code"] == code), None) if code else None
        if match:
            return {"operator_code": match["code"], "operator_name": match["name"], "icon": match.get("icon", "📶")}
        name = carrier_name or code or "Unknown network"
        return {"operator_code": code or re.sub(r"[^A-Z0-9]", "", name.upper())[:12], "operator_name": name, "icon": "📶"}

    if live:
        code = _carrier_to_code(live["carrier_name"])
        prefix_code = _prefix_detect(e164, c)
        ported = live.get("ported")
        if ported is None and prefix_code and code:
            ported = prefix_code != code
        result = {
            "detected": True,
            "verified": True,
            "method": live["method"],
            "phone_e164": e164,
            "country": c,
            "carrier_name": live["carrier_name"],
            "ported": bool(ported) if ported is not None else None,
            "original_network": prefix_code if ported else None,
            **_op_details(code, live["carrier_name"]),
        }
        result["message"] = (
            f"Number was ported from {prefix_code} — current network verified live: {result['operator_name']}."
            if ported and prefix_code else f"Current network verified live: {result['operator_name']}."
        )
        _cache_set(cache_key, result, 6 * 3600)
        return result

    prefix_code = _prefix_detect(e164, c)
    if prefix_code:
        result = {
            "detected": True,
            "verified": False,
            "method": "NUMBER_PREFIX",
            "phone_e164": e164,
            "country": c,
            "ported": None,
            **_op_details(prefix_code, None),
            "message": "Detected from the number prefix. If this number was ported to another network, tap 'Change network'.",
        }
        _cache_set(cache_key, result, 600)
        return result

    return {
        "detected": False,
        "verified": False,
        "method": "NONE",
        "phone_e164": e164,
        "country": c,
        "reason": "LOOKUP_UNAVAILABLE",
        "message": "We couldn't verify this number's network automatically. Please select the network.",
    }


# ---------------------------------------------------------------------------
# 2. Electricity meter verification via Flutterwave
# ---------------------------------------------------------------------------
FLW_BASE = "https://api.flutterwave.com/v3"


def flw_configured() -> bool:
    key = settings.FLW_SECRET_KEY or ""
    return bool(key) and "TEST" not in key.upper()


def _flw_headers() -> Dict[str, str]:
    return {"Authorization": f"Bearer {settings.FLW_SECRET_KEY}", "Content-Type": "application/json"}


async def get_power_billers(country_iso: str) -> List[Dict[str, Any]]:
    """Real electricity billers (prepaid & postpaid items) for a country, from Flutterwave."""
    c = (country_iso or "NG").upper()
    cache_key = f"power_billers:{c}"
    cached = _cache_get(cache_key)
    if cached is not None:
        return cached
    if not settings.FLW_SECRET_KEY:
        return []
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.get(f"{FLW_BASE}/bill-categories", params={"power": 1, "country": c}, headers=_flw_headers())
            data = resp.json()
        items = data.get("data") or [] if data.get("status") == "success" else []
        billers = [
            {
                "biller_code": i.get("biller_code"),
                "item_code": i.get("item_code"),
                "biller_name": i.get("biller_name") or i.get("name"),
                "name": i.get("name") or i.get("biller_name"),
                "short_name": i.get("short_name"),
                "label_name": i.get("label_name"),
            }
            for i in items
            if i.get("biller_code") and i.get("item_code")
        ]
        _cache_set(cache_key, billers, 6 * 3600 if billers else 300)
        return billers
    except Exception as e:
        print(f"[MeterLookup] Could not load Flutterwave power billers: {e}")
        return []


def _matches_meter_type(biller: Dict[str, Any], meter_type: str) -> bool:
    text = f"{biller.get('name', '')} {biller.get('biller_name', '')} {biller.get('short_name', '')}".upper()
    mt = (meter_type or "PREPAID").upper()
    other = "POSTPAID" if mt == "PREPAID" else "PREPAID"
    if mt in text:
        return True
    return other not in text  # untyped billers are allowed for both


async def _validate_one(client: httpx.AsyncClient, biller: Dict[str, Any], meter: str, sem: asyncio.Semaphore) -> Optional[Dict[str, Any]]:
    async with sem:
        try:
            resp = await client.get(
                f"{FLW_BASE}/bill-items/{biller['item_code']}/validate",
                params={"code": biller["biller_code"], "customer": meter},
                headers=_flw_headers(),
            )
            data = resp.json()
        except Exception:
            return None
    if data.get("status") != "success":
        return None
    d = data.get("data") or {}
    name = (d.get("name") or "").strip()
    if not name or str(d.get("response_code", "00")) not in ("00", "0"):
        return None
    return {
        "customer_name": name,
        "address": (d.get("address") or "").strip(),
        "biller_code": biller["biller_code"],
        "item_code": biller["item_code"],
        "biller_name": biller["biller_name"],
        "disco_name": biller["name"],
    }


async def verify_meter(meter: str, meter_type: str, country_iso: str, biller_code: Optional[str] = None) -> Dict[str, Any]:
    """
    Find which electricity company owns this meter by validating it against the real billers.
    Returns status VALID (with real customer name), NOT_FOUND, or UNAVAILABLE.
    """
    meter = _digits(meter)
    c = (country_iso or "NG").upper()
    cache_key = f"meter:{c}:{meter_type.upper()}:{meter}:{biller_code or ''}"
    cached = _cache_get(cache_key)
    if cached:
        return cached

    billers = await get_power_billers(c)
    if not billers:
        return {
            "status": "UNAVAILABLE",
            "message": "Live meter verification is currently unavailable. Please try again shortly.",
        }

    candidates = [b for b in billers if _matches_meter_type(b, meter_type)]
    if biller_code:
        candidates = [b for b in candidates if b["biller_code"] == biller_code] or candidates

    sem = asyncio.Semaphore(6)
    async with httpx.AsyncClient(timeout=15.0) as client:
        tasks = [asyncio.create_task(_validate_one(client, b, meter, sem)) for b in candidates]
        found = None
        for fut in asyncio.as_completed(tasks):
            res = await fut
            if res:
                found = res
                break
        for t in tasks:
            if not t.done():
                t.cancel()

    if not found:
        result = {
            "status": "NOT_FOUND",
            "meter_number": meter,
            "message": f"This {meter_type.lower()} meter number was not recognised by any electricity company. Check the number or the meter type (Prepaid/Postpaid).",
        }
        _cache_set(cache_key, result, 120)
        return result

    result = {
        "status": "VALID",
        "verified": True,
        "method": "LIVE_UTILITY_VALIDATION",
        "meter_number": meter,
        "meter_type": meter_type.upper(),
        "disco": found["biller_code"],
        **found,
    }
    _cache_set(cache_key, result, 1800)
    return result
