"""
Grahvani Backend Load & Performance Testing Suite (Locust)
Location: services/api/tests/load/locustfile.py

Simulates realistic multi-tier traffic (Free, Trial, Premium users) targeting:
- RAG SSE streaming endpoints: POST /api/v1/chat/stream and POST /api/v1/interpretation/query
- 7-Day Trial Activation: POST /api/v1/billing/trial/activate
- Billing Entitlements: GET /api/v1/billing/entitlements
- Ephemeris & Chart Calculation: POST /api/v1/charts/calculate, POST /api/v1/charts/dignities, GET /api/v1/profiles

Auth Header: Authorization: Bearer demo-token-... (leveraging app/core/security.py development bypass)
Metrics: Measures Time-To-First-Byte (TTFB) and total SSE stream completion time via events.request.fire calls.
Quota Handling: Gracefully handles HTTP 429 (ENTITLEMENT_REQUIRED) without marking expected quota limits as failures.
"""

import json
import random
import time
import uuid
from typing import Any, Dict, Optional

from locust import HttpUser, TaskSet, between, events, task


# Sample prompts for RAG chat streaming tests
SAMPLE_PROMPTS = [
    "What does my Sun in the 10th house indicate for my career?",
    "Explain the effects of Jupiter Mahadasha in my natal chart.",
    "Which gemstones are suitable for an Aries Lagna?",
    "What are the key transits affecting my Saturn in 2026?",
    "How does Moon in Rohini nakshatra influence emotional balance?",
    "What is the significance of Rahu in the 5th house for education?",
]

# Sample planetary positions for dignity calculation tests
SAMPLE_DIGNITIES_PAYLOAD = {
    "planet_positions": {
        "Sun": 0,
        "Moon": 3,
        "Mars": 0,
        "Mercury": 1,
        "Jupiter": 4,
        "Venus": 11,
        "Saturn": 6,
    },
    "planet_degrees": {
        "Sun": 14.5,
        "Moon": 2.1,
        "Mars": 28.0,
        "Mercury": 10.0,
        "Jupiter": 5.0,
        "Venus": 27.0,
        "Saturn": 20.0,
    },
    "sun_longitude": 14.5,
    "retrogrades": {
        "Mercury": False,
        "Jupiter": True,
        "Saturn": False,
    },
}


class GrahvaniUserBase(HttpUser):
    """
    Base user class providing shared request helpers, auth header setup,
    and custom SSE timing instrumentation.
    """

    abstract = True
    wait_time = between(1.0, 3.0)
    tier = "free"

    def on_start(self):
        """Initialize user headers and session identifiers on worker start."""
        token_suffix = f"{self.tier}-{random.randint(1, 1000)}"
        self.auth_token = f"Bearer demo-token-{token_suffix}"
        self.headers = {
            "Authorization": self.auth_token,
            "Content-Type": "application/json",
        }
        self.profile_id = str(uuid.uuid4())
        self.session_id = str(uuid.uuid4())

    def _stream_rag_query(self, endpoint: str = "/api/v1/chat/stream", expect_quota_error: bool = False):
        """
        Execute SSE streaming request against RAG endpoints and record custom TTFB
        and total stream completion events.
        """
        payload = {
            "session_id": self.session_id,
            "prompt": random.choice(SAMPLE_PROMPTS),
        }
        headers = {**self.headers, "Accept": "text/event-stream"}
        start_time = time.time()

        first_byte_received = False
        total_content_len = 0

        try:
            with self.client.post(
                endpoint,
                json=payload,
                headers=headers,
                stream=True,
                catch_response=True,
                name=f"POST {endpoint} (SSE Connect)",
            ) as response:
                # Handle rate limiting / quota limits gracefully
                if response.status_code == 429 or (expect_quota_error and response.status_code in (400, 429)):
                    response.success()
                    events.request.fire(
                        request_type="SSE_QUOTA",
                        name=f"POST {endpoint} (Quota Reached)",
                        response_time=(time.time() - start_time) * 1000,
                        response_length=0,
                        exception=None,
                    )
                    return

                if response.status_code != 200:
                    response.failure(f"HTTP {response.status_code}: {response.text[:200]}")
                    return

                # Read line-by-line from SSE stream
                for line in response.iter_lines():
                    if not line:
                        continue

                    line_str = line.decode("utf-8") if isinstance(line, bytes) else line

                    if line_str.startswith("data: "):
                        total_content_len += len(line_str)

                        # Measure Time-To-First-Byte (TTFB) on initial event
                        if not first_byte_received:
                            ttfb = (time.time() - start_time) * 1000
                            first_byte_received = True
                            events.request.fire(
                                request_type="SSE_TTFB",
                                name=f"POST {endpoint} (TTFB)",
                                response_time=ttfb,
                                response_length=len(line_str),
                                exception=None,
                            )

                        try:
                            event_data = json.loads(line_str[6:])
                            event_type = event_data.get("event")

                            if event_type == "error":
                                err_code = event_data.get("code", "")
                                if expect_quota_error and err_code == "ENTITLEMENT_REQUIRED":
                                    response.success()
                                    events.request.fire(
                                        request_type="SSE_QUOTA",
                                        name=f"POST {endpoint} (Quota Reached)",
                                        response_time=(time.time() - start_time) * 1000,
                                        response_length=total_content_len,
                                        exception=None,
                                    )
                                    return
                                else:
                                    response.failure(f"SSE Error: {event_data.get('message')}")
                                    return
                            elif event_type == "done":
                                break

                        except json.JSONDecodeError:
                            pass

                total_duration = (time.time() - start_time) * 1000
                events.request.fire(
                    request_type="SSE_STREAM",
                    name=f"POST {endpoint} (Full Stream)",
                    response_time=total_duration,
                    response_length=total_content_len,
                    exception=None,
                )
                response.success()

        except Exception as err:
            events.request.fire(
                request_type="SSE_STREAM",
                name=f"POST {endpoint} (Failed)",
                response_time=(time.time() - start_time) * 1000,
                response_length=0,
                exception=err,
            )

    @task(3)
    def check_entitlements(self):
        """GET /api/v1/billing/entitlements — Check user entitlement quota and tier."""
        with self.client.get(
            "/api/v1/billing/entitlements",
            headers=self.headers,
            catch_response=True,
            name="GET /api/v1/billing/entitlements",
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"HTTP {response.status_code}: {response.text[:200]}")

    @task(2)
    def get_profiles(self):
        """GET /api/v1/profiles — Fetch user's active birth profiles."""
        with self.client.get(
            "/api/v1/profiles",
            headers=self.headers,
            catch_response=True,
            name="GET /api/v1/profiles",
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"HTTP {response.status_code}: {response.text[:200]}")

    @task(2)
    def calculate_dignities(self):
        """POST /api/v1/charts/dignities — Direct calculation of planetary dignities."""
        with self.client.post(
            "/api/v1/charts/dignities",
            json=SAMPLE_DIGNITIES_PAYLOAD,
            headers=self.headers,
            catch_response=True,
            name="POST /api/v1/charts/dignities",
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"HTTP {response.status_code}: {response.text[:200]}")

    @task(1)
    def calculate_birth_chart(self):
        """POST /api/v1/charts/calculate — Enqueue background ephemeris calculation."""
        payload = {
            "profile_id": self.profile_id,
            "ayanamsa": "lahiri",
            "house_system": "placidus",
        }
        with self.client.post(
            "/api/v1/charts/calculate",
            json=payload,
            headers=self.headers,
            catch_response=True,
            name="POST /api/v1/charts/calculate",
        ) as response:
            # 202 Accepted or 404 (if profile id doesn't exist in DB) are expected status codes in load runs
            if response.status_code in (200, 202, 404):
                response.success()
            else:
                response.failure(f"HTTP {response.status_code}: {response.text[:200]}")


class FreeUser(GrahvaniUserBase):
    """
    Simulates un-monetized free tier users (60% weight).
    Subject to 3 daily query limit, expected to test quota enforcement and trial activation.
    """

    weight = 6
    tier = "free"

    @task(4)
    def check_entitlements(self):
        super().check_entitlements()

    @task(3)
    def stream_chat(self):
        """POST /api/v1/chat/stream — Stream RAG response, expecting entitlement 429 when quota is reached."""
        self._stream_rag_query("/api/v1/chat/stream", expect_quota_error=True)

    @task(2)
    def stream_interpretation_query(self):
        """POST /api/v1/interpretation/query — Stream RAG response on alias endpoint."""
        self._stream_rag_query("/api/v1/interpretation/query", expect_quota_error=True)

    @task(2)
    def activate_trial(self):
        """POST /api/v1/billing/trial/activate — Attempt trial activation."""
        with self.client.post(
            "/api/v1/billing/trial/activate",
            headers=self.headers,
            catch_response=True,
            name="POST /api/v1/billing/trial/activate",
        ) as response:
            # 200 (Activated) or 400 (Already redeemed) are valid non-failure responses
            if response.status_code in (200, 400):
                response.success()
            else:
                response.failure(f"HTTP {response.status_code}: {response.text[:200]}")


class TrialUser(GrahvaniUserBase):
    """
    Simulates users currently on 7-Day Free Premium Trial (20% weight).
    """

    weight = 2
    tier = "trial"

    @task(5)
    def stream_chat(self):
        """POST /api/v1/chat/stream — Premium query limit under trial."""
        self._stream_rag_query("/api/v1/chat/stream", expect_quota_error=False)

    @task(3)
    def check_entitlements(self):
        super().check_entitlements()

    @task(2)
    def calculate_birth_chart(self):
        super().calculate_birth_chart()

    @task(2)
    def calculate_dignities(self):
        super().calculate_dignities()


class PremiumUser(GrahvaniUserBase):
    """
    Simulates paying subscription users (20% weight).
    High volume of RAG streaming queries and chart calculations.
    """

    weight = 2
    tier = "premium"

    @task(6)
    def stream_chat(self):
        """POST /api/v1/chat/stream — RAG SSE streaming query."""
        self._stream_rag_query("/api/v1/chat/stream", expect_quota_error=False)

    @task(4)
    def stream_interpretation_query(self):
        """POST /api/v1/interpretation/query — Alias streaming endpoint."""
        self._stream_rag_query("/api/v1/interpretation/query", expect_quota_error=False)

    @task(3)
    def calculate_dignities(self):
        super().calculate_dignities()

    @task(3)
    def calculate_birth_chart(self):
        super().calculate_birth_chart()

    @task(2)
    def check_entitlements(self):
        super().check_entitlements()


class GrahvaniUser(GrahvaniUserBase):
    """
    Unified default user runner class for general single-class Locust invocations.
    """

    weight = 1
    tier = "premium"

    @task(5)
    def stream_chat(self):
        self._stream_rag_query("/api/v1/chat/stream", expect_quota_error=False)

    @task(3)
    def check_entitlements(self):
        super().check_entitlements()

    @task(2)
    def calculate_dignities(self):
        super().calculate_dignities()
