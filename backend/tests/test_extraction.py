"""Unit tests for Gemini Bill Extraction Service and validation rules."""

from decimal import Decimal
import pytest

from backend.app.schemas.invoice import OCRLine, OCRResult
from backend.app.services.extraction import GeminiExtractionService


def create_sample_ocr_result() -> OCRResult:
    """Create sample OCRResult resembling an Indian GST purchase bill."""
    lines = [
        OCRLine(text="TAX INVOICE", confidence=0.99),
        OCRLine(text="BHARAT FASTENERS & TOOLS PVT LTD", confidence=0.98),
        OCRLine(text="Plot 12, Industrial Estate, Chennai", confidence=0.95),
        OCRLine(text="GSTIN: 33AAAAA1234A1Z5", confidence=0.99),
        OCRLine(text="Invoice No: BFT-2026-4401", confidence=0.97),
        OCRLine(text="Date: 2026-10-24", confidence=0.98),
        OCRLine(text="High Tensile Hex Bolts M12x60 2000.00", confidence=0.95),
        OCRLine(text="Sub Total: 2000.00", confidence=0.98),
        OCRLine(text="CGST @ 9%: 180.00", confidence=0.97),
        OCRLine(text="SGST @ 9%: 180.00", confidence=0.97),
        OCRLine(text="Total Amount: 2360.00", confidence=0.99),
    ]
    raw_text = "\n".join(l.text for l in lines)
    return OCRResult(
        raw_text=raw_text,
        lines=lines,
        page_count=1,
        average_confidence=0.975,
    )


def test_heuristic_extraction_fields():
    """Verify rule-based extraction correctly parses GSTIN, Invoice #, Date, and Amounts."""
    ocr_result = create_sample_ocr_result()
    service = GeminiExtractionService(api_key="")  # Uses heuristic fallback

    extracted = service.extract(ocr_result)

    assert extracted.supplier_gstin == "33AAAAA1234A1Z5"
    assert extracted.invoice_number == "BFT-2026-4401"
    assert extracted.invoice_date == "2026-10-24"
    assert extracted.supplier_name == "BHARAT FASTENERS & TOOLS PVT LTD"
    assert extracted.subtotal_amount == Decimal("2000.00")
    assert extracted.cgst_amount == Decimal("180.00")
    assert extracted.sgst_amount == Decimal("180.00")
    assert extracted.total_amount == Decimal("2360.00")
    assert extracted.overall_confidence > 0.80


def test_arithmetic_discrepancy_warning():
    """Verify warning is added when subtotal + tax does not equal grand total."""
    lines = [
        OCRLine(text="INVOICE #999", confidence=0.98),
        OCRLine(text="GSTIN: 33AAAAA1234A1Z5", confidence=0.98),
        OCRLine(text="Sub Total: 1000.00", confidence=0.98),
        OCRLine(text="CGST: 90.00", confidence=0.98),
        OCRLine(text="SGST: 90.00", confidence=0.98),
        OCRLine(text="Total Amount: 1500.00", confidence=0.98),  # 1000 + 180 != 1500
    ]
    ocr_result = OCRResult(
        raw_text="\n".join(l.text for l in lines),
        lines=lines,
        page_count=1,
        average_confidence=0.98,
    )

    service = GeminiExtractionService(api_key="")
    extracted = service.extract(ocr_result)

    warning_fields = [w.field_name for w in extracted.warnings]
    assert "total_amount" in warning_fields


def test_empty_ocr_does_not_hallucinate():
    """Verify Rule 10: Empty OCR returns empty fields without fabricated values."""
    empty_ocr = OCRResult(raw_text="", lines=[], page_count=1, average_confidence=0.0)
    service = GeminiExtractionService(api_key="")

    extracted = service.extract(empty_ocr)

    assert extracted.invoice_number is None
    assert extracted.supplier_name is None
    assert extracted.total_amount is None
    assert len(extracted.warnings) >= 1


def test_gemini_extraction_with_mock_client():
    """Verify Gemini multimodal API parsing when client returns structured JSON."""
    from unittest.mock import MagicMock

    mock_client = MagicMock()
    mock_response = MagicMock()
    mock_response.text = '''```json
    {
        "invoice_number": "INV-2026-901",
        "invoice_date": "2026-10-24",
        "supplier_name": "ACME Industrial Supplies",
        "supplier_gstin": "27AAAAA0000A1Z5",
        "subtotal_amount": "5000.00",
        "cgst_amount": "450.00",
        "sgst_amount": "450.00",
        "igst_amount": "0.00",
        "total_tax_amount": "900.00",
        "total_amount": "5900.00",
        "invoice_mode": "inventory",
        "line_items": [
            {
                "item_description": "Industrial Steel Bearing 6205",
                "hsn_sac_code": "8482",
                "quantity": "10",
                "unit_of_measure": "PCS",
                "unit_price": "500.00",
                "discount_amount": "0.00",
                "taxable_amount": "5000.00",
                "gst_rate_percent": "18",
                "cgst_amount": "450.00",
                "sgst_amount": "450.00",
                "igst_amount": "0.00",
                "total_line_amount": "5900.00"
            }
        ]
    }
    ```'''
    mock_client.models.generate_content.return_value = mock_response

    service = GeminiExtractionService(api_key="fake-test-key")
    service._client = mock_client

    ocr_result = create_sample_ocr_result()
    extracted = service.extract(ocr_result, image_bytes=b"fake-image-bytes", mime_type="image/jpeg")

    assert extracted.invoice_number == "INV-2026-901"
    assert extracted.supplier_name == "ACME Industrial Supplies"
    assert extracted.supplier_gstin == "27AAAAA0000A1Z5"
    assert extracted.total_amount == Decimal("5900.00")
    assert len(extracted.line_items) == 1
    assert extracted.line_items[0].quantity == Decimal("10")
    assert extracted.line_items[0].unit_price == Decimal("500.00")
    assert extracted.line_items[0].hsn_sac_code == "8482"
    assert mock_client.models.generate_content.called


def test_rate_limiter_and_cache():
    """Verify GeminiRateLimiter blocks requests exceeding limits and cache avoids duplicate calls."""
    from backend.app.services.extraction import GeminiRateLimiter

    limiter = GeminiRateLimiter(max_per_minute=2, max_per_day=3)
    assert limiter.can_request()[0] is True

    limiter.record_request()
    limiter.record_request()
    # 3rd request in same minute should be blocked
    can_call, reason = limiter.can_request()
    assert can_call is False
    assert "rate limit exceeded" in reason

    # Test daily limit
    daily_limiter = GeminiRateLimiter(max_per_minute=10, max_per_day=2)
    daily_limiter.record_request()
    daily_limiter.record_request()
    can_call_daily, daily_reason = daily_limiter.can_request()
    assert can_call_daily is False
    assert "Daily Gemini quota reached" in daily_reason


