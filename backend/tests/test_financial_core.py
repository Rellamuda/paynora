import pytest
import httpx
from decimal import Decimal
from app.main import app
from app.ledger.engine import DoubleEntryLedgerEngine

@pytest.mark.asyncio
async def test_wallet_activation_and_ledger_integrity():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as client:
        # 1. Register & Login
        await client.post("/api/v1/auth/register", json={
            "first_name": "Rella",
            "last_name": "Muda",
            "email": "rella.wallet@example.com",
            "phone": "+2348033445566",
            "country_iso": "NG",
            "password": "SecurePassword2026!"
        })
        login_res = await client.post("/api/v1/auth/login", json={
            "email": "rella.wallet@example.com",
            "password": "SecurePassword2026!"
        })
        token = login_res.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 2. List Default Wallets (NGN and GBP)
        wallets_res = await client.get("/api/v1/wallets", headers=headers)
        assert wallets_res.status_code == 200
        wallets_data = wallets_res.json()
        assert wallets_data["count"] == 2
        currencies = [w["currency"] for w in wallets_data["wallets"]]
        assert "NGN" in currencies
        assert "GBP" in currencies

        # 3. Activate USD Wallet
        act_res = await client.post("/api/v1/wallets", json={"currency": "USD"}, headers=headers)
        assert act_res.status_code == 201
        assert act_res.json()["currency"] == "USD"

        # 4. Verify Double-Entry Accounting Engine for Wallet Funding Transaction
        sender_account_id = wallets_data["wallets"][0]["wallet_id"]
        settlement_account_id = "acc_settlement_asset_001"
        funding_amount = Decimal("500000.00")

        entries = DoubleEntryLedgerEngine.create_transfer_entries(
            sender_account_id=sender_account_id,
            settlement_account_id=settlement_account_id,
            amount=funding_amount,
            currency="NGN"
        )
        assert len(entries) == 2
        # Validate zero-discrepancy balance condition
        assert DoubleEntryLedgerEngine.validate_transaction(entries) is True
