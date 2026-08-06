# Environment Variables & Configuration Specification

## Purpose
This document provides the definitive list of all environment variables required to run the Grahvani FastAPI backend. It defines their types, default values (if any), and whether they are loaded from a `.env` file or dynamically fetched from AWS Secrets Manager in production.

## Scope
Applies to the `pydantic-settings` schema in the backend application.

---

## 1. Application Configuration Strategy

The backend uses `pydantic-settings` for robust type parsing and validation of environment variables at startup. 

```python
# app/core/config.py
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import PostgresDsn, RedisDsn, SecretStr

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")
    
    # Typed fields - application fails to start if types don't match
    ENVIRONMENT: str = "development"
    DATABASE_URL: PostgresDsn
    REDIS_URL: RedisDsn
    LLM_PROVIDER: str = "google"
    # ...
```

---

## 2. Environment Variables Checklist

### 2.1 Core Application Settings
| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `ENVIRONMENT` | string | `"development"` | Current deployment stage (`"development"`, `"staging"`, `"production"`). |
| `USE_DOTENV` | boolean | `False` | If `true`, secrets are loaded from `.env` instead of AWS Secrets Manager. Set to `true` exclusively for local development. |
| `LOG_LEVEL` | string | `"INFO"` | Logging verbosity (`"DEBUG"`, `"INFO"`, `"WARNING"`, `"ERROR"`). |
| `CORS_ORIGINS` | string | `"*"` | Comma-separated list of allowed origins for web clients. |

### 2.2 Database and Infrastructure
| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `DATABASE_URL` | string (DSN) | *Required* | PostgreSQL connection string. Must use `postgresql+asyncpg://` protocol. |
| `REDIS_URL` | string (DSN) | *Required* | Redis connection string. Must include `ssl=True` params in production. |
| `EPHEMERIS_DATA_PATH` | string | `"/app/ephe_data"` | Absolute path to the directory containing Swiss Ephemeris `.se1` files. |

### 2.3 Authentication (Firebase)
| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `FIREBASE_PROJECT_ID` | string | *Required* | The Google Cloud project ID containing the Firebase app. |
| `FIREBASE_CREDENTIALS_JSON` | string | *Required* | The raw stringified JSON of the Firebase Admin SDK service account key. |

### 2.4 AI and Models
| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `LLM_PROVIDER` | string | `"google"` | The LLM provider abstraction to load (`"google"`, `"anthropic"`, `"openai"`). |
| `LLM_MODEL_NAME` | string | `"gemini-1.5-flash"` | The specific model version to use for chat inference. |
| `GEMINI_API_KEY` | string | *Required* | API key for Google Gemini (Vertex AI equivalent). |
| `EMBEDDING_MODEL` | string | `"text-embedding-3-small"` | The model used to generate query vectors for RAG. |
| `OPENAI_API_KEY` | string | *Required* | Used exclusively for the embedding model if OpenAI is selected. |

### 2.5 Billing and Webhooks
| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `APPLE_WEBHOOK_SECRET` | string | *Required* | Secret used to verify Apple App Store Server Notifications v2 JWTs. |
| `GOOGLE_PLAY_CREDENTIALS` | string | *Required* | Stringified JSON of the Google Play service account for RTDN verification. |
| `RAZORPAY_KEY_ID` | string | *Required* | Public identifier for Razorpay API. |
| `RAZORPAY_KEY_SECRET` | string | *Required* | Secret key for Razorpay API calls. |
| `RAZORPAY_WEBHOOK_SECRET` | string | *Required* | Used to generate the HMAC signature to verify incoming Razorpay webhooks. |

### 2.6 Observability
| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `SENTRY_DSN` | string | `""` | DSN for Sentry error tracking. If empty, Sentry is disabled. |
| `LANGFUSE_PUBLIC_KEY` | string | *Required* | Langfuse project public key for AI tracing. |
| `LANGFUSE_SECRET_KEY` | string | *Required* | Langfuse project secret key. |

---

## 3. Loading Mechanism (AWS Secrets Manager)

To comply with the non-negotiable security rule of "No secrets in environment definitions", the App Runner production service does NOT have sensitive variables like `DATABASE_URL` injected as environment variables in the console or terraform script.

Instead, when `USE_DOTENV=false` (the default in production), the application explicitly fetches these secrets from AWS Secrets Manager at startup.

**Production Container Environment Setup:**
```bash
# Only these non-sensitive flags are set in App Runner config
ENVIRONMENT=production
USE_DOTENV=false
AWS_REGION=ap-south-1
# ... all other variables are fetched dynamically by pydantic on boot
```

---

## 4. Rationale

Failing fast at startup via Pydantic validation prevents the application from entering a zombie state where it appears healthy to the load balancer but fails on specific API calls due to missing credentials. Relying on AWS Secrets Manager for the actual injection prevents credential leakage via standard environment dumping exploits (e.g., SSRF vulnerabilities that read `/proc/1/environ`).

---

## 5. Related Documents

- [security/SECRETS.md](../security/SECRETS.md) -- Detailed rules and AWS Secrets Manager loading code
- [infrastructure/AWS.md](AWS.md) -- Where the App Runner configurations are defined
- [infrastructure/DOCKER.md](DOCKER.md) -- Local development `.env` usage via Docker Compose
