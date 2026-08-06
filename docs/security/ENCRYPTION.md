# Encryption Specification

## Purpose
This document specifies every encryption mechanism applied in the Grahvani system -- in transit, at rest, and on client devices. It serves as the authoritative reference for security reviews, compliance audits, and infrastructure configuration.

## Scope
Covers all data stores (PostgreSQL, Redis, S3), API transport, internal service-to-service communication, and client-side secure storage.

---

## 1. Encryption in Transit

All data moving between any two system components is encrypted using **TLS 1.3** as a minimum standard. TLS 1.2 is explicitly disabled.

| Connection Path | Protocol | Certificate |
| :--- | :--- | :--- |
| Flutter Client --> AWS App Runner (API) | TLS 1.3 | AWS ACM auto-renewed certificate on custom domain `api.grahvani.app` |
| Flutter Client --> Firebase Auth | TLS 1.3 | Google-managed |
| FastAPI Backend --> Amazon RDS PostgreSQL | TLS 1.3 | `sslmode=require` enforced in `DATABASE_URL` connection string |
| FastAPI Backend --> Amazon ElastiCache Redis | TLS 1.3 | `ssl=True` in Redis connection URL |
| FastAPI Backend --> Google Gemini API | TLS 1.3 | Google-managed; HTTPS enforced by `google-generativeai` SDK |
| FastAPI Backend --> AWS S3 | TLS 1.3 | AWS-managed endpoint; boto3 uses HTTPS by default |
| App Runner --> AWS Secrets Manager | TLS 1.3 | AWS VPC endpoint enforced |

**HTTP Strict Transport Security (HSTS)**: The API gateway enforces `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload` on all responses.

---

## 2. Encryption at Rest

| Data Store | Encryption Method | Key Management |
| :--- | :--- | :--- |
| **Amazon RDS PostgreSQL** | AES-256 via AWS KMS (default service key) | AWS-managed, rotated automatically |
| **Amazon ElastiCache Redis** | AES-256 via AWS KMS | AWS-managed |
| **Amazon S3 (Docs + PDF Exports)** | SSE-S3 (AES-256, AWS-managed keys) | No extra cost; auto-applied to every object |
| **Flutter SecureStorage (JWT + Profile Cache)** | iOS: AES-256 via iOS Keychain (Secure Enclave on supported devices) | Platform-managed |
| **Flutter SecureStorage (JWT + Profile Cache)** | Android: AES-256 via Android Keystore | Platform-managed |
| **Drift SQLite (Client Cache)** | Unencrypted -- sensitive chart facts are stored as computed, non-PII data only | No key needed; PII never stored in Drift |

---

## 3. Encryption Implementation Details

### 3.1 PostgreSQL TLS Configuration

The `DATABASE_URL` environment variable must be configured as:
```
postgresql+asyncpg://user:password@rds-endpoint:5432/grahvani_prod?ssl=require
```

SQLAlchemy engine creation enforces this:
```python
from sqlalchemy.ext.asyncio import create_async_engine

engine = create_async_engine(
    settings.DATABASE_URL,
    connect_args={"ssl": "require"},   # Enforces TLS; connection fails if DB doesn't support it
    pool_size=10,
    max_overflow=20,
)
```

### 3.2 Redis TLS Configuration

```python
import redis.asyncio as aioredis

redis_client = aioredis.from_url(
    settings.REDIS_URL,
    ssl=True,
    ssl_cert_reqs="required",   # Enforce server certificate validation
)
```

### 3.3 Client-Side Secure Storage (Flutter)

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage(
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

// Store Firebase JWT token securely
await storage.write(key: 'firebase_jwt', value: idToken);

// Read JWT for API calls
final jwt = await storage.read(key: 'firebase_jwt');
```

---

## 4. Rationale

**Why TLS 1.3 minimum (not 1.2)?**
TLS 1.3 eliminates several legacy cryptographic vulnerabilities (RC4, SHA-1, RSA key exchange) present in TLS 1.2. AWS App Runner and modern AWS managed services support TLS 1.3 by default, so there is no operational cost to enforcing it.

**Why AWS-managed KMS keys (not customer-managed CMKs)?**
AWS service-managed keys provide AES-256 encryption with automatic rotation at zero cost and no operational overhead. Customer-managed CMKs add control at the cost of key rotation management complexity. CMKs will be evaluated in Phase 3 when compliance requirements (ISO 27001 / SOC 2) may require it.

---

## 5. Trade-offs

| Choice | Pro | Con |
| :--- | :--- | :--- |
| TLS 1.3 minimum | Strongest modern TLS, eliminates legacy vulns | Older mobile OS versions (Android 6, iOS 9) may not support -- acceptable for Grahvani's target market |
| AWS-managed KMS | Zero operational overhead | Less fine-grained control vs. CMKs |
| Drift SQLite unencrypted | No performance overhead for chart display caching | Sensitive data (birth time, exact coordinates) must never be written to Drift -- enforced by code review |

---

## 6. Future Improvements

- **Customer-Managed KMS Keys (CMKs)**: Implement for ISO 27001 / SOC 2 readiness in Phase 3.
- **Encrypted Drift Cache**: If chart PII is ever stored locally, evaluate `sqflite_sqlcipher` for encrypted SQLite.
- **Certificate Pinning**: Add SSL pinning in the Flutter app to prevent MITM attacks on compromised devices.

---

## 7. Related Documents

- [SECRETS.md](SECRETS.md) -- Secrets management and AWS Secrets Manager configuration
- [DATA_PRIVACY.md](DATA_PRIVACY.md) -- DPDP Act compliance and data handling
- [THREAT_MODEL.md](THREAT_MODEL.md) -- Information disclosure threat mitigations
- [infrastructure/SECURITY.md](../infrastructure/SECURITY.md) -- IAM and network-level security
