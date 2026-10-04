import pytest
import httpx
from app.main import app

@pytest.mark.asyncio
async def test_fx_quote_and_beneficiary_flow():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as client:
        # 1. Fetch FX Quote NGN -> GBP for 1,000,000 NGN
        fx_res = await client.get("/api/v1/fx/quote?source_currency=NGN&destination_currency=GBP&source_amount=1000000")
        assert fx_res.status_code == 200
        quote_data = fx_res.json()
        assert quote_data["source_currency"] == "NGN"
        assert quote_data["destination_currency"] == "GBP"
        assert "quote_id" in quote_data
        assert quote_data["fee"] == "5000.00"

        # 2. Register User
        await client.post("/api/v1/auth/register", json={
            "first_name": "Rella",
            "last_name": "Muda",
            "email": "rella.fx@example.com",
            "phone": "+2348077665544",
            "country_iso": "NG",
            "password": "SecurePassword2026!"
        })
        login_res = await client.post("/api/v1/auth/login", json={
            "email": "rella.fx@example.com",
            "password": "SecurePassword2026!"
        })
        token = login_res.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 3. Add Beneficiary in London (GB)
        ben_res = await client.post("/api/v1/beneficiaries", json={
            "name": "John London",
            "country_iso": "GB",
            "currency": "GBP",
            "account_details": {"sort_code": "20-40-60", "account_number": "11223344"}
        }, headers=headers)
        assert ben_res.status_code == 201
        ben_data = ben_res.json()
        assert ben_data["name"] == "John London"

        # 4. Create Idempotent Transfer Intent (NGN -> GBP)
        trf_res = await client.post(
            "/api/v1/transfers",
            json={
                "source_currency": "NGN",
                "source_amount": "1000000",
                "recipient_name": "John London",
                "source_country": "NG",
                "destination_country": "GB",
                "recipient_currency_mode": "CHOICE"
            },
            headers={"Idempotency-Key": "idemp_key_test_fx_12345", **headers}
        )
        assert trf_res.status_code == 201
        trf_data = trf_res.json()
        assert trf_data["source_currency"] == "NGN"
        assert trf_data["recipient_currency_mode"] == "CHOICE"
