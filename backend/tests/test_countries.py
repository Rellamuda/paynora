import pytest
import httpx
from app.main import app

@pytest.mark.asyncio
async def test_list_active_countries():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as client:
        response = await client.get("/api/v1/countries/active")
        assert response.status_code == 200
        data = response.json()
        assert data["active_countries_count"] == 11
        iso_codes = [c["iso_code"] for c in data["countries"]]
        assert "NG" in iso_codes
        assert "GB" in iso_codes
        assert "US" in iso_codes
        assert "CN" in iso_codes

@pytest.mark.asyncio
async def test_get_specific_country():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as client:
        response = await client.get("/api/v1/countries/NG")
        assert response.status_code == 200
        country = response.json()
        assert country["name"] == "Nigeria"
        assert country["primary_currency"] == "NGN"
