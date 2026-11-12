"""Root-level app package bridge for cloud deployments (Render, Railway, Fly.io).
Redirects imports to backend/app.
"""
from pathlib import Path
import sys

_root = Path(__file__).resolve().parent.parent
_backend = _root / "backend"
if str(_backend) not in sys.path:
    sys.path.insert(0, str(_backend))

