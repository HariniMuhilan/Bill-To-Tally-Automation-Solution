"""Unit tests for OCR Service (Mock and PaddleOCR adapters)."""

import io
from PIL import Image, ImageDraw
import numpy as np
import pytest

from backend.app.schemas.invoice import OCRResult
from backend.app.services.ocr_service import (
    MockOCRAdapter,
    PaddleOCRAdapter,
    load_image_as_numpy,
    get_ocr_service,
)


def create_synthetic_bill_image(text: str = "INVOICE #1024\nTOTAL: 1500.00") -> Image.Image:
    """Helper to draw synthetic high-contrast text on an image."""
    img = Image.new("RGB", (400, 150), color=(255, 255, 255))
    draw = ImageDraw.Draw(img)
    # Simple line drawing for testing
    draw.text((20, 30), text, fill=(0, 0, 0))
    return img


def test_load_image_as_numpy_formats():
    """Verify loading from PIL, Bytes, and BytesIO with RGB normalization."""
    img = create_synthetic_bill_image()

    # 1. Direct PIL
    arr1 = load_image_as_numpy(img)
    assert isinstance(arr1, np.ndarray)
    assert arr1.shape == (150, 400, 3)

    # 2. BytesIO
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    arr2 = load_image_as_numpy(buf)
    assert isinstance(arr2, np.ndarray)
    assert arr2.shape == (150, 400, 3)

    # 3. Raw bytes
    arr3 = load_image_as_numpy(buf.getvalue())
    assert isinstance(arr3, np.ndarray)
    assert arr3.shape == (150, 400, 3)


def test_mock_ocr_adapter():
    """Verify MockOCRAdapter produces structured OCRResult."""
    adapter = MockOCRAdapter()
    result = adapter.extract_from_image(create_synthetic_bill_image())

    assert isinstance(result, OCRResult)
    assert len(result.lines) > 0
    assert "TAX INVOICE" in result.raw_text
    assert result.average_confidence > 0.90
    assert result.lines[0].bbox is not None


def test_factory_returns_correct_adapter():
    """Verify get_ocr_service respects engine configuration."""
    mock_adapter = get_ocr_service("mock")
    assert isinstance(mock_adapter, MockOCRAdapter)

    paddle_adapter = get_ocr_service("paddleocr")
    assert isinstance(paddle_adapter, PaddleOCRAdapter)


def test_paddleocr_adapter_real_inference():
    """Verify PaddleOCRAdapter extracts text, bounding boxes, and confidences from photo image."""
    adapter = PaddleOCRAdapter()
    img = create_synthetic_bill_image("TAX INVOICE")

    result = adapter.extract_from_image(img)

    assert isinstance(result, OCRResult)
    assert len(result.lines) >= 1
    # Check that at least one extracted line contains TAX or INVOICE
    extracted_text = result.raw_text.upper()
    assert "TAX" in extracted_text or "INVOICE" in extracted_text
    assert result.average_confidence > 0.50

    line = result.lines[0]
    assert len(line.bbox) == 4  # 4-point polygon
    assert 0.0 <= line.confidence <= 1.0


def test_paddleocr_adapter_blank_image():
    """Verify handling of blank image does not crash and returns empty result."""
    adapter = PaddleOCRAdapter()
    blank_img = Image.new("RGB", (200, 200), color=(255, 255, 255))

    result = adapter.extract_from_image(blank_img)
    assert isinstance(result, OCRResult)
    assert len(result.lines) == 0
    assert result.raw_text == ""
    assert result.average_confidence == 0.0
