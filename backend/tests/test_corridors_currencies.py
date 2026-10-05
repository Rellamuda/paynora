import pytest
import httpx
from app.main import app

@pytest.mark.asyncio
async def test_corridors_and_currencies_catalog():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as client:
        # 1. Corridors
        res_crd = await client.get("/api/v1/corridors")
        assert res_crd.status_code == 200
        data_crd = res_crd.json()
        assert data_crd["count"] >= 11
        assert any(c["corridor_id"] == "crd_ng_gb" for c in data_crd["corridors"])

        # 2. Single Corridor
        res_single = await client.get("/api/v1/corridors/crd_ng_gb")
        assert res_single.status_code == 200
        assert res_single.json()["source_currency"] == "NGN"

        # 3. Currencies
        res_curr = await client.get("/api/v1/currencies")
        assert res_curr.status_code == 200
        data_curr = res_curr.json()
        assert data_curr["count"] == 10
        codes = [c["code"] for c in data_curr["currencies"]]
        assert "NGN" in codes
        assert "GBP" in codes
        assert "USD" in codes

@pytest.mark.asyncio
async def test_recipient_currency_mode_and_webhooks():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as client:
        # 1. Create transfer with CHOICE mode
        tx_res = await client.post("/api/v1/transfers", json={
            "source_currency": "NGN",
            "source_amount": "50000.00",
            "recipient_name": "David Adeleke",
            "source_country": "NG",
            "destination_country": "GB",
            "recipient_currency_mode": "CHOICE"
        }, headers={"Idempotency-Key": "test_choice_01"})
        assert tx_res.status_code == 201
        tx_id = tx_res.json()["transfer_id"]

        # 2. Recipient selects GBP payout
        choice_res = await client.post(f"/api/v1/transfers/{tx_id}/recipient-currency", json={
            "selected_currency": "GBP",
            "payout_method": "UK_FASTER_PAYMENTS"
        })
        assert choice_res.status_code == 200
        assert choice_res.json()["selected_currency"] == "GBP"

        # 3. Webhook idempotency test
        wh_res = await client.post("/api/v1/webhooks/mock_payment", json={
            "event_id": "wh_evt_998877",
            "event_type": "payment.succeeded",
            "data": {"transfer_id": tx_id, "amount": "50000.00"}
        })
        assert wh_res.status_code == 200
        assert wh_res.json()["status"] == "RECEIVED"

        # Duplicate webhook must return ALREADY_PROCESSED
        wh_dup = await client.post("/api/v1/webhooks/mock_payment", json={
            "event_id": "wh_evt_998877",
            "event_type": "payment.succeeded",
            "data": {"transfer_id": tx_id, "amount": "50000.00"}
        })
        assert wh_dup.status_code == 200
        assert wh_dup.json()["status"] == "ALREADY_PROCESSED"
