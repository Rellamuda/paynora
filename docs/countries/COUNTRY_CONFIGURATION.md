# PayNora — Global Country & Corridor Configuration Engine

## Initial 11 Active Countries

| Country Name | ISO Code | Primary Currency | Supported Currencies | Status |
|---|---|---|---|---|
| Nigeria 🇳🇬 | NG | NGN | NGN, USD, GBP | ACTIVE |
| United Kingdom 🇬🇧 | GB | GBP | GBP, EUR, USD | ACTIVE |
| United States 🇺🇸 | US | USD | USD, CAD | ACTIVE |
| Canada 🇨🇦 | CA | CAD | CAD, USD | ACTIVE |
| United Arab Emirates 🇦🇪 | AE | AED | AED, USD | ACTIVE |
| Ghana 🇬🇭 | GH | GHS | GHS, USD | ACTIVE |
| South Africa 🇿🇦 | ZA | ZAR | ZAR, USD | ACTIVE |
| Germany DE | DE | EUR | EUR, USD | ACTIVE |
| France 🇫🇷 | FR | EUR | EUR, USD | ACTIVE |
| Saudi Arabia 🇸🇦 | SA | SAR | SAR, USD | ACTIVE |
| China 🇨🇳 | CN | CNY | CNY, USD | ACTIVE |

## Corridor Management Principles
- Corridors are defined explicitly as `(source_country, destination_country)`.
- Initial Priority Corridor: **Nigeria ↔ United Kingdom** (`NG ↔ GB`).
- Corridor execution requires configured payment providers, settlement accounts, compliance policies, and liquidity limits.
