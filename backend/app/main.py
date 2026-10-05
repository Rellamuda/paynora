from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.api.v1 import (
    health,
    countries,
    corridors,
    currencies,
    transfers,
    auth,
    users,
    onboarding,
    kyc,
    wallets,
    fx,
    beneficiaries,
    ai,
    admin,
    webhooks
)

app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    description="PayNora Global AI-Powered Money Movement & Multi-Currency Platform Core API"
)

# CORS Middleware setup for Next.js & Mobile clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router, prefix="/api/v1")
app.include_router(countries.router, prefix="/api/v1")
app.include_router(corridors.router, prefix="/api/v1")
app.include_router(currencies.router, prefix="/api/v1")
app.include_router(transfers.router, prefix="/api/v1")
app.include_router(auth.router, prefix="/api/v1")
app.include_router(users.router, prefix="/api/v1")
app.include_router(onboarding.router, prefix="/api/v1")
app.include_router(kyc.router, prefix="/api/v1")
app.include_router(wallets.router, prefix="/api/v1")
app.include_router(fx.router, prefix="/api/v1")
app.include_router(beneficiaries.router, prefix="/api/v1")
app.include_router(ai.router, prefix="/api/v1")
app.include_router(admin.router, prefix="/api/v1")
app.include_router(webhooks.router, prefix="/api/v1")

@app.get("/")
def root():
    return {
        "app": settings.APP_NAME,
        "status": "online",
        "documentation": "/docs"
    }
