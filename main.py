"""Root-level FastAPI entry point for cloud deployments.
Forwards FastAPI instance from backend.app.main.
"""
from pathlib import Path
import sys

_root = Path(__file__).resolve().parent
_backend = _root / "backend"
if str(_backend) not in sys.path:
    sys.path.insert(0, str(_backend))

try:
    from backend.app.main import app
except ImportError:
    from app.main import app

__all__ = ["app"]
