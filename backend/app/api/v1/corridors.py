from fastapi import APIRouter, HTTPException, Query, status
from typing import List, Optional
from pydantic import BaseModel
from app.corridors.engine import CorridorEngine, CorridorLifecycle

router = APIRouter(prefix="/corridors", tags=["Global Corridors"])

class CorridorStatusUpdate(BaseModel):
    status: CorridorLifecycle

@router.get("")
def list_corridors(
    source_country: Optional[str] = Query(None, description="Filter by source country ISO"),
    destination_country: Optional[str] = Query(None, description="Filter by destination country ISO")
):
    """
    List all configured payment and remittance corridors.
    """
    corridors = CorridorEngine.get_all_corridors()
    if source_country:
        corridors = [c for c in corridors if c["source_country"] == source_country.upper()]
    if destination_country:
        corridors = [c for c in corridors if c["destination_country"] == destination_country.upper()]

    return {
        "count": len(corridors),
        "corridors": corridors
    }

@router.get("/{corridor_id}")
def get_corridor(corridor_id: str):
    """Get single corridor configuration and rails."""
    for c in CorridorEngine.get_all_corridors():
        if c["corridor_id"] == corridor_id:
            return c
    raise HTTPException(status_code=404, detail="Corridor not found")

@router.patch("/{corridor_id}/status")
def update_corridor_lifecycle(corridor_id: str, payload: CorridorStatusUpdate):
    """Administrative activation/suspension of payment corridors."""
    updated = CorridorEngine.update_corridor_status(corridor_id, payload.status)
    if not updated:
        raise HTTPException(status_code=404, detail="Corridor not found")
    return {"status": "SUCCESS", "corridor": updated}
