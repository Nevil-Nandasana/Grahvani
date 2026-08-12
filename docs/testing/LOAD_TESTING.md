# Load and Concurrency Testing Specification (Locust)

## Purpose
This document defines the load testing architecture, execution procedures, performance Service Level Objectives (SLOs), and results interpretation for the Grahvani FastAPI backend service (`services/api`).

## Scope
Applies to HTTP REST and Server-Sent Event (SSE) streaming API endpoints served by the FastAPI application. Covers concurrent user simulation up to 500+ users across multiple user tiers (Free, Trial, Premium).

---

## 1. Prerequisites & Installation

### Prerequisites
- Python 3.12+
- Poetry package manager installed
- Target Grahvani API server running (e.g. `http://localhost:8000` locally or a staging environment)

### Installation
Locust is included as a dev dependency in `services/api/pyproject.toml`. To ensure all dependencies are installed:

```bash
cd services/api
poetry install --with dev
```

To verify Locust installation:
```bash
poetry run locust --version
```

---

## 2. Target Performance Service Level Objectives (SLOs)

All backend endpoints must meet the following performance benchmarks under a 500 concurrent user load test before major releases:

| Endpoint | Target p50 | Target p95 | Target p99 | Max Non-Quota Error Rate |
| :--- | :--- | :--- | :--- | :--- |
| `GET /api/v1/billing/entitlements` | < 40 ms | < 100 ms | < 200 ms | < 0.1% |
| `POST /api/v1/billing/trial/activate` | < 100 ms | < 250 ms | < 500 ms | < 0.1% |
| `GET /api/v1/profiles` | < 50 ms | < 120 ms | < 250 ms | < 0.1% |
| `POST /api/v1/charts/dignities` | < 50 ms | < 150 ms | < 300 ms | < 0.1% |
| `POST /api/v1/charts/calculate` (Enqueue) | < 200 ms | < 500 ms | < 1,000 ms | < 0.1% |
| `POST /api/v1/chat/stream` (TTFB) | < 1,200 ms | < 2,500 ms | < 4,000 ms | < 1.0% |
| `POST /api/v1/chat/stream` (Total Stream) | < 3,500 ms | < 7,000 ms | < 10,000 ms | < 1.0% |
| `POST /api/v1/interpretation/query` (TTFB) | < 1,200 ms | < 2,500 ms | < 4,000 ms | < 1.0% |

> **Note on TTFB (Time-To-First-Byte)**: Measures the time elapsed between client request transmission and the receipt of the first SSE token chunk (`data: {"event": "delta", ...}`). This reflects hybrid search retrieval, cross-encoder reranking, and initial LLM model latency.

---

## 3. Running Load Tests

### 3.1 Headless Mode Execution (Automated CI/CD Runs)

To run a headless load test simulating 500 concurrent users with a spawn rate of 50 users/sec for 1 minute:

```bash
cd services/api
poetry run locust -f tests/load/locustfile.py \
  --headless \
  -u 500 \
  -r 50 \
  --run-time 1m \
  --host http://localhost:8000 \
  --html load_test_report.html \
  --csv load_test_metrics
```

#### Command Options Reference:
- `-f tests/load/locustfile.py`: Path to the Locust test script.
- `--headless`: Runs Locust without launching the Web UI (ideal for CLI/CI scripts).
- `-u 500` (`--users`): Peak number of concurrent simulated users.
- `-r 50` (`--spawn-rate`): Users spawned per second during ramp-up.
- `--run-time 1m`: Total test duration (e.g., `1m`, `5m`, `10m`).
- `--host http://localhost:8000`: Base URL of the target API service.
- `--html report.html`: Generates a standalone HTML performance report with charts.
- `--csv metrics`: Exports raw CSV latency, failure, and throughput data.

### 3.2 Interactive Web UI Execution

To launch Locust with its interactive web interface:

```bash
cd services/api
poetry run locust -f tests/load/locustfile.py --host http://localhost:8000 --web-port 8089
```

1. Open your browser and navigate to `http://localhost:8089`.
2. Enter the target number of users (e.g. `500`) and spawn rate (e.g. `50`).
3. Click **Start swarming** to initiate real-time graph tracking.
4. Monitor live requests per second (RPS), response time percentiles (p50, p95, p99), and failure rates.

---

## 4. Test Suite Architecture & User Classes

The Locust script in `services/api/tests/load/locustfile.py` implements a multi-tier user model to reflect realistic production traffic distribution:

```
                  GrahvaniUserBase (Abstract HttpUser)
                                   │
         ┌─────────────────────────┼─────────────────────────┐
         ▼                         ▼                         ▼
     FreeUser                 TrialUser                 PremiumUser
   (Weight: 60%)            (Weight: 20%)             (Weight: 20%)
   - 3 queries/day          - 100 queries/day         - 100 queries/day
   - Trial activation       - Chart calculation       - RAG SSE streaming
   - Entitlement checks     - Dignities endpoint      - Dignities calculation
```

### Authentication Bypass
Load tests use `Authorization: Bearer demo-token-<tier>-<id>` headers. When `APP_ENV == "development"`, `app/core/security.py` automatically intercepts `demo-` tokens and bypasses external Firebase verification, enabling high-concurrency performance testing without third-party network bottlenecks.

### Custom SSE Instrumentation
Locust's standard HTTP client measures response time up to initial response headers or full content download. For Server-Sent Events (SSE), `locustfile.py` utilizes custom `events.request.fire` hooks:

1. **`SSE_TTFB`**: Fired as soon as the first `data: ` line containing content is received.
2. **`SSE_STREAM`**: Fired when the `done` event is received or stream closes.
3. **`SSE_QUOTA`**: Fired when quota rate limit (HTTP 429 / `ENTITLEMENT_REQUIRED`) is hit.

### Quota Limit (HTTP 429) Handling
Free tier users are capped at 3 daily AI queries. In load tests, when a `FreeUser` receives an `ENTITLEMENT_REQUIRED` error (HTTP 429 or status 400 with entitlement detail), `locustfile.py` captures the event as `response.success()`. This ensures that rate limiting mechanisms are validated without distorting system error statistics.

---

## 5. Interpreting Results & Troubleshooting

### 5.1 Analyzing Latency Metrics
- **TTFB vs Total Duration**:
  - High `SSE_TTFB` (> 2,500 ms p95): Indicates slowdown in vector search (`text-embedding-004`), BGE cross-encoder reranking, or LLM prompt construction.
  - High `SSE_STREAM` (> 7,000 ms p95): Indicates slow token generation from the underlying LLM provider or network socket buffering.
- **Chart Endpoint Latency**:
  - If `POST /api/v1/charts/dignities` or `GET /api/v1/profiles` exceeds 100 ms p95, inspect database index coverage or CPU saturation during Swiss Ephemeris calculations.

### 5.2 Distinguishing Rate Limits from System Failures
- **Expected Rate Limits**: HTTP 429 or `ENTITLEMENT_REQUIRED` errors indicate that user quotas are functioning properly.
- **System Failures**: HTTP 500 (Internal Server Error), HTTP 502/503 (Bad Gateway / Service Unavailable), or connection timeouts indicate backend resource exhaustion.

### 5.3 Troubleshooting Bottlenecks
1. **PostgreSQL Connection Exhaustion**:
   - Symptom: HTTP 500 errors with `TooManyConnectionsError` or `asyncpg.exceptions.TooManyConnectionsError`.
   - Fix: Increase DB connection pool size in `app/core/db.py` or scale `pgBouncer`.
2. **Redis Task Queue Congestion**:
   - Symptom: High latency in `POST /api/v1/charts/calculate` job execution.
   - Fix: Increase Dramatiq worker concurrency or scale Redis instance memory.
3. **App Runner / CPU Scaling Lag**:
   - Symptom: Response time spike during initial user ramp up.
   - Fix: Adjust auto-scaling min instances or decrease target CPU threshold in deployment config.

---

## 6. Pre-Release Load Test Sign-Off Checklist

Before approving any major release to production:

- [ ] Run 500 user headless load test for at least 5 minutes (`poetry run locust ... -u 500 -r 50 --run-time 5m`).
- [ ] Verify `GET /api/v1/billing/entitlements` p95 < 100 ms.
- [ ] Verify `POST /api/v1/charts/dignities` p95 < 150 ms.
- [ ] Verify `POST /api/v1/chat/stream` TTFB p95 < 2,500 ms.
- [ ] Confirm non-quota error rate is < 0.1% across all HTTP endpoints.
- [ ] Export HTML report (`load_test_report.html`) and archive in `docs/testing/reports/`.

---

## Related Documents
- [TESTING_STRATEGY.md](TESTING_STRATEGY.md) — Risk-weighted testing philosophy
- [UNIT_TESTS.md](UNIT_TESTS.md) — Unit testing guidelines
- [INTEGRATION_TESTS.md](INTEGRATION_TESTS.md) — Integration test suite
- [E2E_TESTS.md](E2E_TESTS.md) — Maestro mobile UI testing
