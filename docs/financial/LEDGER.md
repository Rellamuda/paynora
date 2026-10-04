# PayNora — Immutable Double-Entry Ledger System

## Accounting Primitives
Money movement in PayNora strictly follows double-entry bookkeeping rules:
$$\sum \text{Debits} = \sum \text{Credits}$$

### Non-Negotiable Rules:
1. **No Direct Mutation**: Balances are NEVER updated using direct `balance += x` or `balance -= x`.
2. **Immutable Entries**: Ledger transactions and entries are strictly append-only. No deletion or updating of posted transactions.
3. **Compensating Transactions**: Errors or refunds are handled strictly via new compensating ledger transactions.
4. **Fixed Precision Arithmetic**: All financial calculations use Python `Decimal` / Postgres `NUMERIC(28, 8)` to prevent floating-point rounding errors.

### Account Types:
- `ASSET`: Settlement provider accounts, bank accounts.
- `LIABILITY`: Customer wallet liability accounts.
- `REVENUE`: Fee revenue accounts.
- `EXPENSE`: Provider processing fee accounts.
