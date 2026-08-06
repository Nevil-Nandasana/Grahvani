# Secrets Management Specification

## Purpose
This document defines the rules, tooling, and processes for managing all secrets and credentials in the Grahvani system. A secret is any value that, if exposed, could allow unauthorized access to the system, user data, or third-party services.

## Scope
Covers all environments: local development, staging, and production.

---

## 1. Core Rules (Non-Negotiable)

1. **No secrets in Git**: No credential, API key, webhook secret, or database password may ever be committed to the repository. Violations are treated as security incidents requiring immediate secret rotation.
2. **No secrets in Docker images**: Container images must not bake in environment-specific secrets. Images are environment-agnostic.
3. **No secrets in application logs**: Structured logs must never include credential values. Use `mask_secrets()` middleware on all log formatters.
4. **No secrets in client apps**: The Flutter mobile app must never contain server-side secrets (API keys, DB passwords). Firebase API keys for client use are acceptable (they are restricted by Firebase App Check).

---

## 2. Secrets Inventory

| Secret Name | AWS Secrets Manager Path | Used By | Rotation Period |
| :--- | :--- | :--- | :--- |
| PostgreSQL connection string | `grahvani/prod/database_url` | FastAPI API, Dramatiq Worker | 90 days |
| Redis connection URL | `grahvani/prod/redis_url` | FastAPI API, Dramatiq Worker | 90 days |
| Firebase service account JSON | `grahvani/prod/firebase_credentials` | FastAPI JWT verifier | On credential change |
| Google Gemini API Key | `grahvani/prod/gemini_api_key` | Interpretation module | 90 days |
| Razorpay webhook secret | `grahvani/prod/razorpay_webhook_secret` | Billing webhook handler | 90 days |
| Razorpay API key + secret | `grahvani/prod/razorpay_api_credentials` | Billing service | 90 days |
| Google Play service account JSON | `grahvani/prod/google_play_credentials` | Billing IAP verifier | On credential change |
| Apple webhook shared secret | `grahvani/prod/apple_webhook_secret` | Billing webhook handler | On key rotation |
| Langfuse secret key | `grahvani/prod/langfuse_secret_key` | AI observability | 90 days |
| SendGrid API key (future) | `grahvani/prod/sendgrid_api_key` | Email notifications | 90 days |

---

## 3. AWS Secrets Manager Integration

Secrets are loaded at container startup via **Pydantic BaseSettings** with a custom AWS Secrets Manager source:

```python
# app/core/config.py
from pydantic_settings import BaseSettings, SettingsConfigDict
import boto3, json

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    DATABASE_URL: str
    REDIS_URL: str
    GEMINI_API_KEY: str
    RAZORPAY_WEBHOOK_SECRET: str
    FIREBASE_CREDENTIALS_JSON: str  # JSON string of the service account

    @classmethod
    def from_aws_secrets_manager(cls, secret_prefix: str = "grahvani/prod/") -> "Settings":
        """Load all secrets from AWS Secrets Manager at startup."""
        client = boto3.client("secretsmanager", region_name="ap-south-1")
        secret_names = [
            f"{secret_prefix}database_url",
            f"{secret_prefix}redis_url",
            f"{secret_prefix}gemini_api_key",
            f"{secret_prefix}razorpay_webhook_secret",
            f"{secret_prefix}firebase_credentials",
        ]
        env_vars = {}
        for secret_name in secret_names:
            value = client.get_secret_value(SecretId=secret_name)["SecretString"]
            key = secret_name.split("/")[-1].upper()
            env_vars[key] = value
        return cls(**env_vars)

settings = Settings.from_aws_secrets_manager() if not os.getenv("USE_DOTENV") else Settings()
```

---

## 4. Local Development

For local development, secrets are stored in a `.env` file that is listed in `.gitignore`:

```bash
# .env.example  (committed to repo -- no real values)
DATABASE_URL=postgresql+asyncpg://grahvani:password@localhost:5432/grahvani_dev
REDIS_URL=redis://localhost:6379/0
GEMINI_API_KEY=your-gemini-api-key-here
RAZORPAY_WEBHOOK_SECRET=your-razorpay-webhook-secret-here
FIREBASE_CREDENTIALS_JSON='{"type":"service_account","project_id":"...}'
USE_DOTENV=true
```

**Setup**:
```bash
cp .env.example .env
# Fill in your local/development credentials
```

---

## 5. Secret Rotation Procedure

When a secret requires rotation (scheduled 90-day rotation or emergency after a suspected breach):

1. Generate the new secret value in the relevant provider dashboard.
2. Update the secret value in AWS Secrets Manager (does NOT immediately affect running containers).
3. Trigger a rolling restart of App Runner services (the new secret is loaded at startup).
4. Verify health check passes after restart.
5. Revoke the old secret value in the provider dashboard.
6. Log the rotation in `admin_audit_logs` with action `SECRET_ROTATED`.

**Emergency Rotation** (suspected breach): Steps 1-5 must be completed within 4 hours. Notify on-call security lead immediately.

---

## 6. Rationale

AWS Secrets Manager is preferred over plain environment variables because:
- Secrets are never stored as plaintext in container definitions or task definitions.
- Access is controlled by IAM roles (only the App Runner instance role can read production secrets).
- Automatic rotation can be configured for supported resources (e.g., RDS credentials via Secrets Manager native rotation).
- Full access audit trail via AWS CloudTrail.

---

## 7. Trade-offs

| Choice | Pro | Con |
| :--- | :--- | :--- |
| AWS Secrets Manager | IAM-controlled access, CloudTrail audit, auto-rotation | Small additional cost (~$0.40/secret/month) |
| `.env` for local dev | Simple developer experience | Risk of accidentally committing if `.gitignore` is misconfigured |
| Startup-time secret loading | Secrets available before first request | Container startup time increases by ~500ms per Secrets Manager call |

---

## 8. Future Improvements

- **Secrets Manager Auto-Rotation**: Enable native RDS password rotation via Secrets Manager Lambda rotator to eliminate manual rotation.
- **HashiCorp Vault**: Evaluate if multi-cloud or hybrid deployment requirements emerge.
- **Pre-commit Hook**: Add `detect-secrets` pre-commit hook to automatically scan all commits for accidentally committed secrets.

---

## 9. Related Documents

- [ENCRYPTION.md](ENCRYPTION.md) -- Encryption of data at rest and in transit
- [infrastructure/SECURITY.md](../infrastructure/SECURITY.md) -- IAM roles and VPC network controls
- [COMPLIANCE.md](COMPLIANCE.md) -- Regulatory obligations around credential management
