"""
Grahvani — Application Configuration
Reads all environment variables from .env via Pydantic Settings.
"""
from functools import lru_cache
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # Application
    APP_ENV: str = "development"
    DEBUG: bool = True
    LOG_LEVEL: str = "INFO"
    APP_SECRET_KEY: str = "changeme_32_char_secret"
    CORS_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost:8000"]

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://grahvani_user:grahvani_pass@localhost:5432/grahvani"

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # Firebase
    FIREBASE_SERVICE_ACCOUNT_PATH: str = "./firebase-service-account.json"
    FIREBASE_SERVICE_ACCOUNT_JSON: str = "" # Fallback if injected as raw string
    FIREBASE_PROJECT_ID: str = ""

    # Google AI
    GEMINI_API_KEY: str = ""

    # Google Places (Geocoding)
    GOOGLE_PLACES_API_KEY: str = ""

    # Razorpay
    RAZORPAY_KEY_ID: str = ""
    RAZORPAY_KEY_SECRET: str = ""
    RAZORPAY_WEBHOOK_SECRET: str = ""

    # Apple App Store
    APPLE_BUNDLE_ID: str = "com.grahvani.app"
    APPLE_SHARED_SECRET: str = ""
    APPLE_KEY_ID: str = ""
    APPLE_ISSUER_ID: str = ""
    APPLE_PRIVATE_KEY: str = ""

    # Google Play
    GOOGLE_PLAY_PACKAGE_NAME: str = "com.grahvani.app"
    GOOGLE_SERVICE_ACCOUNT_PATH: str = ""

    # AWS
    AWS_REGION: str = "ap-south-1"
    AWS_S3_BUCKET_NAME: str = "grahvani-private-assets"
    
    # Langfuse
    LANGFUSE_SECRET_KEY: str = ""
    LANGFUSE_PUBLIC_KEY: str = ""
    LANGFUSE_HOST: str = "https://cloud.langfuse.com"


@lru_cache
def get_settings() -> Settings:
    from app.core.aws_secrets import load_secrets_from_aws
    
    settings = Settings()
    
    # In production, parse any JSON secrets injected by App Runner
    if settings.APP_ENV == "production":
        overrides = load_secrets_from_aws()
        for key, value in overrides.items():
            if hasattr(settings, key):
                setattr(settings, key, value)
                
    return settings


settings = get_settings()
