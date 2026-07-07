# 🏗️ Architecture & Design Decisions

## Overview

This document describes the architectural approach, resource design, and key decisions
made in this CloudFormation lab.

---

## S3 Bucket Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Account                              │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                  CloudFormation Stack                     │  │
│  │                                                           │  │
│  │   ┌─────────────────────┐    ┌────────────────────────┐  │  │
│  │   │    Main S3 Bucket   │───▶│  Access Logs Bucket    │  │  │
│  │   │                     │    │                        │  │  │
│  │   │  ✅ Versioning ON   │    │  ✅ Versioning ON      │  │  │
│  │   │  ✅ SSE-AES256      │    │  ✅ SSE-AES256         │  │  │
│  │   │  ✅ Public blocked  │    │  ✅ Public blocked     │  │  │
│  │   │  ✅ HTTPS enforced  │    │  ✅ 90-day expiry      │  │  │
│  │   │  ✅ Lifecycle rules │    │  ✅ HTTPS enforced     │  │  │
│  │   └─────────────────────┘    └────────────────────────┘  │  │
│  │                                                           │  │
│  │   ┌──────────────────────────────────────────────────┐   │  │
│  │   │              Bucket Policies (x2)                │   │  │
│  │   │  - Deny HTTP (enforce TLS/HTTPS)                 │   │  │
│  │   │  - Allow S3 Log Delivery (logs bucket only)      │   │  │
│  │   └──────────────────────────────────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Key Design Decisions

### 1. Separate Access Logs Bucket
Logs are written to a dedicated bucket (`<bucket-name>-access-logs`) rather than
the same bucket. This prevents circular logging, keeps data and logs separated,
and allows independent lifecycle policies for logs.

### 2. DeletionPolicy: Retain
Both buckets use `DeletionPolicy: Retain`. This means if the CloudFormation stack
is deleted, the S3 buckets are **not** automatically deleted. This protects against
accidental data loss in production. Change to `Delete` for dev/test environments.

### 3. Change Sets Over Direct Deploys
The `deploy.sh` script always uses CloudFormation Change Sets instead of direct
`create-stack`/`update-stack` calls. This provides a review step before any
infrastructure change is applied — a critical practice in production environments.

### 4. No KMS Key (Yet)
The template uses SSE-S3 (AES-256) instead of SSE-KMS for simplicity. SSE-KMS
provides additional control (key rotation, access audit via CloudTrail) and is
recommended for highly sensitive data. Upgrading is straightforward — change
`SSEAlgorithm: AES256` to `aws:kms` and add a `KMSMasterKeyID`.

---

## Cost Considerations

| Resource | Free Tier | Notes |
|----------|-----------|-------|
| S3 Bucket | First 5GB | Standard storage tier |
| S3 Standard-IA | $0.0125/GB | After lifecycle transition |
| S3 Versioning | Extra cost | Each version stored separately |
| Access Logs | Minimal | Auto-expired after 90 days |

---

## Future Architecture Additions

- **VPC with public/private subnets** — networking foundation
- **EC2 in private subnet + Bastion host** — secure compute access
- **RDS in Multi-AZ** — managed database with failover
- **ALB + Auto Scaling Group** — highly available application tier
- **CloudFront + S3** — static website with CDN
