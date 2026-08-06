# Data Validation and Timezone Resolution

## Purpose
This document defines the strict validation rules applied to birth profile inputs. An astrology engine is extremely sensitive to time and location errors. A 4-minute time error or a 1-degree coordinate error can shift the Ascendant sign, completely altering the generated chart and AI interpretation.

## Scope
Applies to the `/api/v1/profiles` FastAPI endpoint and the Flutter client profile creation form.

---

## 1. Input Validation Rules (Pydantic Schema)

All profile creation requests must pass a strict Pydantic validation layer before the calculation engine is invoked.

```python
# app/modules/profiles/schemas.py
from pydantic import BaseModel, Field, constr
from datetime import date, time
import zoneinfo

class ProfileCreate(BaseModel):
    full_name: constr(min_length=2, max_length=100)
    
    # Restrict to sensible human birth dates
    birth_date: date = Field(..., ge=date(1900, 1, 1), le=date(2100, 12, 31))
    
    # Require seconds precision (even if 00)
    birth_time: time 
    
    # Valid geographic coordinates
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    
    # Must be a valid IANA database string
    timezone_id: str = Field(..., example="Asia/Kolkata")
    
    @field_validator('timezone_id')
    @classmethod
    def validate_timezone(cls, v: str) -> str:
        if v not in zoneinfo.available_timezones():
            raise ValueError("Invalid IANA timezone identifier")
        return v
```

---

## 2. The Timezone Resolution Problem

Users do not know their UTC offset at birth. They only know their local wall-clock time. Furthermore, countries change Daylight Saving Time (DST) rules frequently. For example, India observed DST briefly during the Sino-Indian War (1962) and the Indo-Pakistani War (1971).

**Rule**: Grahvani relies exclusively on the **IANA Time Zone Database** (`tzdata` via Python's `zoneinfo`) to resolve historical local time to UTC. 

### 2.1 Conversion Implementation

```python
# app/modules/birth_chart/services/time_conversion.py
from datetime import datetime
from zoneinfo import ZoneInfo

def convert_to_utc(
    birth_date: str, time_str: str, timezone_id: str
) -> datetime:
    """
    Takes local birth date/time and an IANA timezone ID, 
    and returns the exact UTC datetime.
    """
    # 1. Create a naive datetime object
    naive_dt = datetime.strptime(
        f"{birth_date} {time_str}", "%Y-%m-%d %H:%M:%S"
    )
    
    # 2. Attach the local timezone (applies historical DST offset automatically)
    local_dt = naive_dt.replace(tzinfo=ZoneInfo(timezone_id))
    
    # 3. Convert to UTC
    return local_dt.astimezone(ZoneInfo("UTC"))
```

---

## 3. Client-Side Location Enforcement (Flutter)

To ensure the backend receives valid coordinates and an IANA timezone string, the Flutter app **prohibits manual text entry for birth city**. 

**UX Flow:**
1. User types "Mumb" in the Birth City field.
2. Flutter app calls Google Places Autocomplete API.
3. User selects "Mumbai, Maharashtra, India".
4. Flutter app calls Google Places Details API to fetch exact `lat`/`lng`.
5. Flutter app calls Google Time Zone API (passing `lat`/`lng` and `timestamp=birth_date`) to retrieve the `timeZoneId` (e.g., "Asia/Kolkata").
6. App POSTs the exact coordinates and timezone string to the backend.

---

## 4. Rationale

Allowing users to type "EST" or "IST" is a catastrophic anti-pattern in astrology software because "IST" can mean Indian Standard Time, Irish Standard Time, or Israel Standard Time, and simple offsets (`+05:30`) ignore historical DST shifts. Enforcing IANA standard strings (e.g., `Asia/Kolkata`) via the Google Places/Timezone API guarantees mathematically correct UTC resolution.

---

## 5. Related Documents

- [CALCULATION_ENGINE.md](CALCULATION_ENGINE.md) -- Requires the UTC timestamp produced by this validation step
- [api/REQUEST_RESPONSE.md](../api/REQUEST_RESPONSE.md) -- Defines the HTTP 422 payload returned if validation fails
