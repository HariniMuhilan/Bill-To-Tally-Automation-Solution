import pytest
from backend.app.core.config import settings

@pytest.fixture(autouse=True)
def set_test_environment(monkeypatch):
    """Ensure all tests run under APP_ENV='test'."""
    monkeypatch.setattr(settings, "APP_ENV", "test")
