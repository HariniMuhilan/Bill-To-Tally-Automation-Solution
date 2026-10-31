"""Gemini LLM Bill Extraction Service.

Transforms raw OCR text and bounding boxes into structured invoice data
matching Pydantic schemas (InvoiceExtractedData, InvoiceLineItem) with strict
adherence to AGENTS.md Hard Safety Rules (Rules 7, 9, 10: no hallucinated values,
precise Decimal arithmetic, and untrusted input sanitization).
"""

from decimal import Decimal, InvalidOperation
import json
import os
import sys
from pathlib import Path
import logging
import re
import time
from typing import Any, Dict, List, Optional

# Ensure project root and backend directory are in sys.path for direct execution or IDE tools
_current_dir = Path(__file__).resolve().parent
_project_root = _current_dir.parent.parent.parent
if str(_project_root) not in sys.path:
    sys.path.insert(0, str(_project_root))
_backend_dir = _project_root / "backend"
if str(_backend_dir) not in sys.path:
    sys.path.insert(0, str(_backend_dir))

try:
    from google import genai
    from google.genai import types
except ImportError:
    import google.genai as genai  # type: ignore
    from google.genai import types  # type: ignore

try:
    from backend.app.core.config import settings
    from backend.app.schemas.invoice import (
        ExtractionWarning,
        InvoiceExtractedData,
        InvoiceLineItem,
        InvoiceMode,
        OCRResult,
    )
except (ImportError, ValueError):
    try:
        from app.core.config import settings
        from app.schemas.invoice import (
            ExtractionWarning,
            InvoiceExtractedData,
            InvoiceLineItem,
            InvoiceMode,
            OCRResult,
        )
    except (ImportError, ValueError):
        # pyrefly: ignore[missing-import]
        from ..core.config import settings
        # pyrefly: ignore[missing-import]
        from ..schemas.invoice import (
            ExtractionWarning,
            InvoiceExtractedData,
            InvoiceLineItem,
            InvoiceMode,
            OCRResult,
        )

logger = logging.getLogger(__name__)

GSTIN_REGEX = re.compile(r"\b[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}\b")
DATE_REGEX = re.compile(r"\b(\d{4}[-/.]\d{1,2}[-/.]\d{1,2}|\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4})\b")


def safe_decimal(val: Any, default: Optional[Decimal] = None) -> Optional[Decimal]:
    """Safely parse input to Decimal without floating-point precision errors."""
    if val is None or val == "":
        return default
    if isinstance(val, Decimal):
        return val
    try:
        # Strip currency symbols, commas, and whitespace
        clean_str = re.sub(r"[^\d.-]", "", str(val).strip())
        if not clean_str:
            return default
        return Decimal(clean_str)
    except (InvalidOperation, ValueError):
        return default


import hashlib
from collections import deque
from datetime import datetime, date


class GeminiRateLimiter:
    """Strict in-memory rate limiter to protect free-tier Gemini API quota.
    
    Enforces:
    - Max 5 requests per 60 seconds (1 minute window)
    - Max 20 requests per calendar day (UTC/Local day)
    """

    def __init__(self, max_per_minute: int = 5, max_per_day: int = 20):
        self.max_per_minute = max_per_minute
        self.max_per_day = max_per_day
        self._minute_timestamps: deque[float] = deque()
        self._current_day: date = datetime.now().date()
        self._daily_count: int = 0

    def can_request(self) -> tuple[bool, Optional[str]]:
        now = time.time()
        today = datetime.now().date()

        # Reset daily counter on date change
        if today != self._current_day:
            self._current_day = today
            self._daily_count = 0

        # Purge timestamps older than 60 seconds
        while self._minute_timestamps and now - self._minute_timestamps[0] > 60:
            self._minute_timestamps.popleft()

        if self._daily_count >= self.max_per_day:
            return False, f"Daily Gemini quota reached ({self._daily_count}/{self.max_per_day} requests today). Using rule-based fallback."

        if len(self._minute_timestamps) >= self.max_per_minute:
            wait_time = int(60 - (now - self._minute_timestamps[0])) + 1
            return False, f"Gemini rate limit exceeded ({len(self._minute_timestamps)}/min). Please wait {wait_time}s before next LLM call."

        return True, None

    def record_request(self) -> None:
        now = time.time()
        self._minute_timestamps.append(now)
        self._daily_count += 1

    @property
    def remaining_today(self) -> int:
        today = datetime.now().date()
        if today != self._current_day:
            return self.max_per_day
        return max(0, self.max_per_day - self._daily_count)

    @property
    def requests_in_current_minute(self) -> int:
        now = time.time()
        while self._minute_timestamps and now - self._minute_timestamps[0] > 60:
            self._minute_timestamps.popleft()
        return len(self._minute_timestamps)


# Global rate limiter and extraction cache singleton
_rate_limiter = GeminiRateLimiter(max_per_minute=5, max_per_day=20)
_extraction_cache: Dict[str, InvoiceExtractedData] = {}


class GeminiExtractionService:
    """Extracts structured purchase bills from OCR results using Gemini."""

    def __init__(self, api_key: Optional[str] = None, model: Optional[str] = None):
        self.api_key = api_key
        self.model_name = model
        self._client: Optional[genai.Client] = None
        self.rate_limiter = _rate_limiter

    def _read_live_gemini_key(self) -> str:
        """Dynamically detect GEMINI_API_KEY from environment or .env files."""
        if self.api_key is not None:
            return self.api_key.strip()
        env_key = os.environ.get("GEMINI_API_KEY", "").strip()
        if env_key and env_key not in ("", "your_gemini_api_key_here"):
            return env_key
        if settings.GEMINI_API_KEY and settings.GEMINI_API_KEY.strip() not in ("", "your_gemini_api_key_here"):
            return settings.GEMINI_API_KEY.strip()
        # Direct check on backend/.env and .env in workspace
        for candidate in [
            Path("backend/.env"),
            Path(".env"),
            Path(__file__).resolve().parent.parent.parent / ".env",
            Path(__file__).resolve().parent.parent.parent.parent / "backend" / ".env",
        ]:
            if candidate.exists() and candidate.is_file():
                try:
                    for line in candidate.read_text(encoding="utf-8").splitlines():
                        line = line.strip()
                        if line.startswith("GEMINI_API_KEY=") and not line.startswith("#"):
                            val = line.split("=", 1)[1].strip().strip("'\"")
                            if val and val != "your_gemini_api_key_here":
                                return val
                except Exception:
                    pass
        return ""

    def _get_model_name(self) -> str:
        """Dynamically detect GEMINI_MODEL from environment or .env files, fallback to gemini-3.8-flash."""
        env_model = os.environ.get("GEMINI_MODEL", "").strip()
        if env_model:
            return env_model
        for candidate in [
            Path("backend/.env"),
            Path(".env"),
            Path(__file__).resolve().parent.parent.parent / ".env",
            Path(__file__).resolve().parent.parent.parent.parent / "backend" / ".env",
        ]:
            if candidate.exists() and candidate.is_file():
                try:
                    for line in candidate.read_text(encoding="utf-8").splitlines():
                        line = line.strip()
                        if line.startswith("GEMINI_MODEL=") and not line.startswith("#"):
                            val = line.split("=", 1)[1].strip().strip("'\"")
                            if val:
                                return val
                except Exception:
                    pass
        return getattr(settings, "GEMINI_MODEL", "gemini-3.8-flash") or "gemini-3.8-flash"

    def _get_client(self) -> Optional[genai.Client]:
        """Lazy loader for Google GenAI client (re-checks for live .env updates)."""
        if self._client is not None and getattr(self, "_cached_key", None) is None:
            # Client was explicitly injected (e.g. in test suite)
            return self._client
        key = self._read_live_gemini_key()
        if not key:
            self._client = None
            return None
        if self._client is not None and getattr(self, "_cached_key", None) == key:
            return self._client
        self._cached_key = key
        self._client = genai.Client(api_key=key)
        return self._client

    def extract(
        self,
        ocr_result: OCRResult,
        image_bytes: Optional[bytes] = None,
        mime_type: str = "image/jpeg",
    ) -> InvoiceExtractedData:
        """Main extraction pipeline: respects strict rate limits, checks cache, and falls back gracefully."""
        if not ocr_result or not ocr_result.raw_text.strip():
            return InvoiceExtractedData(
                overall_confidence=0.0,
                warnings=[
                    ExtractionWarning(
                        field_name="raw_text",
                        severity="error",
                        message="OCR text is empty. Image may be unreadable or blank.",
                    )
                ],
                raw_ocr_text="",
            )

        client = self._get_client()
        is_custom_client = getattr(self, "_client", None) is not None and getattr(self, "_cached_key", None) is None

        # Cache check: if identical OCR text was already extracted, return cached result without consuming quota
        cache_key = hashlib.sha256(ocr_result.raw_text.encode("utf-8")).hexdigest()
        if not is_custom_client and cache_key in _extraction_cache:
            logger.info("Serving Gemini extraction from cache for key %s", cache_key[:12])
            cached = _extraction_cache[cache_key].model_copy(deep=True)
            cached.warnings = list(cached.warnings)
            cached.warnings.append(
                ExtractionWarning(
                    field_name="gemini_cache",
                    severity="info",
                    message="Served from local extraction cache (no Gemini quota used).",
                )
            )
            return cached

        if client:
            # Check rate limiter before calling Gemini
            can_call, limit_reason = self.rate_limiter.can_request()
            if not can_call:
                logger.warning("Gemini rate limit guard triggered: %s. Using heuristic parser.", limit_reason)
                fallback = self._heuristic_fallback(ocr_result)
                fallback.warnings.append(
                    ExtractionWarning(
                        field_name="gemini_rate_limit",
                        severity="warning",
                        message=limit_reason or "Gemini rate limit exceeded. Used fallback parser.",
                    )
                )
                return self._post_process_and_validate(fallback, ocr_result)

            try:
                # Record API call towards minute and daily limits
                self.rate_limiter.record_request()
                logger.info(
                    "Calling Gemini %s (Daily remaining: %d/20, Minute: %d/5)",
                    self._get_model_name(),
                    self.rate_limiter.remaining_today,
                    self.rate_limiter.requests_in_current_minute,
                )

                extracted = self._extract_with_gemini(client, ocr_result, image_bytes, mime_type)
                validated = self._post_process_and_validate(extracted, ocr_result)
                
                # Cache successful extraction
                _extraction_cache[cache_key] = validated.model_copy(deep=True)
                return validated
            except Exception as e:
                logger.warning("Gemini API extraction failed: %s. Falling back to heuristic extractor.", str(e))
                fallback = self._heuristic_fallback(ocr_result)
                fallback.warnings.append(
                    ExtractionWarning(
                        field_name="gemini_api",
                        severity="warning",
                        message=f"Gemini API call failed ({str(e)}). Used fallback rule-based parser.",
                    )
                )
                return self._post_process_and_validate(fallback, ocr_result)
        else:
            logger.info("GEMINI_API_KEY not configured. Using rule-based heuristic extractor.")
            extracted = self._heuristic_fallback(ocr_result)
            extracted.warnings.append(
                ExtractionWarning(
                    field_name="gemini_api_key",
                    severity="info",
                    message="Extracted using rule-based parser (Configure GEMINI_API_KEY in .env for advanced LLM extraction).",
                )
            )
            return self._post_process_and_validate(extracted, ocr_result)

    def _extract_with_gemini(
        self,
        client: genai.Client,
        ocr_result: OCRResult,
        image_bytes: Optional[bytes] = None,
        mime_type: str = "image/jpeg",
    ) -> InvoiceExtractedData:
        """Query Gemini using structured JSON schema output with multimodal visual grounding."""
        prompt = f"""You are an expert accounts payable invoice parsing system for Indian GST invoices and commercial purchase receipts.
Extract structured invoice fields from the bill photo and/or raw OCR text.

CRITICAL RULES (NEVER VIOLATE):
1. NO FABRICATIONS / NO HALLUCINATIONS: If a field is missing, unreadable, or blurry, leave it as null. NEVER invent invoice numbers, GSTINs, or totals.
2. DATES: Format as YYYY-MM-DD. If year is 2 digits (e.g., 25 or 24), map to 2025 or 2024.
3. AMOUNTS: Return exact numeric strings (e.g., "1250.00"). Do NOT round, estimate, or omit decimals.
4. SUPPLIER: Extract the merchant, vendor, or company name accurately from the header or company block.
5. INVOICE / BILL NUMBER: Extract the bill/invoice/receipt number accurately.
6. TAX SPLITS: Extract CGST, SGST, IGST accurately. Intra-state usually has CGST and SGST. Inter-state has IGST.
7. LINE ITEMS: Extract each purchased product or service line item with description, HSN/SAC code, quantity, unit, unit price, taxable amount, and GST rate.
8. DISCOUNT: If the bill contains any trade discount, item discount, or bill-level discount (e.g. '(-) Discount 20.00' or 'Less: Discount'), extract the total discount as a positive numeric string in 'discount_amount' (e.g. '20.00').

RAW OCR TEXT FROM BILL:
{ocr_result.raw_text}

Respond ONLY with a valid JSON object matching this schema:
{{
  "invoice_number": string or null,
  "invoice_date": "YYYY-MM-DD" or null,
  "supplier_name": string or null,
  "supplier_gstin": string or null,
  "supplier_address": string or null,
  "buyer_name": string or null,
  "buyer_gstin": string or null,
  "place_of_supply": string or null,
  "subtotal_amount": "string amount" or null,
  "discount_amount": "string amount" or "0.00",
  "cgst_amount": "string amount" or "0.00",
  "sgst_amount": "string amount" or "0.00",
  "igst_amount": "string amount" or "0.00",
  "total_tax_amount": "string amount" or "0.00",
  "round_off_amount": "string amount" or "0.00",
  "total_amount": "string amount" or null,
  "invoice_mode": "accounting" or "inventory",
  "line_items": [
    {{
      "item_description": string,
      "hsn_sac_code": string or null,
      "quantity": "string number" or null,
      "unit_of_measure": string or null,
      "unit_price": "string amount" or null,
      "discount_amount": "string amount" or "0.00",
      "taxable_amount": "string amount" or null,
      "gst_rate_percent": "string number" or null,
      "cgst_amount": "string amount" or "0.00",
      "sgst_amount": "string amount" or "0.00",
      "igst_amount": "string amount" or "0.00",
      "total_line_amount": "string amount" or null
    }}
  ]
}}"""

        contents: List[Any] = []
        if image_bytes:
            contents.append(types.Part.from_bytes(data=image_bytes, mime_type=mime_type))
        contents.append(prompt)

        primary_model = self._get_model_name()
        candidates = [primary_model] + [m for m in ["gemini-3.5-flash", "gemini-3.8-flash", "gemini-flash-latest"] if m != primary_model]

        response = None
        last_err: Optional[Exception] = None
        for candidate in candidates:
            try:
                response = client.models.generate_content(
                    model=candidate,
                    contents=contents,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        temperature=0.0,
                    ),
                )
                if response:
                    break
            except Exception as e:
                last_err = e
                logger.warning("Gemini model %s call failed (%s), trying next candidate...", candidate, str(e))
                continue

        if response is None and last_err is not None:
            raise last_err

        content_text = response.text or "{}"
        cleaned_text = content_text.strip()
        if cleaned_text.startswith("```"):
            lines_raw = cleaned_text.splitlines()
            if lines_raw[0].startswith("```"):
                lines_raw = lines_raw[1:]
            if lines_raw and lines_raw[-1].strip() == "```":
                lines_raw = lines_raw[:-1]
            cleaned_text = "\n".join(lines_raw).strip()

        data: Dict[str, Any] = json.loads(cleaned_text)

        # Parse line items with Decimal
        line_items: List[InvoiceLineItem] = []
        for item in data.get("line_items", []):
            desc = str(item.get("item_description", "")).strip()
            if not desc:
                continue

            line = InvoiceLineItem(
                item_description=desc,
                hsn_sac_code=item.get("hsn_sac_code"),
                quantity=safe_decimal(item.get("quantity")),
                unit_of_measure=item.get("unit_of_measure"),
                unit_price=safe_decimal(item.get("unit_price")),
                discount_amount=safe_decimal(item.get("discount_amount"), Decimal("0.00")),
                taxable_amount=safe_decimal(item.get("taxable_amount")),
                gst_rate_percent=safe_decimal(item.get("gst_rate_percent")),
                cgst_amount=safe_decimal(item.get("cgst_amount"), Decimal("0.00")),
                sgst_amount=safe_decimal(item.get("sgst_amount"), Decimal("0.00")),
                igst_amount=safe_decimal(item.get("igst_amount"), Decimal("0.00")),
                total_line_amount=safe_decimal(item.get("total_line_amount")),
            )
            line_items.append(line)

        mode_str = str(data.get("invoice_mode", "accounting")).lower()
        mode = InvoiceMode.INVENTORY if mode_str == "inventory" or len(line_items) > 0 else InvoiceMode.ACCOUNTING

        return InvoiceExtractedData(
            invoice_number=data.get("invoice_number"),
            invoice_date=data.get("invoice_date"),
            supplier_name=data.get("supplier_name"),
            supplier_gstin=data.get("supplier_gstin"),
            supplier_address=data.get("supplier_address"),
            buyer_name=data.get("buyer_name"),
            buyer_gstin=data.get("buyer_gstin"),
            place_of_supply=data.get("place_of_supply"),
            subtotal_amount=safe_decimal(data.get("subtotal_amount")),
            discount_amount=safe_decimal(data.get("discount_amount"), Decimal("0.00")),
            cgst_amount=safe_decimal(data.get("cgst_amount"), Decimal("0.00")),
            sgst_amount=safe_decimal(data.get("sgst_amount"), Decimal("0.00")),
            igst_amount=safe_decimal(data.get("igst_amount"), Decimal("0.00")),
            total_tax_amount=safe_decimal(data.get("total_tax_amount"), Decimal("0.00")),
            round_off_amount=safe_decimal(data.get("round_off_amount"), Decimal("0.00")),
            total_amount=safe_decimal(data.get("total_amount")),
            voucher_type="Purchase",
            invoice_mode=mode,
            line_items=line_items,
            raw_ocr_text=ocr_result.raw_text,
        )

    def _heuristic_fallback(self, ocr_result: OCRResult) -> InvoiceExtractedData:
        """Deterministic pattern-matching fallback when Gemini is unavailable or not configured."""
        text = ocr_result.raw_text
        lines = [l.text.strip() for l in ocr_result.lines if l.text.strip()]

        # 1. GSTIN Search
        gstins = GSTIN_REGEX.findall(text)
        supplier_gstin = gstins[0] if gstins else None
        buyer_gstin = gstins[1] if len(gstins) > 1 else None

        # 2. Invoice Number
        invoice_no = None
        for line in lines:
            if line.upper() in ["TAX INVOICE", "INVOICE", "BILL OF SUPPLY", "CASH MEMO"]:
                continue
            inv_match = re.search(
                r"(?i)(?:invoice\s*(?:no|number|#)?|inv\s*(?:no|number|#)?|bill\s*(?:no|number|#)?)[.:\s#-]+([A-Z0-9\-\/]{3,})",
                line,
            )
            if inv_match:
                invoice_no = inv_match.group(1).strip()
                break

        # 3. Date
        date_match = DATE_REGEX.search(text)
        invoice_date = None
        if date_match:
            raw_d = date_match.group(1).replace(".", "-").replace("/", "-")
            parts = raw_d.split("-")
            if len(parts) == 3:
                if len(parts[0]) == 4:
                    invoice_date = f"{parts[0]}-{int(parts[1]):02d}-{int(parts[2]):02d}"
                elif len(parts[2]) == 4:
                    invoice_date = f"{parts[2]}-{int(parts[1]):02d}-{int(parts[0]):02d}"

        # 4. Supplier Name (usually first 1-3 lines before invoice keywords)
        supplier_name = None
        for line in lines[:4]:
            if not any(k in line.upper() for k in ["TAX INVOICE", "INVOICE", "CASH MEMO", "GSTIN", "BILL"]):
                if len(line) > 3:
                    supplier_name = line
                    break

        # 5. Amounts
        total_match = re.search(
            r"(?i)(?:grand\s*total|net\s*amount|total\s*amount|(?<!sub\s)(?<!sub-)total)[\s:₹rs.]*([0-9,]+\.[0-9]{2})",
            text,
        )
        total_amount = safe_decimal(total_match.group(1)) if total_match else None

        subtotal_match = re.search(
            r"(?i)(?:sub\s*total|taxable\s*value|taxable\s*amount)[\s:₹rs.]*([0-9,]+\.[0-9]{2})",
            text,
        )
        subtotal_amount = safe_decimal(subtotal_match.group(1)) if subtotal_match else None

        # 5. Discount Search
        discount_match = re.search(
            r"(?i)(?:[-–(]*\s*discount|[-–(]*\s*disc|rebate|less\s*discount)[\s:₹rs.-]*([0-9,]+\.[0-9]{2})",
            text,
        )
        discount_amount = safe_decimal(discount_match.group(1), Decimal("0.00")) if discount_match else Decimal("0.00")

        cgst_amount = Decimal("0.00")
        sgst_amount = Decimal("0.00")
        igst_amount = Decimal("0.00")

        for line in lines:
            line_upper = line.upper()
            if "CGST" in line_upper:
                amts = re.findall(r"([0-9,]+\.[0-9]{2})", line)
                if amts:
                    cgst_amount = safe_decimal(amts[-1], Decimal("0.00"))
            elif "SGST" in line_upper or "UTGST" in line_upper:
                amts = re.findall(r"([0-9,]+\.[0-9]{2})", line)
                if amts:
                    sgst_amount = safe_decimal(amts[-1], Decimal("0.00"))
            elif "IGST" in line_upper:
                amts = re.findall(r"([0-9,]+\.[0-9]{2})", line)
                if amts:
                    igst_amount = safe_decimal(amts[-1], Decimal("0.00"))

        # 6. Parse candidate line items from middle lines
        line_items: List[InvoiceLineItem] = []
        for line_str in lines:
            # Check if line contains description and a price/amount
            amt_match = re.search(r"([0-9,]+\.[0-9]{2})$", line_str)
            if amt_match:
                amount_val = safe_decimal(amt_match.group(1))
                desc_candidate = line_str[:amt_match.start()].strip()
                if desc_candidate and not any(k in desc_candidate.upper() for k in ["TOTAL", "SUBTOTAL", "CGST", "SGST", "IGST"]):
                    line_items.append(
                        InvoiceLineItem(
                            item_description=desc_candidate,
                            total_line_amount=amount_val,
                            taxable_amount=amount_val,
                            confidence_score=0.85,
                        )
                    )

        return InvoiceExtractedData(
            invoice_number=invoice_no,
            invoice_date=invoice_date,
            supplier_name=supplier_name,
            supplier_gstin=supplier_gstin,
            buyer_gstin=buyer_gstin,
            subtotal_amount=subtotal_amount,
            discount_amount=discount_amount,
            cgst_amount=cgst_amount,
            sgst_amount=sgst_amount,
            igst_amount=igst_amount,
            total_tax_amount=(cgst_amount or Decimal("0")) + (sgst_amount or Decimal("0")) + (igst_amount or Decimal("0")),
            total_amount=total_amount,
            invoice_mode=InvoiceMode.ACCOUNTING if not line_items else InvoiceMode.INVENTORY,
            line_items=line_items,
            raw_ocr_text=text,
        )

    def _post_process_and_validate(
        self, data: InvoiceExtractedData, ocr_result: OCRResult
    ) -> InvoiceExtractedData:
        """Run arithmetic checks, validate GSTIN, and calculate overall quality score."""
        warnings: List[ExtractionWarning] = list(data.warnings)

        # 1. Mandatory Fields Check (AGENTS.md Rule Section 6)
        if not data.supplier_name:
            warnings.append(
                ExtractionWarning(
                    field_name="supplier_name",
                    severity="error",
                    message="Supplier name could not be identified from bill.",
                )
            )

        if not data.invoice_number:
            warnings.append(
                ExtractionWarning(
                    field_name="invoice_number",
                    severity="error",
                    message="Invoice number missing or unreadable.",
                )
            )

        if not data.invoice_date:
            warnings.append(
                ExtractionWarning(
                    field_name="invoice_date",
                    severity="warning",
                    message="Invoice date missing; needs manual review.",
                )
            )

        # 2. GSTIN format check
        if data.supplier_gstin and not GSTIN_REGEX.match(data.supplier_gstin):
            warnings.append(
                ExtractionWarning(
                    field_name="supplier_gstin",
                    severity="warning",
                    message=f"Supplier GSTIN '{data.supplier_gstin}' does not follow the standard 15-character format.",
                )
            )

        # 3. Arithmetic Reconciliation
        calculated_tax = (data.cgst_amount or Decimal("0")) + (data.sgst_amount or Decimal("0")) + (data.igst_amount or Decimal("0"))
        if data.total_tax_amount and abs(data.total_tax_amount - calculated_tax) > Decimal("1.00"):
            warnings.append(
                ExtractionWarning(
                    field_name="total_tax_amount",
                    severity="warning",
                    message=f"Sum of CGST+SGST+IGST ({calculated_tax}) differs from total tax ({data.total_tax_amount}).",
                )
            )

        if data.subtotal_amount and data.total_amount:
            disc = data.discount_amount or Decimal("0.00")
            expected_grand = data.subtotal_amount - disc + calculated_tax + (data.round_off_amount or Decimal("0"))
            diff = abs(data.total_amount - expected_grand)
            if diff > Decimal("1.00"):
                warnings.append(
                    ExtractionWarning(
                        field_name="total_amount",
                        severity="warning",
                        message=f"Arithmetic mismatch: Subtotal ({data.subtotal_amount}) + Tax ({calculated_tax}) differs from Total ({data.total_amount}) by ₹{diff}.",
                    )
                )

        # 4. Overall Confidence
        base_ocr_conf = ocr_result.average_confidence
        fields_present = sum(
            1 for f in [data.supplier_name, data.invoice_number, data.invoice_date, data.total_amount] if f is not None
        )
        field_score = fields_present / 4.0
        overall = round((base_ocr_conf * 0.6) + (field_score * 0.4), 4)

        data.overall_confidence = max(0.0, min(1.0, overall))
        data.warnings = warnings
        return data


_extractor_instance: Optional[GeminiExtractionService] = None


def get_extraction_service() -> GeminiExtractionService:
    """Factory function for GeminiExtractionService singleton."""
    global _extractor_instance
    if _extractor_instance is None:
        _extractor_instance = GeminiExtractionService()
    return _extractor_instance
