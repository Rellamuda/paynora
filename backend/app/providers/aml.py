from typing import Dict, Any

class MockAMLProvider:
    """
    Mock AML and PEP screening provider.
    """
    @staticmethod
    def screen_customer(name: str, country_iso: str) -> Dict[str, Any]:
        if "SANCTION" in name.upper() or "PEP_HIGH" in name.upper():
            return {
                "passed": False,
                "risk_score": 95.0,
                "match_type": "PEP_MATCH",
                "details": "Customer flagged on high-risk watch list."
            }
        return {
            "passed": True,
            "risk_score": 5.0,
            "match_type": "CLEAR",
            "details": "No watch list or PEP matches found."
        }
