from fastapi import APIRouter, HTTPException, Query
from app.fx.engine import FXEngine

router = APIRouter(prefix="/fx", tags=["Foreign Exchange (FX)"])

@router.get("/quote")
def get_fx_quote(
    source_currency: str = Query("NGN"),
    destination_currency: str = Query("GBP"),
    source_amount: str = Query("1000000")
):
    """Obtain a deterministic, time-locked FX rate quote."""
    try:
        quote = FXEngine.generate_quote(source_currency, destination_currency, source_amount)
        return quote
    except Exception as err:
        raise HTTPException(status_code=400, detail=str(err))
