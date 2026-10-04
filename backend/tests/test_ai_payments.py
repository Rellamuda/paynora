import pytest
import httpx
from app.main import app

@pytest.mark.asyncio
async def test_ai_natural_language_transfer_intent():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as client:
        # 1. Register & Login User
        await client.post("/api/v1/auth/register", json={
            "first_name": "Rella",
            "last_name": "Muda",
            "email": "rella.ai@example.com",
            "phone": "+2348055443322",
            "country_iso": "NG",
            "password": "SecurePassword2026!"
        })
        login_res = await client.post("/api/v1/auth/login", json={
            "email": "rella.ai@example.com",
            "password": "SecurePassword2026!"
        })
        token = login_res.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 2. Test AI prompt: "Send ₦1,000,000 to John in London"
        ai_res = await client.post("/api/v1/ai/chat", json={
            "prompt": "Send ₦1,000,000 to John in London"
        }, headers=headers)

        assert ai_res.status_code == 200
        data = ai_res.json()
        assert data["intent"] == "PROPOSE_TRANSFER"
        assert data["requires_confirmation"] is True
        action = data["proposed_action"]
        assert action["source_amount"] == "1000000"
        assert action["recipient_name"] == "John in London"
        assert "fx_quote" in action
        assert action["fx_quote"]["source_currency"] == "NGN"
        assert action["fx_quote"]["destination_currency"] == "GBP"

        # 3. Test AI prompt for Balance inquiry
        bal_res = await client.post("/api/v1/ai/chat", json={
            "prompt": "How much is my wallet balance?"
        }, headers=headers)
        assert bal_res.status_code == 200
        bal_data = bal_res.json()
        assert bal_data["intent"] == "INQUIRE_BALANCE"
        assert bal_data["requires_confirmation"] is False
