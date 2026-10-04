# PayNora — High-Level Architecture Blueprint

## Architectural Overview

PayNora is architected as an event-driven modular monolith with a provider-agnostic financial core.

```
                  PAYNORA WEB APPLICATION
                   React / Next.js / TS
                           │
                           ▼
                    AWS CloudFront
                           │
                           ▼
                        AWS WAF
                           │
                           ▼
                    AWS API Gateway
                           │
                           ▼
                   AWS Application LB
                           │
                           ▼
                     FastAPI Backend
                           ▲
                           │
              HTTPS / REST / OpenAPI
                           │
                           ▼
                  PAYNORA MOBILE APP
                   Flutter / Dart
                    iOS + Android
                           │
                           ▼
                    Financial Core
                           │
       ┌───────────────────┼──────────────────┐
       │                   │                  │
       ▼                   ▼                  ▼
  AI Platform       Compliance / Risk    Payment / FX
       │                   │                  │
       └───────────────────┼──────────────────┘
                           │
                           ▼
                       PostgreSQL
                           │
             ┌─────────────┼─────────────┐
             ▼             ▼             ▼
          Redis          Kafka           S3
             │             │             │
             ▼             ▼             ▼
           Cache       Workers       Documents
```

## System Modules
1. **Core Ledger Module**: Double-entry immutable financial ledger system.
2. **Global Country & Corridor Module**: Dynamic market profiles, 11 initial active countries, eligible transfer corridors.
3. **Identity & KYC Module**: Progressive conversational onboarding, document capture, liveness, AML/Sanctions.
4. **FX Engine**: Fixed-precision decimal FX quote generation and rate locking.
5. **Payment Orchestrator**: Vendor-agnostic abstractions for payments, payouts, and webhooks.
6. **AI Assistant Core**: Typed tools system where AI proposes and backend validates/executes.
7. **Admin Workspace**: Operations, compliance review, reconciliation, and configuration management.
