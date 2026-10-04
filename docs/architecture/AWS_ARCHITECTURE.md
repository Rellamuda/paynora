# PayNora — AWS Cloud Infrastructure Architecture

## Core Services & Topology
- **Edge Routing & Security**: Route 53 -> CloudFront -> AWS WAF -> ACM SSL -> API Gateway -> Application Load Balancer (ALB).
- **Compute Layer**: AWS ECS Fargate hosting containerized FastAPI services, background event workers, and Next.js web applications in private VPC subnets.
- **Database & Persistence**: AWS RDS PostgreSQL Multi-AZ with automated point-in-time recovery, automated backups, and encrypted storage.
- **Cache & Messaging**: AWS ElastiCache for Redis and Amazon MSK (Managed Streaming for Kafka).
- **Object Storage & Security**: Amazon S3 (Encrypted document buckets with short-lived signed URLs), AWS Secrets Manager, AWS KMS, AWS CloudWatch, and AWS CloudTrail.

## Terraform Infrastructure Modules
Infrastructure is managed declaratively under `infrastructure/terraform/` with separate modules for networking, compute, database, cache, security, storage, and CDN.
