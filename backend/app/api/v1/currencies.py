from fastapi import APIRouter, HTTPException
from typing import List, Optional
from app.currencies.config import INITIAL_CURRENCIES

router = APIRouter(prefix="/currencies", tags=["Global Currencies"])

@router.get("")
def list_currencies():
    """Retrieve all supported ISO 4217 fiat currencies."""
    return {
        "count": len(INITIAL_CURRENCIES),
        "currencies": INITIAL_CURRENCIES
    }

@router.get("/{code}")
def get_currency(code: str):
    """Retrieve currency metadata by ISO code."""
    c_upper = code.upper()
    for curr in INITIAL_CURRENCIES:
        if curr["code"] == c_upper:
            return curr
    raise HTTPException(status_code=404, detail=f"Currency '{code}' not supported")
