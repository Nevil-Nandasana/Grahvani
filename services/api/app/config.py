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
    PROJECT_NAME: str = "Grahvani API"
    PROJECT_VERSION: str = "1.0.0"
    PROJECT_DESCRIPTION: str = "Vedic Astrology Engine API"
    STATIC_FILES_DIRECTORY: str = "static"

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

    # LLM Configuration
    LLM_PROVIDER: str = "google"  # google | nvidia
    LLM_MODEL_NAME: str = "gemini-2.0-flash"  # Default Google Gemini model
    LLM_FALLBACK_PROVIDER: str = "nvidia"  # Fallback when primary fails

    # Reranker Configuration
    RERANKER_ENABLED: bool = True
    RERANKER_TYPE: str = "mock"  # mock | huggingface | sentence_transformers
    RERANKER_MODEL_NAME: str = "BAAI/bge-reranker-large"
    RERANKER_MIN_SCORE_THRESHOLD: float = 0.35
    RERANKER_CANDIDATE_POOL_SIZE: int = 20
    RERANKER_TOP_K: int = 4

    # NVIDIA API (fallback)
    NVIDIA_API_KEY: str = ""
    NVIDIA_MODEL_NAME: str = "nvidia/nemotron-3-ultra-550b-instruct"

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

    # Observability
    SENTRY_DSN: str = ""
    AWS_CLOUDWATCH_LOG_GROUP: str = "grahvani-api-logs"
    AWS_CLOUDWATCH_LOG_STREAM: str = "production"


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
