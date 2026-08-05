"""
Identity Module — Pydantic v2 Schemas (Request / Response)
"""
import uuid
from datetime import date, time

from pydantic import BaseModel, Field, field_validator


class CreateProfileRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100, examples=["Aditya Sharma"])
    date_of_birth: date = Field(..., examples=["1992-08-15"])
    time_of_birth: time = Field(..., examples=["14:30:00"])
    place_name: str = Field(..., min_length=2, max_length=255, examples=["New Delhi, India"])
    latitude: float = Field(..., ge=-90.0, le=90.0, examples=[28.6139])
    longitude: float = Field(..., ge=-180.0, le=180.0, examples=[77.2090])
    timezone: str = Field(default="Asia/Kolkata", examples=["Asia/Kolkata"])

    @field_validator("name")
    @classmethod
    def sanitize_name(cls, v: str) -> str:
        return v.strip()


class ProfileResponse(BaseModel):
    id: uuid.UUID
    name: str
    date_of_birth: str
    time_of_birth: str
    place_name: str
    latitude: float
    longitude: float
    timezone: str
    is_primary: bool

    model_config = {"from_attributes": True}


class AuthVerifyRequest(BaseModel):
    firebase_token: str = Field(..., min_length=10)


class UserResponse(BaseModel):
    user_id: uuid.UUID
    email: str | None
    role: str
    tier: str
    is_new_user: bool
