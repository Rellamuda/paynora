# PAYNORA — Global AI-Powered Money Movement & Multi-Currency Financial Core

PayNora is a global, AI-powered money movement, multi-currency digital wallet, cross-border payments, and financial technology platform built with modern modular monorepo architecture.

## Platform Stack
- **Web Application**: Next.js, React, TypeScript, Tailwind CSS
- **Admin Dashboard**: Next.js, React, TypeScript
- **Mobile Application**: Flutter, Dart (iOS & Android)
- **Backend API**: Python 3.10+, FastAPI, Pydantic v2, SQLAlchemy 2.x
- **Databases & Cache**: PostgreSQL (Authoritative Ledger), Redis (Caching & Sessions)
- **Messaging & Events**: Apache Kafka
- **Cloud & IaC**: Amazon Web Services (AWS), Terraform
- **Containerization**: Docker & Docker Compose

## Monorepo Layout
```
paynora/
├── apps/
│   ├── web/              # Customer Next.js Web Dashboard
│   ├── mobile/           # Flutter iOS/Android Cross-Platform App
│   └── admin/            # Operational & Compliance Admin Workspace
├── backend/
│   ├── app/              # FastAPI Financial Core & Services
│   └── tests/            # Pytest Suite (Unit, Integration, Ledger)
├── packages/
│   ├── api-contracts/    # Shared OpenAPI Specs & Endpoints
│   ├── shared-types/     # Shared Data Models & Enums
│   ├── design-tokens/    # Unified Design System Tokens
│   └── ui-guidelines/    # UI/UX & Brand Identity Rules
├── infrastructure/
│   └── terraform/        # AWS Modular Infrastructure as Code
├── docs/                 # Architecture, Security, Ledger & Market Docs
└── docker-compose.yml    # Local Orchestration (FastAPI, Postgres, Redis, Kafka)
```

## Quick Start (Local Development)
1. Copy environment configuration:
   `cp .env.example .env`
2. Launch core infrastructure & backend with Docker Compose:
   `docker-compose up -d --build`
3. Run backend unit & integration tests:
   `docker-compose exec backend pytest`
4. Access applications:
   - FastAPI Backend API Docs: `http://localhost:8000/docs`
   - Web Application: `http://localhost:3000`
   - Admin Workspace: `http://localhost:3001`
