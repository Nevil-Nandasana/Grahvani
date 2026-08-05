"""
Grahvani — Global Exception Handlers & Custom Exception Classes
Converts domain exceptions into standardized JSON error envelopes.
"""
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse


# ─── Custom Exception Classes ─────────────────────────────────────────────────

class GrahvaniException(Exception):
    """Base application exception with structured error response fields."""
    def __init__(self, status_code: int, code: str, message: str, details: dict | None = None):
        self.status_code = status_code
        self.code = code
        self.message = message
        self.details = details or {}


class AuthenticationError(GrahvaniException):
    def __init__(self, message: str = "Authentication failed."):
        super().__init__(status.HTTP_401_UNAUTHORIZED, "AUTHENTICATION_ERROR", message)


class AuthorizationError(GrahvaniException):
    def __init__(self, message: str = "You are not authorized to perform this action."):
        super().__init__(status.HTTP_403_FORBIDDEN, "AUTHORIZATION_ERROR", message)


class EntitlementError(GrahvaniException):
    def __init__(self, message: str = "Upgrade to Premium to access this feature."):
        super().__init__(status.HTTP_403_FORBIDDEN, "ENTITLEMENT_REQUIRED", message)


class NotFoundError(GrahvaniException):
    def __init__(self, resource: str = "Resource"):
        super().__init__(status.HTTP_404_NOT_FOUND, "NOT_FOUND", f"{resource} not found.")


class GuardrailError(GrahvaniException):
    def __init__(self, message: str = "This question falls outside the scope of Vedic astrology."):
        super().__init__(status.HTTP_422_UNPROCESSABLE_ENTITY, "GUARDRAIL_TRIGGERED", message)


# ─── Error Envelope Helper ────────────────────────────────────────────────────

def _error_response(status_code: int, code: str, message: str, details: dict | None = None) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={
            "success": False,
            "error": {
                "code": code,
                "message": message,
                "details": details or {},
            },
        },
    )


# ─── Handler Registration ─────────────────────────────────────────────────────

def register_exception_handlers(app: FastAPI) -> None:
    """Register all global exception handlers on the FastAPI application instance."""

    @app.exception_handler(GrahvaniException)
    async def grahvani_exception_handler(request: Request, exc: GrahvaniException):
        return _error_response(exc.status_code, exc.code, exc.message, exc.details)

    @app.exception_handler(HTTPException)
    async def http_exception_handler(request: Request, exc: HTTPException):
        return _error_response(exc.status_code, "HTTP_ERROR", str(exc.detail))

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        return _error_response(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            "VALIDATION_ERROR",
            "Request body validation failed.",
            {"errors": exc.errors()},
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception):
        return _error_response(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            "INTERNAL_SERVER_ERROR",
            "An unexpected error occurred. Please try again.",
        )
