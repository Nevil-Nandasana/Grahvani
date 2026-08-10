"""
Dramatiq Background Task Workers
Entry point: dramatiq app.tasks.worker
"""
import dramatiq
from dramatiq.brokers.redis import RedisBroker
from dramatiq.middleware import Retries, TimeLimit

from app.config import settings

# ─── Broker Setup ─────────────────────────────────────────────────────────────
broker = RedisBroker(url=settings.REDIS_URL)
broker.add_middleware(Retries(max_retries=3))
broker.add_middleware(TimeLimit(time_limit=300_000))  # 5-minute max per task
dramatiq.set_broker(broker)

# Import all task modules so Dramatiq discovers them
from app.tasks import ephemeris  # noqa: E402, F401
from app.tasks import pdf_export  # noqa: E402, F401
from app.tasks import transit_monitor  # noqa: E402, F401
