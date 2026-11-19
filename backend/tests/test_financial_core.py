import pytest
import httpx
from decimal import Decimal
from app.main import app
from app.ledger.engine import DoubleEntryLedgerEngine

@pytest.mark.asyncio
async def test_wallet_activation_and_ledger_integrity(monkeypatch):
    import app.api.v1.bills as bills_mod

    async def fake_verify_meter(meter, meter_type, country_iso, biller_code=None):
        return {
            "status": "VALID",
            "verified": True,
            "method": "TEST_MOCK",
            "meter_number": meter,
            "meter_type": meter_type,
            "disco": "BIL113",
            "biller_code": "BIL113",
            "biller_name": "IKEJA DISCO",
            "disco_name": "Ikeja Electric (IKEDC)",
            "customer_name": "RELLA MUDA",
            "address": "Ikeja, Lagos",
        }

    monkeypatch.setattr(bills_mod, "flw_configured", lambda: False)
    monkeypatch.setattr(bills_mod, "verify_meter", fake_verify_meter)

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

        # 2. List Default Wallets (Strictly 2 wallets: Local NGN + Foreign USD)
        wallets_res = await client.get("/api/v1/wallets", headers=headers)
        assert wallets_res.status_code == 200
        wallets_data = wallets_res.json()
        assert wallets_data["count"] == 2
        currencies = [w["currency"] for w in wallets_data["wallets"]]
        assert currencies == ["NGN", "USD"]

        # 3. Activate USD Wallet
        act_res = await client.post("/api/v1/wallets", json={"currency": "USD"}, headers=headers)
        assert act_res.status_code == 201
        assert act_res.json()["currency"] == "USD"

        # 4. Fund Wallets & Verify Double-Entry Accounting Engine for Wallet Funding Transaction
        await client.post("/api/v1/wallets/fund", json={"currency": "NGN", "amount": "500000.00"}, headers=headers)
        await client.post("/api/v1/wallets/fund", json={"currency": "USD", "amount": "1250.00"}, headers=headers)
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

        # 6. Verify Bill Payments (Airtime, Data, Electricity) deduct from Local Currency Wallet (NGN)
        air_res = await client.post(
            "/api/v1/bills/airtime",
            json={"phone_number": "08031234567", "operator_code": "MTN", "amount": "2000.00", "country_iso": "NG"},
            headers=headers
        )
        assert air_res.status_code == 200
        assert air_res.json()["wallet_balance_after"] == "498000.00"

        pwr_res = await client.post(
            "/api/v1/bills/electricity",
            json={
                "disco_code": "IKEDC",
                "meter_number": "45012345678",
                "meter_type": "PREPAID",
                "amount": "5000.00",
                "customer_name": "RELLA MUDA",
                "country_iso": "NG"
            },
            headers=headers
        )
        assert pwr_res.status_code == 200
        assert pwr_res.json()["wallet_balance_after"] == "493000.00"
        assert len(pwr_res.json()["token"]) >= 24

        # 7. Verify Bank Transfer with account_details deducts wallet balance & disburses payout
        bank_res = await client.post(
            "/api/v1/transfers",
            json={
                "source_currency": "NGN",
                "destination_currency": "NGN",
                "source_amount": "13000.00",
                "recipient_name": "CHUKWUEMEKA OBI",
                "source_country": "NG",
                "destination_country": "NG",
                "recipient_currency_mode": "LOCAL_CURRENCY",
                "payout_method": "LOCAL_BANK",
                "account_details": {"account_number": "0123456789", "bank_code": "044", "institution": "Access Bank"}
            },
            headers={**headers, "Idempotency-Key": "test_local_bank_13000"}
        )
        assert bank_res.status_code == 201
        bank_data = bank_res.json()
        assert bank_data["state"] == "COMPLETED"
        assert bank_data["wallet_balance_after"] == "480000.00"
        assert bank_data["disbursal"]["status"] == "SUCCESS"

        # 8. Verify One-Tap Airtime Reversal (100% refund back to Local Currency Wallet)
        air_tx_id = air_res.json()["transaction_id"]
        rev_res = await client.post(
            "/api/v1/bills/airtime/reverse",
            json={"transaction_id": air_tx_id},
            headers=headers
        )
        assert rev_res.status_code == 200
        assert rev_res.json()["status"] == "REVERSED"
        assert rev_res.json()["refunded_amount"] == "2000.00"
        assert rev_res.json()["wallet_balance_after"] == "482000.00"

        # 9. Verify Airtime-to-Cash Converter (90% cash payout / 10% conversion fee)
        a2c_res = await client.post(
            "/api/v1/bills/airtime-to-cash",
            json={
                "phone_number": "08021234567",
                "operator_code": "AIRTEL",
                "airtime_amount": "10000.00",
                "country_iso": "NG"
            },
            headers=headers
        )
        assert a2c_res.status_code == 200
        a2c_data = a2c_res.json()
        assert a2c_data["status"] == "CONVERTED"
        assert a2c_data["payout_rate"] == "90%"
        assert a2c_data["conversion_fee"] == "1000.00"
        assert a2c_data["cash_credited"] == "9000.00"
        assert a2c_data["wallet_balance_after"] == "491000.00"
