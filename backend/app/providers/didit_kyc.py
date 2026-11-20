"""
Live Biometric KYC & ID Verification via Didit v3 API (https://verification.didit.me).
Runs:
  1. POST /v3/id-verification/   -> Document authenticity & OCR extraction
  2. POST /v3/passive-liveness/  -> Live selfie anti-spoofing / liveness check
  3. POST /v3/face-match/        -> 1:1 biometric comparison between selfie & ID photo
"""
import asyncio
import base64
import uuid
from typing import Any, Dict, Optional

import httpx

from app.config import settings

DIDIT_BASE_URL = "https://verification.didit.me/v3"


def _decode_b64_image(data: Optional[str]) -> Optional[bytes]:
    if not data:
        return None
    raw = data.split(",", 1)[-1].strip()
    try:
        return base64.b64decode(raw, validate=False)
    except Exception:
        return None


def didit_configured() -> bool:
    return bool(settings.DIDIT_API_KEY and settings.DIDIT_API_KEY.strip())


class DiditKYCProvider:
    @staticmethod
    async def verify_kyc(
        user_id: str,
        document_type: str,
        document_number: str,
        id_image_base64: Optional[str],
        selfie_image_base64: Optional[str],
    ) -> Dict[str, Any]:
        api_key = settings.DIDIT_API_KEY.strip()
        id_bytes = _decode_b64_image(id_image_base64)
        selfie_bytes = _decode_b64_image(selfie_image_base64)
        if not id_bytes or not selfie_bytes:
            return {
                "session_id": f"didit_{uuid.uuid4().hex[:10]}",
                "status": "REJECTED",
                "provider": "DIDIT_LIVE",
                "reason": "Both a clear Government ID photo and a live selfie photo are required.",
                "liveness_score": 0.0,
                "face_match_score": 0.0,
            }

        headers = {"x-api-key": api_key}
        async with httpx.AsyncClient(timeout=30.0) as client:
            id_task = client.post(
                f"{DIDIT_BASE_URL}/id-verification/",
                headers=headers,
                files={"front_image": ("id_front.jpg", id_bytes, "image/jpeg")},
            )
            liveness_task = client.post(
                f"{DIDIT_BASE_URL}/passive-liveness/",
                headers=headers,
                files={"user_image": ("selfie.jpg", selfie_bytes, "image/jpeg")},
                data={"vendor_data": user_id},
            )
            match_task = client.post(
                f"{DIDIT_BASE_URL}/face-match/",
                headers=headers,
                files={
                    "user_image": ("selfie.jpg", selfie_bytes, "image/jpeg"),
                    "ref_image": ("id_front.jpg", id_bytes, "image/jpeg"),
                },
            )
            id_resp, live_resp, match_resp = await asyncio.gather(
                id_task, liveness_task, match_task, return_exceptions=True
            )

        def _json(resp: Any) -> Dict[str, Any]:
            if isinstance(resp, Exception):
                return {"_error": str(resp)}
            try:
                return resp.json()
            except Exception:
                return {"_error": f"HTTP {resp.status_code}"}

        id_data = _json(id_resp)
        live_data = _json(live_resp)
        match_data = _json(match_resp)

        # Parse Didit ID Verification
        id_info = id_data.get("id_verification") or id_data
        id_status = str(id_info.get("status") or "").lower()

        # Parse Didit Passive Liveness
        live_info = live_data.get("liveness") or live_data
        live_status = str(live_info.get("status") or "").lower()
        liveness_score = float(live_info.get("score") or live_info.get("liveness_score") or (95.0 if live_status == "approved" else 0.0))

        # Parse Didit Face Match 1:1
        match_info = match_data.get("face_match") or match_data
        match_status = str(match_info.get("status") or "").lower()
        face_match_score = float(match_info.get("score") or match_info.get("similarity") or (95.0 if match_status == "approved" else 0.0))

        reasons = []
        if id_status and id_status != "approved":
            reasons.append(f"ID check: {id_info.get('status')} ({id_info.get('reason') or 'document not verified'})")
        elif "_error" in id_data or (not isinstance(id_resp, Exception) and id_resp.status_code >= 400):
            reasons.append(f"ID check failed: {id_data.get('detail') or id_data.get('message') or id_data.get('_error')}")

        if live_status and live_status != "approved":
            reasons.append(f"Liveness check: {live_info.get('status')}")
        elif "_error" in live_data or (not isinstance(live_resp, Exception) and live_resp.status_code >= 400):
            reasons.append(f"Liveness check failed: {live_data.get('detail') or live_data.get('message') or live_data.get('_error')}")

        if match_status and match_status != "approved":
            reasons.append(f"Face match: {match_info.get('status')} (score {face_match_score:.0f}%)")
        elif "_error" in match_data or (not isinstance(match_resp, Exception) and match_resp.status_code >= 400):
            reasons.append(f"Face match failed: {match_data.get('detail') or match_data.get('message') or match_data.get('_error')}")

        session_id = id_data.get("request_id") or live_data.get("request_id") or f"didit_{uuid.uuid4().hex[:10]}"

        if reasons:
            return {
                "session_id": session_id,
                "status": "REJECTED",
                "provider": "DIDIT_LIVE",
                "reason": "; ".join(reasons),
                "liveness_score": round(liveness_score / 100.0 if liveness_score > 1 else liveness_score, 2),
                "face_match_score": round(face_match_score / 100.0 if face_match_score > 1 else face_match_score, 2),
            }

        return {
            "session_id": session_id,
            "status": "APPROVED",
            "provider": "DIDIT_LIVE",
            "reason": "Government ID, passive liveness, and 1:1 selfie face match verified by Didit.",
            "liveness_score": round(liveness_score / 100.0 if liveness_score > 1 else liveness_score, 2),
            "face_match_score": round(face_match_score / 100.0 if face_match_score > 1 else face_match_score, 2),
            "extracted_document": {
                "first_name": id_info.get("first_name"),
                "last_name": id_info.get("last_name"),
                "document_type": id_info.get("document_type") or document_type,
                "document_number": id_info.get("document_number") or document_number,
                "nationality": id_info.get("nationality"),
            },
        }
