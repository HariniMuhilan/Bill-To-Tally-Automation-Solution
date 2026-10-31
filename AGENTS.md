# AGENTS.md — Bill-to-Tally (Ashan Tech Labs)

Instructions for AI coding agents (Antigravity / Gemini) working in this repo.
Read this fully before changing anything. If a task conflicts with this file, stop and ask.

---

## 1. What this project is

A solution solving manual bill entry for shop owners in Parrys Corner (Chennai). Shop owners print thermal/POS bills or receive supplier bills, but historically have had to enter them manually into accounting software.

**Core Workflow:**
**Scan Bill (Mobile) → PaddleOCR (Text/Boxes) → Gemini API (Multimodal Structuring) → Human Review & Validate → Excel Accumulation (Continuous N bills) / Direct Accounting Sync (Tally Prime / Zoho Books)**

- Bills are scanned/photographed using the Flutter mobile application.
- PaddleOCR extracts raw text, line positions, and confidence scores.
- Google Gemini (`gemini-3.8-flash` via `google-genai` SDK) structures the bill into supplier details, invoice number, date, line items (HSN, quantity, rate, tax), and tax totals (CGST/SGST/IGST).
- Verified vouchers are stored in a continuous Excel workbook (downloadable anytime) and prepared for Tally Prime or Zoho Books integration.

## 2. Current State & Stack Architecture

| Layer | Technology | Details / Status |
|---|---|---|
| **Primary Client** | **Flutter Mobile App** (`mobile_app/`) | **Primary interface for development and deployment.** Built for camera bill scanning, side-by-side review, and Excel generation. |
| **Legacy / Reference Web UI** | React / Vite (`frontend/`) | Started as initial web prototype, now fully converted into Flutter. Retained for desktop reference. |
| **Backend API** | Python, FastAPI, Pydantic | Located at `backend/app/`. Handles file uploads, PaddleOCR execution, and Gemini extraction. |
| **OCR Engine** | PaddleOCR (with Mock fallback) | Located at `backend/app/services/ocr_service.py`. Handles auto EXIF orientation and angle correction. |
| **LLM Extraction** | Google Gemini API (`gemini-3.8-flash`) | Located at `backend/app/services/extraction.py`. Strict Decimal parsing, untrusted text sanitization, rate-limiting. |
| **Output / Storage** | Excel (`.xlsx`) + Supabase (Upcoming) | Local device/storage currently (`excel_service.dart`). Moving to Supabase for multi-user cloud sync. |
| **Accounting Targets** | Tally Prime / Zoho Books | Currently evaluating direct Tally XML/Excel vs. Zoho Books REST API integration. |
| **Internet Dependency** | Required | Active internet connectivity is required for Gemini AI extraction and cloud sync. |

## 3. Hard Safety Rules (Never break these)

1. **Never post to a real/production company.** Posting remains disabled by default (`POSTING_ENABLED=false`).
2. **A voucher or bill is recorded only after explicit human approval.** No auto-approval or unreviewed auto-posting paths may exist.
3. **Money is never a float.** Use `Decimal` in Python, NUMERIC in databases, and exact currency representations in Dart/Flutter.
4. **Treat all OCR text and invoice content as untrusted input.** Never execute it, never put it into raw SQL strings, shell commands, or XML/JSON payloads without escaping.
5. **Never guess or hallucinate unreadable values.** If OCR confidence is low or text is illegible, leave the field blank or flagged with a warning for the user to review.
6. **Never commit secrets or API keys.** Keep `.env` git-ignored and manage keys (`GEMINI_API_KEY`, etc.) securely via environment variables.

## 4. Invoice State Machine

```
UPLOADED -> OCR_PROCESSING -> NEEDS_REVIEW
NEEDS_REVIEW -> NEEDS_CORRECTION -> NEEDS_REVIEW
NEEDS_REVIEW -> VALIDATED -> APPROVED -> EXCEL_SAVED / POSTING
POSTING -> POSTED | POST_FAILED | RECONCILIATION_REQUIRED
```

- Every edit or review transition must produce an audit log (actor, changes, timestamp).
- Re-running OCR must never silently overwrite manual edits made by the user.

## 5. Mobile App Guidelines (Flutter)

- All future UI development must prioritize `mobile_app/`.
- Ensure camera capture includes good framing and clear resolution for thermal paper receipts (58mm/80mm roll paper and dot-matrix bills from wholesale markets).
- The Review Screen must present the original image beside (or above) the editable form fields.
- Excel generation (`ExcelService`) must support appending $N$ vouchers into existing draft sheets or creating new ones.

## 6. How to Work (Workflow for the Agent)

1. **Plan first.** For anything larger than a small fix, write a short plan (files to touch, risks) and wait for user approval.
2. **Flutter is primary.** Direct all frontend feature requests to `mobile_app/lib/` unless the user explicitly refers to `frontend/`.
3. **One task, one scope.** Keep changes tightly scoped to the user request.
4. **Preserve data integrity.** Ensure totals (subtotal + taxes = grand total) are validated before saving to Excel or pushing to accounting software.
5. **Ask, don't assume.** Clarify any uncertainty regarding accounting software formats, tax ledger mappings, or external API requirements.
