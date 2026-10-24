"""Pydantic schemas for Invoice models, extraction payloads, and validation."""

from datetime import datetime
from decimal import Decimal
from enum import Enum
from typing import List, Literal, Optional
from pydantic import BaseModel, Field, field_serializer


class InvoiceStatus(str, Enum):
    """Invoice lifecycle states per AGENTS.md Section 5."""
    UPLOADED = "UPLOADED"
    OCR_PROCESSING = "OCR_PROCESSING"
    NEEDS_REVIEW = "NEEDS_REVIEW"
    NEEDS_CORRECTION = "NEEDS_CORRECTION"
    VALIDATED = "VALIDATED"
    APPROVED = "APPROVED"
    POSTING = "POSTING"
    POSTED = "POSTED"
    POST_FAILED = "POST_FAILED"
    RECONCILIATION_REQUIRED = "RECONCILIATION_REQUIRED"


class InvoiceMode(str, Enum):
    """Purchase voucher mode: accounting vs inventory."""
    ACCOUNTING = "accounting"
    INVENTORY = "inventory"


class OCRBoundingBox(BaseModel):
    """Polygon bounding box coordinates [[x1, y1], [x2, y2], [x3, y3], [x4, y4]]."""
    points: List[List[float]]


class OCRLine(BaseModel):
    """Single line extracted by OCR."""
    text: str
    confidence: float = Field(ge=0.0, le=1.0)
    bbox: Optional[List[List[float]]] = None


class OCRResult(BaseModel):
    """Complete raw OCR extraction result."""
    raw_text: str
    lines: List[OCRLine] = Field(default_factory=list)
    page_count: int = 1
    average_confidence: float = Field(default=0.0, ge=0.0, le=1.0)


class ExtractionWarning(BaseModel):
    """Warning or issue identified during extraction or validation."""
    field_name: str
    severity: Literal["info", "warning", "error"] = "warning"
    message: str


class InvoiceLineItem(BaseModel):
    """Single purchase line item with exact Decimal arithmetic."""
    item_description: str
    hsn_sac_code: Optional[str] = None
    quantity: Optional[Decimal] = None
    unit_of_measure: Optional[str] = None
    unit_price: Optional[Decimal] = None
    discount_amount: Optional[Decimal] = Field(default=Decimal("0.00"))
    taxable_amount: Optional[Decimal] = None
    gst_rate_percent: Optional[Decimal] = None
    cgst_amount: Optional[Decimal] = Field(default=Decimal("0.00"))
    sgst_amount: Optional[Decimal] = Field(default=Decimal("0.00"))
    igst_amount: Optional[Decimal] = Field(default=Decimal("0.00"))
    total_line_amount: Optional[Decimal] = None
    confidence_score: Optional[float] = Field(default=1.0, ge=0.0, le=1.0)

    # Master mapping targets
    tally_ledger_name: Optional[str] = None
    tally_item_name: Optional[str] = None

    @field_serializer(
        "quantity",
        "unit_price",
        "discount_amount",
        "taxable_amount",
        "gst_rate_percent",
        "cgst_amount",
        "sgst_amount",
        "igst_amount",
        "total_line_amount",
        when_used="json",
    )
    def serialize_decimal(self, v: Optional[Decimal]) -> Optional[str]:
        """Serialize Decimal as string to prevent JS float precision loss."""
        return str(v) if v is not None else None


class InvoiceExtractedData(BaseModel):
    """Structured bill data parsed by Gemini from raw OCR."""
    invoice_number: Optional[str] = None
    invoice_date: Optional[str] = None  # Expected format YYYY-MM-DD
    supplier_name: Optional[str] = None
    supplier_gstin: Optional[str] = None
    supplier_address: Optional[str] = None
    buyer_name: Optional[str] = None
    buyer_gstin: Optional[str] = None
    place_of_supply: Optional[str] = None

    # Totals and Tax splits (all Decimal)
    subtotal_amount: Optional[Decimal] = None
    cgst_amount: Optional[Decimal] = Field(default=Decimal("0.00"))
    sgst_amount: Optional[Decimal] = Field(default=Decimal("0.00"))
    igst_amount: Optional[Decimal] = Field(default=Decimal("0.00"))
    total_tax_amount: Optional[Decimal] = Field(default=Decimal("0.00"))
    round_off_amount: Optional[Decimal] = Field(default=Decimal("0.00"))
    total_amount: Optional[Decimal] = None

    voucher_type: str = "Purchase"
    invoice_mode: InvoiceMode = InvoiceMode.ACCOUNTING
    line_items: List[InvoiceLineItem] = Field(default_factory=list)

    # Quality indicators
    overall_confidence: float = Field(default=0.0, ge=0.0, le=1.0)
    warnings: List[ExtractionWarning] = Field(default_factory=list)
    raw_ocr_text: Optional[str] = None

    @field_serializer(
        "subtotal_amount",
        "cgst_amount",
        "sgst_amount",
        "igst_amount",
        "total_tax_amount",
        "round_off_amount",
        "total_amount",
        when_used="json",
    )
    def serialize_decimal(self, v: Optional[Decimal]) -> Optional[str]:
        """Serialize Decimal as string for JSON responses."""
        return str(v) if v is not None else None


class InvoiceDetailResponse(BaseModel):
    """Complete invoice record returned by API."""
    id: str
    original_filename: str
    file_hash_sha256: str
    status: InvoiceStatus
    created_at: datetime
    updated_at: datetime
    extracted_data: Optional[InvoiceExtractedData] = None
    tally_voucher_number: Optional[str] = None
    tally_guid: Optional[str] = None


class InvoiceValidationResult(BaseModel):
    """Validation report checking arithmetic, duplicate guard, and GSTIN."""
    is_valid: bool
    status: InvoiceStatus
    errors: List[str] = Field(default_factory=list)
    warnings: List[str] = Field(default_factory=list)
    arithmetic_matches: bool = True
    tax_split_matches: bool = True
    duplicate_suspected: bool = False
