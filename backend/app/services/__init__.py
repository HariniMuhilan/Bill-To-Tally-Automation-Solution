"""Backend business logic and adapter services."""

from .ocr_service import BaseOCRAdapter, PaddleOCRAdapter, MockOCRAdapter, get_ocr_service

__all__ = [
    "BaseOCRAdapter",
    "PaddleOCRAdapter",
    "MockOCRAdapter",
    "get_ocr_service",
]
