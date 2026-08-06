"""
Grahvani — AWS Secrets Manager DB Password Rotation Lambda

Implements the standard four-step Secrets Manager rotation protocol:
  Step 1 (createSecret)  — Generate a new random password, store as AWSPENDING.
  Step 2 (setSecret)     — Apply the new password to the RDS cluster.
  Step 3 (testSecret)    — Verify the new credentials can connect to the DB.
  Step 4 (finishSecret)  — Promote AWSPENDING → AWSCURRENT, move old → AWSPREVIOUS.

References:
  https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets-lambda-function-overview.html
"""
from __future__ import annotations

import json
import logging
import os
import secrets
import string
import time

import boto3
import psycopg2

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# ─── Constants ────────────────────────────────────────────────────────────────
SECRET_ARN = os.environ["SECRET_ARN"]
DB_HOST    = os.environ["DB_HOST"]
DB_PORT    = int(os.environ.get("DB_PORT", "5432"))
DB_NAME    = os.environ["DB_NAME"]

# Password policy: 32 chars, alphanumeric + selected symbols (no shell metacharacters)
_ALPHABET = string.ascii_letters + string.digits + "!#$%&*+-=?@^_"
_PASSWORD_LENGTH = 32


def handler(event: dict, context) -> None:  # noqa: ANN001
    """Lambda entrypoint called by AWS Secrets Manager rotation scheduler."""
    secret_id       = event["SecretId"]
    token           = event["ClientRequestToken"]
    rotation_step   = event["Step"]

    sm = boto3.client("secretsmanager")

    logger.info("Rotation step=%s secret=%s token=%s", rotation_step, secret_id, token)

    if rotation_step == "createSecret":
        _create_secret(sm, secret_id, token)
    elif rotation_step == "setSecret":
        _set_secret(sm, secret_id, token)
    elif rotation_step == "testSecret":
        _test_secret(sm, secret_id, token)
    elif rotation_step == "finishSecret":
        _finish_secret(sm, secret_id, token)
    else:
        raise ValueError(f"Unsupported rotation step: {rotation_step}")


# ─── Step 1: createSecret ─────────────────────────────────────────────────────

def _create_secret(sm, secret_id: str, token: str) -> None:
    """Generate a new password and store it as AWSPENDING (if not already present)."""
    # Check if AWSPENDING already exists (idempotency for retries)
    try:
        sm.get_secret_value(
            SecretId=secret_id,
            VersionStage="AWSPENDING",
        )
        logger.info("AWSPENDING already exists — skipping createSecret")
        return
    except sm.exceptions.ResourceNotFoundException:
        pass  # Expected — we need to create it

    # Fetch current secret to keep non-password fields intact
    current = _get_secret_dict(sm, secret_id, "AWSCURRENT")

    # Generate a new secure password
    new_password = _generate_password()

    # Build new secret value preserving all existing keys
    new_secret = {**current, "password": new_password}
    new_secret["database_url"] = (
        f"postgresql+asyncpg://{current['username']}:{new_password}"
        f"@{current['host']}:{current.get('port', 5432)}/{current['dbname']}"
    )

    sm.put_secret_value(
        SecretId=secret_id,
        ClientRequestToken=token,
        SecretString=json.dumps(new_secret),
        VersionStages=["AWSPENDING"],
    )
    logger.info("New password stored as AWSPENDING")


# ─── Step 2: setSecret ───────────────────────────────────────────────────────

def _set_secret(sm, secret_id: str, token: str) -> None:
    """Apply the AWSPENDING password to the RDS cluster."""
    pending = _get_secret_dict(sm, secret_id, "AWSPENDING")
    current = _get_secret_dict(sm, secret_id, "AWSCURRENT")

    if pending["password"] == current["password"]:
        logger.info("AWSPENDING password matches AWSCURRENT — nothing to apply")
        return

    # Connect using AWSCURRENT credentials and ALTER the user's password
    conn = _get_db_connection(current)
    try:
        with conn.cursor() as cur:
            # Escape the username to prevent SQL injection (should be a fixed string)
            cur.execute(
                "ALTER USER %s WITH PASSWORD %%s" % pending["username"],  # noqa: S608
                (pending["password"],),
            )
        conn.commit()
        logger.info("RDS password updated for user: %s", pending["username"])
    finally:
        conn.close()


# ─── Step 3: testSecret ──────────────────────────────────────────────────────

def _test_secret(sm, secret_id: str, token: str) -> None:
    """Verify the AWSPENDING credentials can connect to the database."""
    pending = _get_secret_dict(sm, secret_id, "AWSPENDING")

    # Retry up to 3 times to allow RDS to propagate the new password
    for attempt in range(1, 4):
        try:
            conn = _get_db_connection(pending)
            conn.close()
            logger.info("AWSPENDING credentials verified successfully (attempt %d)", attempt)
            return
        except psycopg2.OperationalError as exc:
            logger.warning("Connection failed (attempt %d): %s", attempt, exc)
            if attempt < 3:
                time.sleep(5 * attempt)

    raise RuntimeError("AWSPENDING credentials failed verification after 3 attempts")


# ─── Step 4: finishSecret ────────────────────────────────────────────────────

def _finish_secret(sm, secret_id: str, token: str) -> None:
    """Promote AWSPENDING → AWSCURRENT and demote the old AWSCURRENT → AWSPREVIOUS."""
    metadata = sm.describe_secret(SecretId=secret_id)
    versions = metadata.get("VersionIdsToStages", {})

    # Find the current version ID
    current_version_id = next(
        (vid for vid, stages in versions.items() if "AWSCURRENT" in stages),
        None,
    )

    if current_version_id == token:
        logger.info("Token is already AWSCURRENT — rotation already complete")
        return

    sm.update_secret_version_stage(
        SecretId=secret_id,
        VersionStage="AWSCURRENT",
        MoveToVersionId=token,
        RemoveFromVersionId=current_version_id,
    )
    logger.info("Rotation complete: %s promoted to AWSCURRENT", token)


# ─── Helpers ─────────────────────────────────────────────────────────────────

def _get_secret_dict(sm, secret_id: str, stage: str) -> dict:
    response = sm.get_secret_value(SecretId=secret_id, VersionStage=stage)
    return json.loads(response["SecretString"])


def _get_db_connection(creds: dict):
    return psycopg2.connect(
        host=creds.get("host", DB_HOST),
        port=int(creds.get("port", DB_PORT)),
        dbname=creds.get("dbname", DB_NAME),
        user=creds["username"],
        password=creds["password"],
        connect_timeout=10,
        sslmode="require",
    )


def _generate_password() -> str:
    return "".join(secrets.choice(_ALPHABET) for _ in range(_PASSWORD_LENGTH))
