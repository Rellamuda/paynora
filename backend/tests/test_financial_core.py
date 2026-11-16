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

        # 2. List Default Wallets (Local NGN + Default Foreign USD & GBP)
        wallets_res = await client.get("/api/v1/wallets", headers=headers)
        assert wallets_res.status_code == 200
        wallets_data = wallets_res.json()
        assert wallets_data["count"] == 3
        currencies = [w["currency"] for w in wallets_data["wallets"]]
        assert "NGN" in currencies
        assert "USD" in currencies
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

        # 5. Verify App-to-App (P2P) lookup, quote, and instant transfer
        lookup_res = await client.get("/api/v1/p2p/lookup?q=@chidi", headers=headers)
        assert lookup_res.status_code == 200
        lookup_data = lookup_res.json()
        assert lookup_data["found"] is True
        assert lookup_data["user_id"] == "usr_demo_chidi"

        p2p_res = await client.post(
            "/api/v1/p2p/transfer",
            json={
                "recipient_user_id": "usr_demo_chidi",
                "source_currency": "USD",
                "amount": "100.00",
                "receive_mode": "ORIGINAL",
                "note": "Test P2P USD transfer"
            },
            headers={**headers, "Idempotency-Key": "test_p2p_usd_100"}
        )
        assert p2p_res.status_code == 201
        p2p_data = p2p_res.json()
        assert p2p_data["type"] == "APP_TO_APP"
        assert p2p_data["state"] == "COMPLETED"
        assert p2p_data["destination_currency"] == "USD"
        assert p2p_data["destination_amount"] == "100.00"
        assert p2p_data["fee"] == "0.00"
