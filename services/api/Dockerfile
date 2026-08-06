# Multi-stage production Dockerfile for Grahvani FastAPI backend
FROM python:3.12-slim AS builder

# Install system build dependencies for pyswisseph C extension
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install poetry==1.8.3

WORKDIR /build

# Copy dependency files first (Docker layer cache optimization)
COPY pyproject.toml poetry.lock* ./

# Install runtime dependencies only (no dev tools)
RUN poetry config virtualenvs.create false \
    && poetry install --only main --no-interaction --no-ansi

# ----------------------------------------------------------------
FROM python:3.12-slim AS runtime

RUN apt-get update && apt-get install -y \
    libpq-dev \
    libcairo2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libgdk-pixbuf2.0-0 \
    shared-mime-info \
    && rm -rf /var/lib/apt/lists/*

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

WORKDIR /app

# Copy application source code
COPY . .

# Expose FastAPI port
EXPOSE 8000

# Default startup: uvicorn (overridden by docker-compose for worker)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
