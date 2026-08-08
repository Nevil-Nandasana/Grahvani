"""
Grahvani — Firebase JWT Authentication Security Layer
"""
import uuid
from typing import Annotated, Any

import firebase_admin
from fastapi import Depends, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth as firebase_auth, credentials

from app.config import settings
from app.core.exceptions import AuthenticationError

# ─── Firebase Admin SDK Initialization ───────────────────────────────────────
_firebase_initialized = False

def _init_firebase():
    global _firebase_initialized
    if not _firebase_initialized:
        cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True


_init_firebase()

# ─── HTTP Bearer Scheme ───────────────────────────────────────────────────────
_security_scheme = HTTPBearer(auto_error=True)


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(_security_scheme)],
) -> dict[str, Any]:
    """
    FastAPI dependency that verifies the Firebase ID token in the Authorization header.
    Returns the decoded token payload containing firebase_uid, email, phone_number.

    Raises:
        AuthenticationError: If the token is invalid, expired, or revoked.
    """
    token = credentials.credentials

    # Development mode demo token bypass for offline/local testing
    if settings.APP_ENV == "development" and token.startswith("demo-"):
        return {
            "uid": "demo-user-uid-12345",
            "email": "demo@grahvani.ai",
            "phone_number": "+919999999999",
            "user_id": "demo-user-uid-12345",
        }

    try:
        decoded_token = firebase_auth.verify_id_token(token, check_revoked=True)
        return decoded_token
    except firebase_auth.RevokedIdTokenError:
        raise AuthenticationError("Authentication token has been revoked. Please sign in again.")
    except firebase_auth.ExpiredIdTokenError:
        raise AuthenticationError("Authentication token has expired. Please refresh and retry.")
    except firebase_auth.InvalidIdTokenError:
        raise AuthenticationError("Authentication token is invalid.")
    except Exception as e:
        raise AuthenticationError(f"Authentication failed: {str(e)}")


# Convenience type alias for route function signatures
CurrentUser = Annotated[dict[str, Any], Depends(get_current_user)]
