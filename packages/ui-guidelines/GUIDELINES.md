# PAYNORA — UI/UX Design System & Brand Guidelines

## Core Principles
1. **Financial Professionalism & Trust**: Subdued palette, clear typography, explicit state visibility.
2. **Global Accessibility**: Supports Latin, Arabic (RTL), Chinese characters. Locale-aware currency formatting.
3. **Deterministic Financial Confirmation**: Visual transfer steps require double-confirmation with locked quotes.
4. **Platform Parity**: Web (Next.js) and Mobile (Flutter iOS/Android) share design tokens and API contracts.

## Color Tokens
- **Brand Primary**: Deep Navy `#0D253F`
- **Brand Secondary**: Emerald Green `#00C853`
- **Background**: Soft Off-White `#F8FAFC`
- **Surface**: White `#FFFFFF`
- **Text Primary**: Charcoal `#0F172A`

## Component Standards
- Buttons must explicitly indicate loading, disabled, or locked financial execution state.
- Floating-point calculations are strictly forbidden in UI formatting; amounts must render exact decimal values.
