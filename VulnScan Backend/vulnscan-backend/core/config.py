"""Application configuration loaded from environment variables."""

from pathlib import Path
import tempfile
from typing import Optional

from pydantic import AliasChoices, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings from environment variables.

    Defaults are intentionally developer-friendly so the API can boot and expose
    health/docs endpoints even before optional services such as Firebase,
    MongoDB Atlas, Claude, Razorpay, or MobSF are configured.
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=True,
        extra="ignore",
        populate_by_name=True,
    )

    # Server
    DEBUG: bool = False
    HOST: str = Field(default="0.0.0.0", validation_alias=AliasChoices("HOST", "API_HOST"))
    PORT: int = Field(default=8000, validation_alias=AliasChoices("PORT", "API_PORT"))

    # Firebase Admin SDK. Configure either FIREBASE_CREDENTIALS_PATH or the
    # inline service-account fields below.
    FIREBASE_PROJECT_ID: str = ""
    FIREBASE_PRIVATE_KEY: str = ""
    FIREBASE_CLIENT_EMAIL: str = ""
    FIREBASE_CREDENTIALS_PATH: Optional[str] = None
    FIREBASE_DATABASE_URL: Optional[str] = None
    FIREBASE_WEB_API_KEY: Optional[str] = None

    # MongoDB
    MONGODB_URI: str = "mongodb://localhost:27017"
    MONGODB_DB_NAME: str = "vulnscan"

    # Scanning
    MAX_SCAN_TIMEOUT: int = 300  # 5 minutes
    TEMP_SCAN_DIR: str = Field(
        default=str(Path(tempfile.gettempdir()) / "vulnscan"),
        validation_alias=AliasChoices("TEMP_SCAN_DIR", "TEMP_DIR"),
    )

    # External APIs / services
    CLAUDE_API_KEY: Optional[str] = None
    OPENAI_API_KEY: Optional[str] = None
    MOBSF_API_KEY: Optional[str] = None
    MOBSF_API_URL: str = "http://localhost:8001/api"

    # Payments
    RAZORPAY_KEY_ID: Optional[str] = None
    RAZORPAY_KEY_SECRET: Optional[str] = None

    # Admin panel access. If set, this email is accepted as an admin in
    # addition to Firebase custom claim `isAdmin=true`.
    ADMIN_EMAIL: Optional[str] = None

    @property
    def has_inline_firebase_credentials(self) -> bool:
        """Return True when inline Firebase service-account fields are present."""
        return all(
            [
                self.FIREBASE_PROJECT_ID,
                self.FIREBASE_PRIVATE_KEY,
                self.FIREBASE_CLIENT_EMAIL,
            ]
        )


settings = Settings()
