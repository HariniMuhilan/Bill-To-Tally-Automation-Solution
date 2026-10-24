"""FastAPI Application Entry Point for Bill-to-Tally Automation Solution."""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pathlib import Path
import sys

# Ensure project root and backend directory are in sys.path for direct execution or IDE tools
_current_dir = Path(__file__).resolve().parent
_project_root = _current_dir.parent.parent
if str(_project_root) not in sys.path:
    sys.path.insert(0, str(_project_root))
_backend_dir = _project_root / "backend"
if str(_backend_dir) not in sys.path:
    sys.path.insert(0, str(_backend_dir))
try:
    from backend.app.core.config import settings
    from backend.app.api.routes.invoices import router as invoices_router
except (ImportError, ValueError):
    try:
        from app.core.config import settings
        from app.api.routes.invoices import router as invoices_router
    except (ImportError, ValueError):
        from .core.config import settings
        from .api.routes.invoices import router as invoices_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown hooks."""
    # Ensure document storage directories exist
    settings.ensure_directories()
    yield


app = FastAPI(
    title="Bill-to-Tally Automation API",
    description="Backend API for OCR bill extraction, review, validation, and TallyPrime voucher automation.",
    version="0.1.0",
    lifespan=lifespan,
)

# CORS configuration for local development and frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount routes
app.include_router(invoices_router)


@app.get("/api/health", tags=["System"])
async def api_health():
    """System health check endpoint."""
    return {
        "status": "healthy",
        "app_env": settings.APP_ENV,
        "ocr_engine": settings.OCR_ENGINE,
        "gemini_model": settings.GEMINI_MODEL,
        "posting_enabled": settings.POSTING_ENABLED,
    }


@app.get("/api/tally/health", tags=["Tally"])
async def tally_health():
    """Tally connectivity probe (NEVER attempts posting, read/connectivity only)."""
    return {
        "tally_host": settings.TALLY_HOST,
        "tally_port": settings.TALLY_PORT,
        "posting_enabled": settings.POSTING_ENABLED,
        "connected": False,  # Stubbed until connector client is invoked
        "company": settings.TALLY_COMPANY_NAME or "Not configured",
    }
