from typing import List, Dict, Any

INITIAL_11_COUNTRIES: List[Dict[str, Any]] = [
    {
        "iso_code": "NG",
        "name": "Nigeria",
        "flag": "🇳🇬",
        "primary_currency": "NGN",
        "supported_currencies": ["NGN", "USD", "GBP"],
        "dialing_code": "+234",
        "is_sending_supported": True,
        "is_receiving_supported": True,
        "is_active": True
    },
    {
        "iso_code": "GB",
        "name": "United Kingdom",
        "flag": "🇬🇧",
        "primary_currency": "GBP",
        "supported_currencies": ["GBP", "EUR", "USD"],
        "dialing_code": "+44",
        "is_sending_supported": True,
        "is_receiving_supported": True,
        "is_active": True
    },
    {
        "iso_code": "US",
        "name": "United States",
        "flag": "🇺🇸",
        "primary_currency": "USD",
        "supported_currencies": ["USD", "CAD"],
        "dialing_code": "+1",
        "is_sending_supported": True,
        "is_receiving_supported": True,
        "is_active": True
    },
    {
        "iso_code": "CA",
        "name": "Canada",
        "flag": "🇨🇦",
        "primary_currency": "CAD",
        "supported_currencies": ["CAD", "USD"],
        "dialing_code": "+1",
        "is_sending_supported": True,
        "is_receiving_supported": True,
        "is_active": True
    },
    {
        "iso_code": "AE",
        "name": "United Arab Emirates",
        "flag": "🇦🇪",
        "primary_currency": "AED",
        "supported_currencies": ["AED", "USD"],
        "dialing_code": "+971",
        "is_sending_supported": True,
        "is_receiving_supported": True,
        "is_active": True
    },
    {
        "iso_code": "GH",
        "name": "Ghana",
        "flag": "🇬🇭",
        "primary_currency": "GHS",
        "supported_currencies": ["GHS", "USD"],
        "dialing_code": "+233",
        "is_sending_supported": True,
        "is_receiving_supported": True,
        "is_active": True
    },
    {
        "iso_code": "ZA",
        "name": "South Africa",
        "flag": "🇿🇦",
        "primary_currency": "ZAR",
        "supported_currencies": ["ZAR", "USD"],
        "dialing_code": "+27",
        "is_sending_supported": True,
        "is_receiving_supported": True,
        "is_active": True
    },
    {
        "iso_code": "DE",
        "name": "Germany",
        "flag": "🇩🇪",
        "primary_currency": "EUR",
        "supported_currencies": ["EUR", "USD"],
        "dialing_code": "+49",
        "is_sending_supported": True,
        "is_receiving_supported": True,
        "is_active": True
    },
    {
        "iso_code": "FR",
        "name": "France",
        "flag": "🇫🇷",
        "primary_currency": "EUR",
        "supported_currencies": ["EUR", "USD"],
        "dialing_code": "+33",
        "is_sending_supported": True,
        "is_receiving_supported": True,
        "is_active": True
    },
    {
        "iso_code": "SA",
        "name": "Saudi Arabia",
        "flag": "🇸🇦",
        "primary_currency": "SAR",
        "supported_currencies": ["SAR", "USD"],
        "dialing_code": "+966",
        "is_sending_supported": True,
        "is_receiving_supported": True,
        "is_active": True
    },
    {
        "iso_code": "CN",
        "name": "China",
        "flag": "🇨🇳",
        "primary_currency": "CNY",
        "supported_currencies": ["CNY", "USD"],
        "dialing_code": "+86",
        "is_sending_supported": True,
        "is_receiving_supported": True,
        "is_active": True
    }
]

def get_active_countries() -> List[Dict[str, Any]]:
    return [c for c in INITIAL_11_COUNTRIES if c["is_active"]]

def get_country_by_iso(iso_code: str) -> Dict[str, Any]:
    iso_upper = iso_code.upper()
    for c in INITIAL_11_COUNTRIES:
        if c["iso_code"] == iso_upper:
            return c
    return None
