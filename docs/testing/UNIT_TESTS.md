# Unit Testing and Reference Test Vectors

## Purpose
This document defines the unit testing strategy for the Grahvani backend API, focusing on business logic isolation, mocking strategies for external dependencies, and the structure of the critical astrological reference test vectors.

## Scope
Applies to all Python code in the FastAPI backend (`app/`) tested via `pytest`. Does not cover Flutter client unit tests, integration tests, or E2E tests.

---

## 1. Unit Testing Philosophy

Unit tests in Grahvani are designed to be **fast, deterministic, and isolated**.
- **No Database**: Unit tests must use mock repositories or SQLite in-memory fixtures. They must not require a running PostgreSQL instance.
- **No Network**: Calls to Firebase, Gemini, or Razorpay must be mocked.
- **High Coverage Threshold**: The CI pipeline enforces a minimum 80% line coverage for the `app/` directory via `pytest-cov`.

---

## 2. Mocking Strategy

Grahvani uses `pytest` fixtures and the `unittest.mock` library to isolate domain logic from infrastructure.

### 2.1 Mocking LLM Providers

When testing the interpretation module, the actual LLM call is mocked to return a deterministic string, allowing the test to verify prompt assembly and token budget calculations without incurring API costs.

```python
# tests/unit/test_interpretation.py
import pytest
from unittest.mock import AsyncMock, patch

@pytest.fixture
def mock_llm_provider():
    with patch("app.modules.interpretation.llm_provider.GeminiProvider") as mock:
        provider = mock.return_value
        # Mock the async generator
        async def mock_generate(*args, **kwargs):
            yield "Saturn "
            yield "is "
            yield "strong."
        provider.generate_stream = mock_generate
        yield provider

@pytest.mark.asyncio
async def test_generate_answer_assembles_prompt_correctly(mock_llm_provider):
    # Test logic verifying that retrieve_chunks and assemble_prompt are called 
    # correctly before passing data to the mocked provider.
    pass
```

### 2.2 Mocking Database Repositories

```python
# tests/unit/conftest.py
import pytest
from app.modules.profiles.repository import ProfileRepository

class InMemoryProfileRepository(ProfileRepository):
    def __init__(self):
        self._db = {}
        
    async def create(self, profile):
        self._db[profile.id] = profile
        return profile
        
    async def get(self, profile_id):
        return self._db.get(profile_id)

@pytest.fixture
def profile_repo():
    return InMemoryProfileRepository()
```

---

## 3. Astrological Reference Verification

The most critical unit tests in the system verify the output of the Swiss Ephemeris wrapper (`pyswisseph`) against known-correct reference data. 

**Test Vector Format**: A JSON file (`tests/astro/reference_charts.json`) containing historical charts calculated via NASA JPL Horizons or Astro.com.

```json
[
  {
    "description": "Steve Jobs (Standard test case)",
    "birth_date": "1955-02-24",
    "birth_time": "19:15:00",
    "latitude": 37.7749,
    "longitude": -122.4194,
    "timezone_id": "America/Los_Angeles",
    "ayanamsha": "Lahiri",
    "expected_d1": {
      "ascendant_sign": "Leo",
      "ascendant_degree": 141.2451,
      "sun_sign": "Aquarius",
      "sun_degree": 312.4512
    }
  }
]
```

**Precision Assertion**: Astrological math uses floating-point numbers. Tests must assert equality within an acceptable tolerance using `pytest.approx()`.

```python
# tests/astro/test_chart_precision.py
import pytest
from app.modules.birth_chart.services.ephemeris import calculate_positions

def test_lahiri_ayanamsa_reference_chart():
    # Test Vector: 1995-10-24 14:30:00 UTC at 22.3072 N, 73.1812 E
    chart = calculate_positions(
        julian_day_ut=2450015.104167,
        latitude=22.3072,
        longitude=73.1812,
        ayanamsha_id=1  # 1 = Lahiri in pyswisseph
    )
    
    # Assert Sun sidereal longitude matches reference within 0.0001 degrees
    # Tolerance of 0.0001 degrees is ~0.36 arcseconds (far below human perception limit)
    assert pytest.approx(chart["sun_longitude"], abs=1e-4) == 208.5421
    assert chart["ascendant_sign"] == "Scorpio"
```

---

## 4. Test Directory Structure

```
tests/
├── unit/
│   ├── auth/          # JWT parsing, role validation
│   ├── billing/       # Entitlement logic, receipt validation
│   ├── interpretation/# Prompt assembly, guardrails, LLM mocking
│   └── profiles/      # CRUD validation logic
├── astro/             # The critical calculation precision suite
│   ├── reference_charts.json
│   ├── test_chart_precision.py
│   └── test_dasha.py
└── conftest.py        # Shared fixtures (mock DB, mock Redis)
```

---

## 5. Rationale

Isolating the astrological calculation engine into its own highly rigorous unit test suite (`tests/astro/`) prevents infrastructure failures (e.g., database timeouts) from causing false negatives in the core domain logic. Using `pytest.approx()` is mandatory because floating-point drift across CPU architectures (x86 locally vs ARM in AWS) can cause exact equality assertions to fail unpredictably.

---

## 6. Related Documents

- [testing/TESTING_STRATEGY.md](TESTING_STRATEGY.md) -- The overall quality gate and test pyramid
- [testing/INTEGRATION_TESTS.md](INTEGRATION_TESTS.md) -- Tests that do hit the real database
- [astrology/CALCULATION_ENGINE.md](../astrology/CALCULATION_ENGINE.md) -- The system being tested in the `tests/astro/` suite
