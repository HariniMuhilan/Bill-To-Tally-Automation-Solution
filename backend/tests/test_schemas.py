"""Unit tests for Invoice schemas and core configuration."""

import json
from decimal import Decimal
from backend.app.core.config import settings
from backend.app.schemas.invoice import (
    InvoiceStatus,
    InvoiceMode,
    InvoiceLineItem,
    InvoiceExtractedData,
    ExtractionWarning,
)


def test_safety_posting_disabled_by_default():
    """Verify Rule 1: POSTING_ENABLED must always be False by default."""
    assert settings.POSTING_ENABLED is False


def test_line_item_decimal_arithmetic_and_serialization():
    """Verify Rule 9: Money is never a float, uses Decimal and serializes to string."""
    item = InvoiceLineItem(
        item_description="Precision Industrial Fasteners",
        hsn_sac_code="7318",
        quantity=Decimal("100"),
        unit_of_measure="NOS",
        unit_price=Decimal("12.50"),
        taxable_amount=Decimal("1250.00"),
        gst_rate_percent=Decimal("18.00"),
        cgst_amount=Decimal("112.50"),
        sgst_amount=Decimal("112.50"),
        total_line_amount=Decimal("1475.00"),
    )

    # Arithmetic checks
    calculated_taxable = item.quantity * item.unit_price
    assert calculated_taxable == item.taxable_amount
    assert item.cgst_amount + item.sgst_amount == Decimal("225.00")
    assert item.taxable_amount + item.cgst_amount + item.sgst_amount == item.total_line_amount

    # Serialization check
    json_data = json.loads(item.model_dump_json())
    assert isinstance(json_data["total_line_amount"], str)
    assert json_data["total_line_amount"] == "1475.00"
    assert isinstance(json_data["quantity"], str)


def test_invoice_extracted_data_defaults_and_states():
    """Verify state machine values and default fields."""
    invoice = InvoiceExtractedData(
        invoice_number="INV/2026/001",
        invoice_date="2026-10-24",
        supplier_name="Acme Corp Ltd",
        supplier_gstin="33AAAAA0000A1Z5",
        subtotal_amount=Decimal("1000.00"),
        cgst_amount=Decimal("90.00"),
        sgst_amount=Decimal("90.00"),
        total_amount=Decimal("1180.00"),
        invoice_mode=InvoiceMode.ACCOUNTING,
        warnings=[
            ExtractionWarning(
                field_name="place_of_supply",
                severity="info",
                message="Derived from supplier GSTIN state code",
            )
        ],
    )

    assert invoice.invoice_mode == InvoiceMode.ACCOUNTING
    assert invoice.total_amount == Decimal("1180.00")
    assert len(invoice.warnings) == 1
    assert InvoiceStatus.UPLOADED.value == "UPLOADED"
    assert InvoiceStatus.NEEDS_REVIEW.value == "NEEDS_REVIEW"
