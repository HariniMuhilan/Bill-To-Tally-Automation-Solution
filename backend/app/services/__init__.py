"""Backend business logic and adapter services."""

try:
    from .ocr_service import BaseOCRAdapter, PaddleOCRAdapter, MockOCRAdapter, get_ocr_service
    from .extraction import GeminiExtractionService, get_extraction_service
except (ImportError, ValueError):
    from backend.app.services.ocr_service import BaseOCRAdapter, PaddleOCRAdapter, MockOCRAdapter, get_ocr_service
    from backend.app.services.extraction import GeminiExtractionService, get_extraction_service

__all__ = [
    "BaseOCRAdapter",
    "PaddleOCRAdapter",
    "MockOCRAdapter",
    "get_ocr_service",
    "GeminiExtractionService",
    "get_extraction_service",
]
