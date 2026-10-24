"""Backend business logic and adapter services."""

from .ocr_service import BaseOCRAdapter, PaddleOCRAdapter, MockOCRAdapter, get_ocr_service
from .extraction import GeminiExtractionService, get_extraction_service

__all__ = [
    "BaseOCRAdapter",
    "PaddleOCRAdapter",
    "MockOCRAdapter",
    "get_ocr_service",
    "GeminiExtractionService",
    "get_extraction_service",
]
