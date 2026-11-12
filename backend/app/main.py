"""FastAPI Application Entry Point for Bill-to-Tally Automation Solution."""

from contextlib import asynccontextmanager
import re
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
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


@app.middleware("http")
async def normalize_slashes_middleware(request: Request, call_next):
    """Normalize consecutive slashes in request paths (e.g. //api/... -> /api/...)."""
    raw_path = request.scope.get("path", "")
    if "//" in raw_path:
        request.scope["path"] = re.sub(r"/+", "/", raw_path)
    return await call_next(request)

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


@app.get("/auth/confirmed", response_class=HTMLResponse, tags=["Authentication"])
@app.get("/email-confirmed", response_class=HTMLResponse, include_in_schema=False)
async def email_confirmed_page():
    """Branded confirmation landing page for Supabase email verification redirects."""
    return HTMLResponse(
        content="""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>BillBooks &bull; Email Confirmed</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;700&display=swap" rel="stylesheet">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'DM Sans', -apple-system, sans-serif; }
    body {
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      background: linear-gradient(135deg, #FBD9C9 0%, #FDE6D6 30%, #FCD9B8 70%, #FBC590 100%);
      padding: 20px;
    }
    .card {
      background: rgba(255, 255, 255, 0.85);
      backdrop-filter: blur(20px);
      -webkit-backdrop-filter: blur(20px);
      border-radius: 28px;
      border: 1px solid rgba(255, 255, 255, 0.9);
      box-shadow: 0 20px 40px rgba(94, 18, 51, 0.12);
      max-width: 440px;
      width: 100%;
      padding: 40px 32px;
      text-align: center;
    }
    .brand-title {
      font-size: 26px;
      font-weight: 700;
      color: #5E1233;
      letter-spacing: -0.5px;
    }
    .brand-subtitle {
      font-size: 10.5px;
      font-weight: 700;
      letter-spacing: 2px;
      color: #966069;
      margin-top: 4px;
      margin-bottom: 28px;
    }
    .icon-wrapper {
      width: 76px;
      height: 76px;
      margin: 0 auto 20px auto;
      border-radius: 50%;
      background: linear-gradient(135deg, #2F9A58 0%, #20713E 100%);
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 10px 24px rgba(47, 154, 88, 0.35);
    }
    .icon-wrapper svg {
      width: 40px;
      height: 40px;
      stroke: white;
      stroke-width: 3;
      fill: none;
    }
    h1 {
      font-size: 21px;
      font-weight: 700;
      color: #4A1530;
      margin-bottom: 12px;
    }
    p {
      font-size: 14.5px;
      line-height: 1.55;
      color: #6A3850;
      margin-bottom: 26px;
    }
    .app-badge {
      display: inline-block;
      background: linear-gradient(135deg, #F26A21 0%, #F0580E 100%);
      color: white;
      text-decoration: none;
      font-weight: 700;
      font-size: 14px;
      padding: 13px 28px;
      border-radius: 20px;
      box-shadow: 0 8px 18px rgba(242, 106, 33, 0.35);
      transition: transform 0.15s ease;
    }
    .app-badge:hover {
      transform: translateY(-1px);
    }
    .footer-note {
      font-size: 12px;
      color: #A38290;
      margin-top: 24px;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="brand-title">BillBooks</div>
    <div class="brand-subtitle">PURCHASE VOUCHER AUTOMATION</div>

    <div class="icon-wrapper">
      <svg viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="20 6 9 17 4 12"></polyline>
      </svg>
    </div>

    <h1>Email Verified Successfully!</h1>
    <p>Your email has been confirmed. You can now return to the <strong>BillBooks</strong> mobile app and sign in with your password.</p>

    <a href="#" class="app-badge" onclick="window.close(); return false;">Return to BillBooks App</a>

    <div class="footer-note">You may safely close this browser window.</div>
  </div>
</body>
</html>
"""
    )


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
