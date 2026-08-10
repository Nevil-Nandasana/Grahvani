import logging
import watchtower
import boto3
from app.config import settings

def setup_logging():
    """
    Configures centralized logging for the FastAPI application.
    Attaches AWS CloudWatch handler in production environments.
    """
    logging.basicConfig(
        level=settings.LOG_LEVEL,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    logger = logging.getLogger("grahvani_api")
    
    # In production, attach CloudWatch logger
    if settings.APP_ENV == "production" and settings.AWS_REGION:
        try:
            # Assumes standard AWS auth (env vars or IAM role in App Runner)
            boto3_client = boto3.client("logs", region_name=settings.AWS_REGION)
            cw_handler = watchtower.CloudWatchLogHandler(
                log_group_name=settings.AWS_CLOUDWATCH_LOG_GROUP,
                log_stream_name=settings.AWS_CLOUDWATCH_LOG_STREAM,
                boto3_client=boto3_client,
            )
            logging.getLogger().addHandler(cw_handler)
            logger.info("AWS CloudWatch logging initialized")
        except Exception as e:
            logger.error(f"Failed to initialize CloudWatch logging: {e}")
            
    return logger
