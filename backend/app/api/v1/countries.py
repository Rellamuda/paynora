from fastapi import APIRouter, HTTPException
from app.countries.config import get_active_countries, get_country_by_iso

router = APIRouter(prefix="/countries", tags=["Countries & Corridors"])

@router.get("/active")
def list_active_countries():
    """Retrieve 11 initial active operating countries."""
    countries = get_active_countries()
    return {
        "active_countries_count": len(countries),
        "countries": countries
    }

@router.get("/{iso_code}")
def get_country(iso_code: str):
    country = get_country_by_iso(iso_code)
    if not country:
        raise HTTPException(status_code=404, detail="Country configuration not found")
    return country
