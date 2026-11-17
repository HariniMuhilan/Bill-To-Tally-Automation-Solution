"""Application Configuration using Pydantic Settings."""

from pathlib import Path
from typing import List, Literal
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Global configuration settings for Bill-to-Tally Backend."""

    model_config = SettingsConfigDict(
        env_file=(".env", "backend/.env", "../.env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # Server Configuration
    APP_ENV: str = "development"
    API_HOST: str = "127.0.0.1"
    API_PORT: int = 8000
    ALLOWED_ORIGINS: str = ""
    MAX_UPLOAD_BYTES: int = 10 * 1024 * 1024  # 10 MB upload cap

    # Authentication (Supabase JWT & Admin)
    AUTH_REQUIRED: bool = True
    SUPABASE_URL: str = ""
    SUPABASE_JWT_SECRET: str = ""
    SUPABASE_SERVICE_ROLE_KEY: str = ""
    ADMIN_EMAILS: str = "admin@billbooks.app,admin@billbooks.in,muhilanharini@gmail.com"
    ACCESS_REQUEST_RATE_LIMIT: int = 20  # Max requests per hour per IP

    # Storage and Database
    DATABASE_URL: str = "sqlite:///./bill_to_tally.db"
    DOCUMENT_ROOT: Path = Path("./data")

    # OCR Configuration
    OCR_ENGINE: Literal["paddleocr", "mock"] = "paddleocr"
    OCR_LANG: str = "en"
    OCR_CONFIDENCE_THRESHOLD: float = 0.60

    # Gemini LLM Configuration
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-3.1-flash-lite"

    # Tally Prime Connector (Safety defaults)
    TALLY_HOST: str = "127.0.0.1"
    TALLY_PORT: int = 9000
    TALLY_COMPANY_NAME: str = ""
    TALLY_FORMAT: str = "XML"
    POSTING_ENABLED: bool = False  # NEVER True by default per AGENTS.md rule 1

    @property
    def is_production(self) -> bool:
        """True when running in production mode."""
        return self.APP_ENV.strip().lower() == "production"

    def get_allowed_origins(self) -> List[str]:
        """Parse explicit CORS origins from ALLOWED_ORIGINS, rejecting wildcards."""
        raw = self.ALLOWED_ORIGINS.strip()
        if not raw:
            return []
        return [
            origin.strip().rstrip("/")
            for origin in raw.split(",")
            if origin.strip() and origin.strip() != "*"
        ]

    def get_admin_emails(self) -> List[str]:
        """Parse lowercase normalized admin emails from comma-separated ADMIN_EMAILS."""
        raw = self.ADMIN_EMAILS.strip()
        if not raw:
            return []
        return [
            email.strip().lower()
            for email in raw.split(",")
            if email.strip()
        ]

    def ensure_directories(self) -> None:
        """Create document root and upload directories if they don't exist."""
        self.DOCUMENT_ROOT.mkdir(parents=True, exist_ok=True)
        (self.DOCUMENT_ROOT / "uploads").mkdir(parents=True, exist_ok=True)
        (self.DOCUMENT_ROOT / "processed").mkdir(parents=True, exist_ok=True)


settings = Settings()
