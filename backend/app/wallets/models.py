from decimal import Decimal
from typing import Dict, Any, List
import uuid
from app.storage import load_section, save_section

# Persistent wallet store (survives container rebuilds & server restarts)
USER_WALLETS: Dict[str, List[Dict[str, Any]]] = load_section("user_wallets", {})


def persist_wallets_db() -> None:
    save_section("user_wallets", USER_WALLETS)

# Default foreign currency options (USD primary; GBP when local currency is already USD)
DEFAULT_FOREIGN_CURRENCIES = ["USD", "GBP"]

# Global ISO-3166 Alpha-2 Country -> Official ISO-4217 Local Currency Registry (All World Regions)
COUNTRY_LOCAL_CURRENCY: Dict[str, str] = {
    # Africa
    "NG": "NGN", "GH": "GHS", "KE": "KES", "ZA": "ZAR", "EG": "EGP", "RW": "RWF", "TZ": "TZS", "UG": "UGX",
    "ZM": "ZMW", "ZW": "USD", "MA": "MAD", "DZ": "DZD", "TN": "TND", "ET": "ETB", "AO": "AOA", "MZ": "MZN",
    "BW": "BWP", "NA": "NAD", "MU": "MUR", "SC": "SCR", "GM": "GMD", "SL": "SLL", "LR": "LRD", "GN": "GNF",
    "MW": "MWK", "LS": "LSL", "SZ": "SZL", "MG": "MGA", "CD": "CDF", "SD": "SDG", "SS": "SSP", "LY": "LYD",
    "MR": "MRU", "SO": "SOS", "DJ": "DJF", "ER": "ERN", "BI": "BIF", "CV": "CVE", "ST": "STN", "KM": "KMF",
    # Francophone West Africa (XOF) & Central Africa (XAF)
    "SN": "XOF", "CI": "XOF", "BF": "XOF", "ML": "XOF", "NE": "XOF", "TG": "XOF", "BJ": "XOF", "GW": "XOF",
    "CM": "XAF", "GA": "XAF", "CG": "XAF", "TD": "XAF", "CF": "XAF", "GQ": "XAF",
    # Europe
    "GB": "GBP", "CH": "CHF", "NO": "NOK", "SE": "SEK", "DK": "DKK", "PL": "PLN", "CZ": "CZK", "HU": "HUF",
    "RO": "RON", "BG": "BGN", "IS": "ISK", "UA": "UAH", "RS": "RSD", "BA": "BAM", "AL": "ALL", "MK": "MKD",
    "MD": "MDL", "GE": "GEL", "AM": "AMD", "AZ": "AZN", "BY": "BYN", "TR": "TRY", "RU": "RUB",
    # Eurozone (EUR)
    "DE": "EUR", "FR": "EUR", "IT": "EUR", "ES": "EUR", "NL": "EUR", "BE": "EUR", "AT": "EUR", "IE": "EUR",
    "PT": "EUR", "FI": "EUR", "GR": "EUR", "LU": "EUR", "MT": "EUR", "CY": "EUR", "EE": "EUR", "LV": "EUR",
    "LT": "EUR", "SK": "EUR", "SI": "EUR", "HR": "EUR", "AD": "EUR", "MC": "EUR", "SM": "EUR", "VA": "EUR",
    # Americas
    "US": "USD", "CA": "CAD", "MX": "MXN", "BR": "BRL", "AR": "ARS", "CL": "CLP", "CO": "COP", "PE": "PEN",
    "UY": "UYU", "PY": "PYG", "BO": "BOB", "VES": "VES", "VE": "VES", "EC": "USD", "SV": "USD", "PA": "USD",
    "CR": "CRC", "GT": "GTQ", "HN": "HNL", "NI": "NIO", "DO": "DOP", "JM": "JMD", "TT": "TTD", "BB": "BBD",
    "BS": "BSD", "BZ": "BZD", "GY": "GYD", "SR": "SRD", "HT": "HTG", "CU": "CUP", "PR": "USD",
    # Middle East
    "AE": "AED", "SA": "SAR", "QA": "QAR", "KW": "KWD", "BH": "BHD", "OM": "OMR", "JO": "JOD", "IL": "ILS",
    "LB": "LBP", "IQ": "IQD", "IR": "IRR", "YE": "YER", "SY": "SYP",
    # Asia & Oceania
    "CN": "CNY", "IN": "INR", "JP": "JPY", "KR": "KRW", "SG": "SGD", "HK": "HKD", "TW": "TWD", "MY": "MYR",
    "TH": "THB", "ID": "IDR", "PH": "PHP", "VN": "VND", "PK": "PKR", "BD": "BDT", "LK": "LKR", "NP": "NPR",
    "MM": "MMK", "KH": "KHR", "LA": "LAK", "MN": "MNT", "KZ": "KZT", "UZ": "UZS", "KG": "KGS", "TJ": "TJS",
    "TM": "TMT", "AF": "AFN", "BN": "BND", "MV": "MVR", "BT": "BTN", "TL": "USD",
    "AU": "AUD", "NZ": "NZD", "FJ": "FJD", "PG": "PGK", "WS": "WST", "TO": "TOP", "VU": "VUV", "SB": "SBD",
}

DEMO_SEED_BALANCES = {"NGN": "500000.00", "USD": "1250.00", "GBP": "800.00"}
REVIEWER_USER_ID = "usr_store_reviewer"


def resolve_local_currency(user_id: str) -> str:
    """Derive the user's local currency from their registered country of residence (defaults to NGN)."""
    try:
        from app.auth.store import USERS_DB
        user = USERS_DB.get(user_id) or {}
        country_iso = (user.get("country_iso") or "NG").upper()
        return COUNTRY_LOCAL_CURRENCY.get(country_iso, "USD")
    except Exception:
        return "NGN"


def resolve_foreign_currency(local_currency: str) -> str:
    """
    Universal 2-Wallet Rule:
    - Every country user whose local currency is not USD gets USD as their foreign currency wallet.
    - USA (and any country whose local currency is already USD) gets GBP as their foreign currency wallet.
    """
    return "GBP" if (local_currency or "").upper() == "USD" else "USD"


class WalletEngine:
    """
    SendMoni Global Double-Currency Wallet Engine:
    Every user in every country of the world is provisioned strictly TWO wallets:
    1. Their Country of Residence's Local Currency (e.g., NGN, GHS, KES, GBP, EUR, CAD, INR, BRL, etc.)
    2. USD as their Foreign Currency Wallet (or GBP if their local currency is already USD, e.g. USA residents).
    """

    @staticmethod
    def initialize_default_wallets(user_id: str, primary_currency: str = None) -> List[Dict[str, Any]]:
        local_curr = (primary_currency or resolve_local_currency(user_id)).upper()
        foreign_curr = resolve_foreign_currency(local_curr)
        currencies = [local_curr, foreign_curr]
        allowed = set(currencies)

        is_reviewer = user_id == REVIEWER_USER_ID
        if user_id not in USER_WALLETS:
            USER_WALLETS[user_id] = [
                {
                    "wallet_id": f"wlt_{uuid.uuid4().hex[:10]}",
                    "user_id": user_id,
                    "currency": curr,
                    "available_balance": DEMO_SEED_BALANCES.get(curr, "2500.00") if is_reviewer else "0.00",
                    "pending_balance": "0.00",
                    "status": "ACTIVE",
                    "is_local": curr == local_curr,
                    "wallet_role": "LOCAL" if curr == local_curr else "FOREIGN",
                    "created_at": "2026-10-04T11:40:00Z"
                }
                for curr in currencies
            ]
            persist_wallets_db()
        else:
            # Strictly enforce the 2-wallet invariant: Local + Foreign (USD, or GBP for US users)
            USER_WALLETS[user_id] = [w for w in USER_WALLETS[user_id] if w["currency"] in allowed]
            existing = {w["currency"] for w in USER_WALLETS[user_id]}
            changed = False
            for curr in currencies:
                if curr not in existing:
                    USER_WALLETS[user_id].append({
                        "wallet_id": f"wlt_{uuid.uuid4().hex[:10]}",
                        "user_id": user_id,
                        "currency": curr,
                        "available_balance": DEMO_SEED_BALANCES.get(curr, "0.00") if is_reviewer else "0.00",
                        "pending_balance": "0.00",
                        "status": "ACTIVE",
                        "is_local": curr == local_curr,
                        "wallet_role": "LOCAL" if curr == local_curr else "FOREIGN",
                        "created_at": "2026-10-04T11:40:00Z"
                    })
                    changed = True
            if changed:
                persist_wallets_db()
        return USER_WALLETS[user_id]

    @staticmethod
    def get_user_wallets(user_id: str, primary_currency: str = None) -> List[Dict[str, Any]]:
        return WalletEngine.initialize_default_wallets(user_id, primary_currency)

    @staticmethod
    def activate_currency_wallet(user_id: str, currency: str) -> Dict[str, Any]:
        """In the Double Currency architecture, users hold their Local Currency and Foreign (USD/GBP) wallets."""
        wallets = WalletEngine.get_user_wallets(user_id)
        currency_upper = currency.upper()
        for w in wallets:
            if w["currency"] == currency_upper:
                return w
        for w in wallets:
            if w["currency"] in ("USD", "GBP"):
                return w
        return wallets[0]

    @staticmethod
    def fund_wallet(user_id: str, currency: str, amount: str) -> Dict[str, Any]:
        wallets = WalletEngine.get_user_wallets(user_id)
        currency_upper = currency.upper()
        add_amount = Decimal(amount)

        target_wallet = None
        for w in wallets:
            if w["currency"] == currency_upper:
                target_wallet = w
                break

        if not target_wallet:
            for w in wallets:
                if w["currency"] in ("USD", "GBP"):
                    target_wallet = w
                    break
            if not target_wallet:
                target_wallet = wallets[0]

        current_bal = Decimal(target_wallet["available_balance"])
        target_wallet["available_balance"] = f"{(current_bal + add_amount):.2f}"
        persist_wallets_db()
        return target_wallet

    @staticmethod
    def convert_wallet_currency(
        user_id: str,
        from_currency: str,
        to_currency: str,
        from_amount: str,
        to_amount: str
    ) -> Dict[str, Any]:
        wallets = WalletEngine.get_user_wallets(user_id)
        f_curr = from_currency.upper()
        t_curr = to_currency.upper()
        f_amt = Decimal(from_amount)
        t_amt = Decimal(to_amount)

        source_wallet = None
        for w in wallets:
            if w["currency"] == f_curr:
                source_wallet = w
                break

        if not source_wallet or Decimal(source_wallet["available_balance"]) < f_amt:
            raise ValueError(f"Insufficient {f_curr} balance")

        dest_wallet = None
        for w in wallets:
            if w["currency"] == t_curr:
                dest_wallet = w
                break

        if not dest_wallet:
            raise ValueError(f"Destination wallet {t_curr} not available in double-currency configuration")

        source_wallet["available_balance"] = f"{(Decimal(source_wallet['available_balance']) - f_amt):.2f}"
        dest_wallet["available_balance"] = f"{(Decimal(dest_wallet['available_balance']) + t_amt):.2f}"
        persist_wallets_db()

        return {
            "source_wallet": source_wallet,
            "destination_wallet": dest_wallet,
            "from_currency": f_curr,
            "to_currency": t_curr,
            "from_amount": str(f_amt),
            "to_amount": str(t_amt)
        }
