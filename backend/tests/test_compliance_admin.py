import pytest
import httpx
from decimal import Decimal
from app.main import app
from app.compliance.risk_engine import RiskPolicyEngine
from app.reconciliation.engine import ReconciliationEngine

@pytest.mark.asyncio
async def test_compliance_risk_and_admin_audit_flow():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as client:
        # 1. Evaluate Risk Engine for High-Value Transaction
        risk_res = RiskPolicyEngine.evaluate_transaction_risk(
            user_id="usr_test_1",
            amount=Decimal("6000000.00"),
            currency="NGN",
            source_country="NG",
            destination_country="GB",
            kyc_status="NOT_STARTED"
        )
        assert risk_res["risk_level"] == "HIGH"
        assert risk_res["requires_manual_review"] is True

        # 2. Test Reconciliation Discrepancy Detection Engine
        rec_res = ReconciliationEngine.reconcile_transaction(
            internal_transfer_id="trf_999",
            internal_amount=Decimal("100000.00"),
            provider_amount=Decimal("95000.00"),  # Discrepancy!
            internal_currency="NGN",
            provider_currency="NGN"
        )
        assert rec_res["status"] == "DISCREPANCY_DETECTED"
        assert "Amount mismatch" in rec_res["mismatch_reason"]

        # 3. Register & Login as Admin
        await client.post("/api/v1/auth/register", json={
            "first_name": "Admin",
            "last_name": "Officer",
            "email": "admin.compliance@example.com",
            "phone": "+2348000000000",
            "country_iso": "NG",
            "password": "SecureAdminPassword2026!"
        })
        login_res = await client.post("/api/v1/auth/login", json={
            "email": "admin.compliance@example.com",
            "password": "SecureAdminPassword2026!"
        })
        token = login_res.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 4. Fetch Customer List via Admin Endpoint
        cust_res = await client.get("/api/v1/admin/customers", headers=headers)
        assert cust_res.status_code == 200
        assert cust_res.json()["count"] >= 1

        # 5. Fetch Reconciliation Cases via Admin Endpoint
        rec_cases_res = await client.get("/api/v1/admin/reconciliation/cases", headers=headers)
        assert rec_cases_res.status_code == 200
        assert rec_cases_res.json()["count"] >= 1

        # 6. Fetch Audit Logs
        audit_res = await client.get("/api/v1/admin/audit/logs", headers=headers)
        assert audit_res.status_code == 200
        assert "logs" in audit_res.json()
