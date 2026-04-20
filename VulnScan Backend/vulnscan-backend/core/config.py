from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """Application settings from environment variables."""

    # Server
    DEBUG: bool = False
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # Firebase
    FIREBASE_PROJECT_ID: str
    FIREBASE_PRIVATE_KEY: str
    FIREBASE_CLIENT_EMAIL: str

    # MongoDB
    MONGODB_URI: str
    MONGODB_DB_NAME: str = "vulnscan"

    # Scanning
    MAX_SCAN_TIMEOUT: int = 300  # 5 minutes
    TEMP_SCAN_DIR: str = "/tmp"

    # External APIs
    CLAUDE_API_KEY: Optional[str] = None
    OPENAI_API_KEY: Optional[str] = None

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
