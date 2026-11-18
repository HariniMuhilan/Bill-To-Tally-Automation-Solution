import pytest
from backend.app.core.config import settings
from backend.app.services.supabase_admin import reset_supabase_admin_for_tests

@pytest.fixture(autouse=True)
def set_test_environment(monkeypatch):
    """Ensure all tests run under APP_ENV='test' with isolated in-memory Supabase client."""
    monkeypatch.setattr(settings, "APP_ENV", "test")
    monkeypatch.setattr(settings, "SUPABASE_SERVICE_ROLE_KEY", "")
    reset_supabase_admin_for_tests()
