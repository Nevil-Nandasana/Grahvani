"""
AWS Secrets Manager Runtime Integration

When running in AWS App Runner (APP_ENV=production), Secrets Manager ARNs are passed
as environment variables via the `runtime_environment_secrets` configuration.
However, because complex secrets (like database credentials) are stored as JSON strings,
we need to parse them at runtime and inject them into our Pydantic Settings instance.
"""
import json
import logging
import os
from typing import Any, Dict

logger = logging.getLogger(__name__)


def load_secrets_from_aws() -> Dict[str, Any]:
    """
    In production, App Runner injects secrets as environment variables.
    However, some secrets (like the database URL) are stored inside a JSON string
    in Secrets Manager, and App Runner's native integration might not extract
    all nested keys cleanly if we need composite values.
    
    Fortunately, we mapped the ARNs directly in Terraform using the syntax:
    "DB_SECRET_ARN" = aws_secretsmanager_secret.db_credentials.arn
    
    Wait, App Runner natively supports injecting specific keys from JSON secrets
    if configured correctly in Terraform (e.g., `arn:aws:secretsmanager...:secret_key::`).
    
    If we rely purely on App Runner's native injection, `os.environ` will already
    contain the resolved secrets. We just need to handle the JSON parsing for
    composite secrets if we injected the whole JSON block.
    
    Let's check if there are any JSON blocks in os.environ that need parsing.
    """
    overrides: Dict[str, Any] = {}
    
    # Example: DB_SECRET_ARN might contain the raw JSON string if App Runner 
    # couldn't parse it, or we might need to parse it ourselves if we fetched it manually.
    # Since we used `runtime_environment_secrets` in Terraform, AWS automatically
    # fetches the secret and populates the env var. 
    
    # If the env var contains JSON (e.g., RAZORPAY_SECRET_ARN), parse it:
    razorpay_raw = os.environ.get("RAZORPAY_SECRET_ARN")
    if razorpay_raw and razorpay_raw.startswith("{"):
        try:
            data = json.loads(razorpay_raw)
            overrides["RAZORPAY_KEY_ID"] = data.get("key_id", "")
            overrides["RAZORPAY_KEY_SECRET"] = data.get("key_secret", "")
            overrides["RAZORPAY_WEBHOOK_SECRET"] = data.get("webhook_secret", "")
        except json.JSONDecodeError:
            logger.warning("Failed to parse RAZORPAY_SECRET_ARN as JSON")

    db_raw = os.environ.get("DB_SECRET_ARN")
    if db_raw and db_raw.startswith("{"):
        try:
            data = json.loads(db_raw)
            overrides["DATABASE_URL"] = data.get("database_url", "")
        except json.JSONDecodeError:
            logger.warning("Failed to parse DB_SECRET_ARN as JSON")

    apple_raw = os.environ.get("APPLE_SECRET_ARN")
    if apple_raw and apple_raw.startswith("{"):
        try:
            data = json.loads(apple_raw)
            overrides["APPLE_BUNDLE_ID"] = data.get("bundle_id", "")
            overrides["APPLE_SHARED_SECRET"] = data.get("shared_secret", "")
            overrides["APPLE_KEY_ID"] = data.get("key_id", "")
            overrides["APPLE_ISSUER_ID"] = data.get("issuer_id", "")
            overrides["APPLE_PRIVATE_KEY"] = data.get("private_key", "")
        except json.JSONDecodeError:
            logger.warning("Failed to parse APPLE_SECRET_ARN as JSON")

    # Firebase service account is usually a JSON file. If it's passed as a raw JSON string
    # in FIREBASE_SECRET_ARN, we need to handle it. The config expects a path, so we
    # might need to write it to a temp file or modify the Firebase initialization to accept a dict.
    # For now, we will just parse it and let the config handle it.
    firebase_raw = os.environ.get("FIREBASE_SECRET_ARN")
    if firebase_raw and firebase_raw.startswith("{"):
        # We store the raw JSON string in a new variable that config.py can use
        overrides["FIREBASE_SERVICE_ACCOUNT_JSON"] = firebase_raw

    return overrides
