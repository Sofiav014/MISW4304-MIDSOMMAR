import os
import logging
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

# Get database configuration from environment variables
db_user = os.getenv("DB_USER", "postgres")
db_pass = os.getenv("DB_PASSWORD", "postgres")
db_host = os.getenv("DB_HOST", "database-1-midsommar.ccr8u60ck1r6.us-east-1.rds.amazonaws.com")
db_name = os.getenv("DB_NAME", "postgres")
# Ensure db_port has a valid default value if empty or not set
db_port = os.getenv("DB_PORT", "").strip() or "5432"

# Log environment variables (without sensitive data)
logger.info("=" * 50)
logger.info("Database Configuration:")
logger.info(f"  DB_USER: {'***' if db_user else 'Not set'}")
logger.info(f"  DB_PASSWORD: {'***' if db_pass else 'Not set'}")
logger.info(f"  DB_HOST: {db_host if db_host else 'Not set'}")
logger.info(f"  DB_PORT: {db_port}")
logger.info(f"  DB_NAME: {db_name if db_name else 'Not set'}")
logger.info("=" * 50)

class Config:
    # Use PostgreSQL if environment variables are set, otherwise SQLite for local development
    if db_user and db_pass and db_host and db_name:
        # Production: PostgreSQL (AWS RDS)
        SQLALCHEMY_DATABASE_URI = f"postgresql://{db_user}:{db_pass}@{db_host}/{db_name}"
        logger.info(f"Using PostgreSQL database: {db_host}/{db_name}")
    else:
        # Development: SQLite (local testing)
        SQLALCHEMY_DATABASE_URI = "sqlite:///blacklist_test.db"
        logger.info("Using SQLite database (development mode)")
    
    SQLALCHEMY_TRACK_MODIFICATIONS = False


class TestingConfig(Config):
    SQLALCHEMY_DATABASE_URI = "sqlite:///test_database.db"
    TESTING = True