"""Application Configuration using Pydantic Settings."""

from pathlib import Path
from typing import Literal
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

    # Storage and Database
    DATABASE_URL: str = "sqlite:///./bill_to_tally.db"
    DOCUMENT_ROOT: Path = Path("./data")

    # OCR Configuration
    OCR_ENGINE: Literal["paddleocr", "mock"] = "paddleocr"
    OCR_LANG: str = "en"
    OCR_CONFIDENCE_THRESHOLD: float = 0.60

    # Gemini LLM Configuration
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-2.5-flash"

    # Tally Prime Connector (Safety defaults)
    TALLY_HOST: str = "127.0.0.1"
    TALLY_PORT: int = 9000
    TALLY_COMPANY_NAME: str = ""
    TALLY_FORMAT: str = "XML"
    POSTING_ENABLED: bool = False  # NEVER True by default per AGENTS.md rule 1

    def ensure_directories(self) -> None:
        """Create document root and upload directories if they don't exist."""
        self.DOCUMENT_ROOT.mkdir(parents=True, exist_ok=True)
        (self.DOCUMENT_ROOT / "uploads").mkdir(parents=True, exist_ok=True)
        (self.DOCUMENT_ROOT / "processed").mkdir(parents=True, exist_ok=True)


settings = Settings()
