import pytest
import httpx
from app.main import app

@pytest.mark.asyncio
async def test_onboarding_and_kyc_verification_flow():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as client:
        # 1. Register and Login
        await client.post("/api/v1/auth/register", json={
            "first_name": "Rella",
            "last_name": "Muda",
            "email": "rella.kyc@example.com",
            "phone": "+2348099887766",
            "country_iso": "NG",
            "password": "SecurePassword2026!"
        })
        login_res = await client.post("/api/v1/auth/login", json={
            "email": "rella.kyc@example.com",
            "password": "SecurePassword2026!"
        })
        token = login_res.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 2. Check initial KYC status (NOT_STARTED -> VIEW_ACCOUNT)
        status_res = await client.get("/api/v1/kyc/status", headers=headers)
        assert status_res.status_code == 200
        assert status_res.json()["kyc_status"] == "NOT_STARTED"
        assert "VIEW_ACCOUNT" in status_res.json()["capabilities"]

        # 3. Submit Onboarding Steps
        step_res = await client.post("/api/v1/onboarding/step", json={
            "step_id": "residence_country",
            "answer": "NG"
        }, headers=headers)
        assert step_res.status_code == 200

        # 4. Perform Mock Identity Verification (APPROVED -> Expands Capabilities)
        verify_res = await client.post("/api/v1/kyc/verify", json={
            "document_type": "NATIONAL_ID",
            "document_number": "NIN123456789"
        }, headers=headers)
        assert verify_res.status_code == 200
        verify_data = verify_res.json()
        assert verify_data["kyc_status"] == "APPROVED"
        assert "SEND_MONEY" in verify_data["capabilities"]
        assert "EXCHANGE_CURRENCY" in verify_data["capabilities"]
