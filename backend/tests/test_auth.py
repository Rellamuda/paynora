import pytest
import httpx
from app.main import app

@pytest.mark.asyncio
async def test_user_registration_and_login_flow():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as client:
        # 1. Register User
        reg_payload = {
            "first_name": "Rella",
            "last_name": "Muda",
            "email": "rella@example.com",
            "phone": "+2348012345678",
            "country_iso": "NG",
            "password": "SecurePassword2026!"
        }
        reg_res = await client.post("/api/v1/auth/register", json=reg_payload)
        assert reg_res.status_code == 201
        reg_data = reg_res.json()
        assert reg_data["email"] == "rella@example.com"
        assert reg_data["first_name"] == "Rella"
        assert "user_id" in reg_data

        # 2. Verify OTP
        otp_res = await client.post("/api/v1/auth/verify-otp", json={"email": "rella@example.com", "otp_code": "123456"})
        assert otp_res.status_code == 200
        assert otp_res.json()["status"] == "verified"

        # 3. Login
        login_res = await client.post("/api/v1/auth/login", json={"email": "rella@example.com", "password": "SecurePassword2026!"})
        assert login_res.status_code == 200
        login_data = login_res.json()
        assert "access_token" in login_data
        token = login_data["access_token"]

        # 4. Fetch authenticated user profile
        headers = {"Authorization": f"Bearer {token}"}
        me_res = await client.get("/api/v1/users/me", headers=headers)
        assert me_res.status_code == 200
        me_data = me_res.json()
        assert me_data["email"] == "rella@example.com"
        assert me_data["is_email_verified"] is True
