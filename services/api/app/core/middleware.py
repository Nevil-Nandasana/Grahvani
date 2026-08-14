"""
Grahvani — Request ID & Logging Middleware
"""
import time
import uuid

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint

from app.config import settings


class RequestIDMiddleware(BaseHTTPMiddleware):
    """
    Adds a unique X-Request-ID header to every request and response for distributed tracing.
    Also logs request method, path, status code, and execution time.
    """
    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id

        start_time = time.perf_counter()
        response: Response = await call_next(request)
        duration_ms = (time.perf_counter() - start_time) * 1000

        response.headers["X-Request-ID"] = request_id
        response.headers["X-Response-Time-Ms"] = f"{duration_ms:.2f}"

        return response


def add_middleware(app: FastAPI) -> None:
    """Register CORS and RequestID tracing middleware onto the FastAPI app instance."""
    app.add_middleware(RequestIDMiddleware)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ALLOWED_ORIGINS,
        allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

