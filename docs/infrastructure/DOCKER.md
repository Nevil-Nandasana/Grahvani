# Docker Containerization Specification

## Purpose
This document defines the containerization strategy for the Grahvani FastAPI backend. It explains the multi-stage build process, the inclusion of proprietary C-library data files, security hardening practices, and local development configurations.

## Scope
Applies to the `Dockerfile` at the root of the repository, used for both local development (via `docker-compose.yml`) and production AWS App Runner deployments.

---

## 1. Multi-Stage Production `Dockerfile`

Grahvani uses a multi-stage Docker build to keep the final image size small and eliminate build-time dependencies (compilers, git, poetry) from the production image.

### 1.1 Stage 1: The Builder
The builder stage installs `gcc` and `libswe-dev` (required to compile the `pyswisseph` C extension), installs `poetry`, and exports the dependencies to standard pip packages.

```dockerfile
# Stage 1: Build & Dependencies
FROM python:3.12-slim AS builder

WORKDIR /app

# Install system dependencies required for compiling pyswisseph and pgvector adapters
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libswe-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY poetry.lock pyproject.toml ./

# Install Poetry and generate a standard requirements.txt for the runner stage
RUN pip install poetry==1.8.2 \
    && poetry export -f requirements.txt --output requirements.txt --without-hashes
    
# Install python dependencies into a local directory for easy copying
RUN pip install --prefix=/install -r requirements.txt
```

### 1.2 Stage 2: The Runner (Production Image)
The runner stage copies only the compiled Python site-packages from the builder. It runs as a non-root user.

```dockerfile
# Stage 2: Runtime Environment
FROM python:3.12-slim AS runner

WORKDIR /app

# Install only the runtime C-libraries required by pyswisseph (no compilers)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libswe-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy python dependencies from builder
COPY --from=builder /install /usr/local

# Copy application source code
COPY ./app /app/app
COPY ./ephe_data /app/ephe_data

# Create a non-root user and switch to it for security
RUN useradd -m -u 1000 grahvani_user \
    && chown -R grahvani_user:grahvani_user /app
USER grahvani_user

# Set environment variables
ENV PYTHONPATH=/app
ENV EPHEMERIS_DATA_PATH=/app/ephe_data
ENV PYTHONUNBUFFERED=1

EXPOSE 8000

# Start FastAPI via Uvicorn (managed by Gunicorn in production for worker management)
CMD ["gunicorn", "app.main:app", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000"]
```

---

## 2. Ephemeris Data Files Injection

As specified in [astrology/SWISS_EPHEMERIS.md](../astrology/SWISS_EPHEMERIS.md), the `pyswisseph` library requires proprietary `.se1` files to calculate accurate positions. 

These files are stored in the git repository under `ephe_data/` and are physically `COPY`'d into the Docker image during Stage 2. This increases the image size by ~40MB but guarantees that the container is entirely self-sufficient and does not rely on external volume mounts at runtime.

---

## 3. Local Development (`docker-compose.yml`)

For local development, we use `docker-compose.yml` to orchestrate the API alongside a local PostgreSQL instance (with pgvector) and Redis.

```yaml
version: '3.8'

services:
  api:
    build: 
      context: .
      # Overrides CMD to use fast auto-reload for local dev
      command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
    ports:
      - "8000:8000"
    volumes:
      - ./app:/app/app   # Live-reload source code mapping
    environment:
      - USE_DOTENV=true  # Forces loading from .env instead of AWS Secrets Manager
      - DATABASE_URL=postgresql+asyncpg://dev:dev@db:5432/grahvani_dev
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis

  db:
    image: ankane/pgvector:v0.5.1  # Postgres 15 + pgvector pre-installed
    environment:
      - POSTGRES_USER=dev
      - POSTGRES_PASSWORD=dev
      - POSTGRES_DB=grahvani_dev
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
```

---

## 4. Rationale

**Why build the C-extensions inside Docker instead of pre-compiled wheels?**
Because `pyswisseph` relies on the system-level `libswe-dev` C library, relying on pre-compiled Python wheels often fails across different Linux distributions. Compiling from source in Stage 1 guarantees compatibility with the Debian-based slim image.

**Why Gunicorn over raw Uvicorn?**
While Uvicorn handles ASGI async routing perfectly, Gunicorn acts as a robust process manager. If an unexpected C-level segmentation fault occurs in `pyswisseph` (rare, but possible), Gunicorn immediately detects the worker death and spins up a replacement.

---

## 5. Related Documents

- [astrology/SWISS_EPHEMERIS.md](../astrology/SWISS_EPHEMERIS.md) -- Details on the data files baked into the image
- [infrastructure/CI_CD.md](CI_CD.md) -- How GitHub Actions builds and pushes this image
- [infrastructure/AWS.md](AWS.md) -- Where the image is deployed (App Runner)
