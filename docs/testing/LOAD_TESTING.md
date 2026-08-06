# Load and Concurrency Testing Specification (Locust)

## Purpose
This document defines the load testing strategy for the Grahvani backend API, including target performance SLOs, Locust test scenarios, infrastructure scaling validation procedures, and pre-release load test sign-off criteria.

## Scope
Covers HTTP API endpoints served by the FastAPI container and SSE streaming endpoints. Does not cover client-side performance (Flutter rendering frames) or database internals.

---

## 1. Performance Service Level Objectives (SLOs)

These targets must be met in a load test before any production release:

| Endpoint | Target p50 | Target p95 | Target p99 | Max Error Rate |
| :--- | :--- | :--- | :--- | :--- |
| `GET /api/v1/profiles` | < 50 ms | < 120 ms | < 250 ms | < 0.1% |
| `GET /api/v1/profiles/{id}/charts` | < 80 ms | < 200 ms | < 400 ms | < 0.1% |
| `POST /api/v1/profiles/{id}/charts/calculate` | < 200 ms (enqueue) | < 500 ms | < 1,000 ms | < 0.1% |
| `POST /api/v1/chat/stream` (TTFB) | < 1,200 ms | < 2,500 ms | < 4,000 ms | < 1.0% |
| `GET /api/v1/billing/entitlements` | < 40 ms | < 100 ms | < 200 ms | < 0.1% |

**Time-To-First-Byte (TTFB) for SSE**: The time from request received to first SSE token delivered. LLM inference latency dominates this -- the 1.2 second p50 target reflects the LLM provider's typical TTFB.

---

## 2. Load Scenarios

### Scenario A: Baseline API Load (Normal Traffic)
Simulate 200 concurrent users browsing charts and reading their Dasha timeline.

### Scenario B: AI Chat Burst (Peak Engagement)
Simulate 100 concurrent users simultaneously opening SSE connections for AI chat.

### Scenario C: Launch Day Spike (Stress Test)
Simulate 1,000 concurrent users over a 5-minute ramp to verify App Runner auto-scaling.

---

## 3. Locust Test Implementation

```python
# tests/load/locustfile.py
from locust import HttpUser, task, between, events
import random, json

# Test JWT tokens (pre-generated for staging test accounts)
TEST_TOKENS = [
    "Bearer eyJ...",  # Load from tests/load/test_tokens.json
]

TEST_PROFILE_IDS = [
    "e4b2d184-7a33-4f9e-a892-000000000001",
    "e4b2d184-7a33-4f9e-a892-000000000002",
    # ... 20 pre-seeded staging profiles
]

class GrahvaniUser(HttpUser):
    """Simulates a typical Grahvani user session."""
    wait_time = between(1, 5)   # Think time between requests (seconds)

    def on_start(self):
        """Called when simulated user starts. Pick a random test identity."""
        self.token = random.choice(TEST_TOKENS)
        self.profile_id = random.choice(TEST_PROFILE_IDS)
        self.headers = {"Authorization": self.token}

    @task(5)
    def fetch_chart(self):
        """Most common action: view birth chart. Weight=5 (most frequent)."""
        with self.client.get(
            f"/api/v1/profiles/{self.profile_id}/charts",
            headers=self.headers,
            catch_response=True,
            name="GET /api/v1/profiles/{id}/charts",
        ) as resp:
            if resp.status_code != 200:
                resp.failure(f"Chart fetch failed: {resp.status_code}")

    @task(3)
    def fetch_dasha(self):
        """View Dasha timeline. Weight=3."""
        self.client.get(
            f"/api/v1/profiles/{self.profile_id}/dashas",
            headers=self.headers,
            name="GET /api/v1/profiles/{id}/dashas",
        )

    @task(2)
    def check_entitlement(self):
        """Check subscription tier. Weight=2."""
        self.client.get(
            "/api/v1/billing/entitlements",
            headers=self.headers,
            name="GET /api/v1/billing/entitlements",
        )

    @task(1)
    def stream_ai_chat(self):
        """
        AI chat SSE stream. Weight=1 (least frequent, most expensive).
        Measures Time-To-First-Byte using streaming response.
        """
        questions = [
            "What does my Sun in the 10th house mean?",
            "Tell me about my current Maha Dasha period.",
            "What is the significance of my Moon in Aries?",
        ]
        with self.client.post(
            "/api/v1/chat/stream",
            json={
                "session_id": "00000000-0000-0000-0000-000000000001",
                "question": random.choice(questions),
            },
            headers={**self.headers, "Accept": "text/event-stream"},
            stream=True,
            catch_response=True,
            name="POST /api/v1/chat/stream (SSE)",
        ) as resp:
            first_token_received = False
            for chunk in resp.iter_content(chunk_size=512):
                if not first_token_received and b"token" in chunk:
                    first_token_received = True
                    # TTFB is automatically measured by Locust's response_time at this point
                if b'"done"' in chunk:
                    break  # Stop reading after done event
```

---

## 4. Running Load Tests

```bash
# Install Locust
pip install locust

# Scenario A: 200 users, 5 minute ramp, against staging
locust -f tests/load/locustfile.py \
  --host https://staging.api.grahvani.app \
  --users 200 \
  --spawn-rate 10 \
  --run-time 5m \
  --headless \
  --html load_test_report.html \
  --csv load_test_results

# Scenario C: Launch day stress test (1000 users, 5 min ramp)
locust -f tests/load/locustfile.py \
  --host https://staging.api.grahvani.app \
  --users 1000 \
  --spawn-rate 50 \
  --run-time 10m \
  --headless \
  --html stress_test_report.html
```

---

## 5. Auto-Scaling Validation

During Scenario C (1000 users), monitor App Runner instance count in CloudWatch:
- Expect: scaling from 2 to 8-10 instances within 90 seconds of ramp start.
- Alert if: p95 response time exceeds SLO during scale-up period (scale-up lag).

---

## 6. Pre-Release Sign-Off Criteria

Load tests must be run and signed off before every major release:

- [ ] All SLO targets met at Scenario B load (100 concurrent users)
- [ ] Error rate < 1% for SSE chat endpoint under Scenario B
- [ ] App Runner scales to >= 4 instances under Scenario C within 2 minutes
- [ ] No RDS connection pool exhaustion errors in CloudWatch during Scenario C
- [ ] Redis memory usage stays below 80% during peak load

---

## 7. Rationale

Load testing is run against staging (not production) because:
1. Production test traffic would consume real LLM API quota and incur real costs.
2. The staging backend uses the same App Runner configuration as production, giving representative scaling behaviour.
3. Staging test user tokens are pre-seeded with free-tier entitlements to accurately simulate the majority of users.

---

## 8. Related Documents

- [TESTING_STRATEGY.md](TESTING_STRATEGY.md) -- Overall testing philosophy
- [infrastructure/MONITORING.md](../infrastructure/MONITORING.md) -- CloudWatch metrics and alarms
- [infrastructure/DEPLOYMENT.md](../infrastructure/DEPLOYMENT.md) -- App Runner auto-scaling configuration
