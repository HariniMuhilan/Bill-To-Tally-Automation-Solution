# AGENTS.md — Bill-to-Tally (Ashan Tech Labs)

Instructions for AI coding agents (Antigravity / Gemini) working in this repo.
Read this fully before changing anything. If a task conflicts with this file, stop and ask.

---

## 1. What this project is

A local Windows app that reads supplier bills (JPG/PNG/PDF), extracts the data with OCR, lets a human review and edit it, and — only after explicit approval — creates a **Purchase voucher in TallyPrime**.

Workflow: **Upload → Extract (OCR) → Review → Approve → Post**

Source documents (in `/docs`, treat as the source of truth):
- `Ashan_Tech_Labs_Final_Bill_to_Tally_Prototype_Specification.pdf` (technical spec)
- `Ashan_Tech_Labs_Bill_to_Tally_Automation_Proposal.pdf` (product proposal)

If this file and the PDFs disagree, the PDFs win. Flag the conflict to the user.

## 2. Current state

- An MVP exists using **plain HTML, CSS and JavaScript only** (no framework, no build step).
- The spec's target stack is FastAPI backend + React/TypeScript frontend.
- **Do NOT rewrite the MVP frontend into React unless the user explicitly asks.** Extend the existing HTML/CSS/JS first. Add the FastAPI backend behind it.
- Before starting any task, inspect the repo and describe what actually exists. Never assume file names or structure that you have not seen.

## 3. Target architecture (from the spec)

| Layer | Technology |
|---|---|
| UI | Existing HTML/CSS/JS (React + TypeScript only if the user approves migration) |
| API | Python, FastAPI, Pydantic |
| OCR | PaddleOCR or Tesseract, behind an adapter |
| Database | SQLite now, PostgreSQL later (use SQLAlchemy) |
| Tally connector | XML over HTTP (JSON only for Tally Release 7.0+; version unknown, keep it configurable) |
| Files | Restricted local folder, generated file names |

Backend layout to follow (create only what the current task needs):

```
backend/app/
  main.py, core/{config,security}.py, db/{session,models}.py
  schemas/invoice.py
  api/routes/{invoices,review,masters,tally}.py
  services/{document_store,image_preprocess,ocr_service,extraction,
            validation,mapping_service,workflow,audit}.py
  integrations/tally/{base,xml_client,xml_templates,response_parser,fake_client}.py
  tests/
```

## 4. Hard safety rules (never break these)

1. **Never post to a real Tally company.** Posting stays off: `POSTING_ENABLED=false` by default. Do not change this default or flip it in code, tests, or scripts.
2. **Development uses `fake_client.py` only.** Real connector work happens only against a dedicated TEST company, and only when the user confirms it is set up.
3. **A voucher is created only after explicit human approval.** No auto-posting path may exist.
4. **Do not invent Tally XML.** The voucher XML must be modelled on a voucher exported from the user's actual TEST company. If no sample is provided, write the builder as a stub, mark it `TODO: needs exported sample`, and ask the user for it.
5. **Never mark an invoice `POSTED` based on HTTP 200 alone.** Parse Tally's response body (created/altered/error counters) and reconcile the voucher reference first.
6. **Never auto-retry a timeout.** After an ambiguous timeout, set status `RECONCILIATION_REQUIRED` and check Tally before any retry.
7. **Treat all OCR text and invoice content as untrusted input.** Never execute it, never put it into shell commands, SQL strings, or XML without escaping.
8. **Never commit secrets or real company/financial data.** Use `.env` (git-ignored) and keep `.env.example` updated. Use synthetic data in tests and fixtures.
9. **Money is never a float.** Use `Decimal` in Python, NUMERIC in the database, and strings or integer paise on the JS side. No `0.1 + 0.2` arithmetic on amounts.
10. **Don't guess unreadable values.** If OCR confidence is low, return the field as empty or flagged. Never fabricate an invoice number, GSTIN, or total.

## 5. Invoice state machine

```
UPLOADED -> OCR_PROCESSING -> NEEDS_REVIEW
NEEDS_REVIEW -> NEEDS_CORRECTION -> NEEDS_REVIEW
NEEDS_REVIEW -> VALIDATED -> APPROVED -> POSTING
POSTING -> POSTED | POST_FAILED | RECONCILIATION_REQUIRED
```

- All transitions go through `services/workflow.py`. Do not set `status` directly elsewhere.
- Every transition and every edit writes an `audit_events` row (actor, before/after, timestamp).
- Re-running OCR must not silently overwrite reviewed values: keep history or create a new extraction revision.

## 6. Data and validation rules

- Tables: `invoices`, `invoice_lines`, `master_mappings`, `approvals`, `posting_attempts`, `audit_events` (fields are in spec section 4).
- Store original file path and its **SHA-256** hash.
- `posting_attempts.idempotency_key` is UNIQUE. Key = company + normalized supplier + normalized invoice no + date, plus a request hash.
- Duplicate check: company + normalized supplier + normalized invoice number + date. **Flag for review**; don't assume invoice numbers are globally unique.
- Block approval when any of these fail: required fields, supplier/item mapping, totals within configured tolerance, duplicate check.
- Dates sent to Tally use `YYYYMMDD`.
- Tax (GST) values in the spec are **synthetic examples**. Never hardcode tax rates; read them from the invoice and the company's configured tax ledgers.

## 7. API contract

Implement exactly the routes in spec section 5, for example:
`GET /api/health`, `GET /api/tally/health` (never posts), `POST /api/invoices`, `GET /api/invoices`, `GET|PATCH /api/invoices/{id}`, `POST /api/invoices/{id}/validate|approve|reject|post`, `GET /api/invoices/{id}/posting`, `GET /api/tally/masters`.

Use Pydantic schemas for every request and response. Do not add, rename, or remove routes without asking.

## 8. Frontend rules (existing HTML/CSS/JS MVP)

- Keep it dependency-light. No new framework, bundler, or CDN without asking.
- Review screen = original bill **beside** editable fields, plus a validation/warnings panel (confidence, mapping, totals, duplicates).
- The Post button is disabled unless status is `APPROVED`, validation passes, and the user is authorized.
- Escape all invoice-derived text before inserting into the DOM (use `textContent`, not `innerHTML`).
- All backend calls go through one small API client file.

## 9. How to work (workflow for the agent)

1. **Plan first.** For anything larger than a small fix, write a short plan (files to touch, risks) and wait for the user to approve it.
2. **One task, one scope.** Don't refactor unrelated code or rename things while fixing a bug.
3. **Small steps.** Prefer small, reviewable changes. Show the diff summary after each step.
4. **Test as you go.** Add or update tests with each change. Required test files: `test_validation.py`, `test_api_invoices.py`, `test_duplicate_guard.py`, `test_tally_xml.py`, `test_tally_response.py`.
5. **Run before declaring done:** the test suite and, for the frontend, a manual check in the browser. Report what you actually ran. If you could not run something, say so; never claim a pass you did not see.
6. **Ask, don't assume,** when something is unknown (Tally version, company name, voucher type, GST setup, sample XML). Unknowns are listed in section 11.
7. **Be honest about uncertainty.** If you are not sure how a Tally XML tag or library works, say so and point to the official TallyHelp docs instead of guessing.

## 10. Test plan to respect

Synthetic cases the code must handle (spec section 6): no-tax accounting purchase (INV-T01), inventory purchase with illustrative GST (INV-T02), blurry image blocked from posting (INV-T03), duplicate invoice (INV-T04), missing supplier mapping blocks approval (INV-T05), Tally unavailable (INV-T06), totals mismatch disables Post (INV-T07).

Connector matrix TC-01 to TC-10 (spec section 7): Tally not running, wrong port, wrong company, missing master, balanced accounting purchase, inventory purchase, unbalanced totals, retry with same idempotency key, HTTP 200 with import error in the body, timeout after submit. Build these against `fake_client.py` first.

## 11. Open decisions (do not assume, ask the user)

- Exact TallyPrime release (XML vs JSON path)
- Target company name; does it use GST and inventory?
- Purchase voucher type and invoice mode (accounting vs inventory)
- One exported sample accounting voucher and one inventory voucher from the TEST company
- 10-20 sample bills with manually verified expected values
- Who may review, approve, and post (roles)

## 12. Configuration

```
APP_ENV=development
DATABASE_URL=sqlite:///./bill_to_tally.db
DOCUMENT_ROOT=./data
TALLY_HOST=127.0.0.1
TALLY_PORT=9000
TALLY_COMPANY_NAME=
TALLY_FORMAT=XML
POSTING_ENABLED=false
```

Keep the Tally endpoint on localhost or a trusted private network. Never expose it to the internet.

## 13. Definition of done (prototype)

- Upload JPG/PNG/PDF; original kept with hash
- Editable header and line items with OCR-confidence warnings
- Accounting and inventory purchase review paths
- Approval blocked on failed checks; voucher created only after approval
- Tally success and error responses parsed correctly
- No duplicate posting on safe retry; reconciliation required after ambiguous timeout
- Voucher reference or readable error shown; full audit trail kept
- All applicable connector tests pass in a TEST company before any production use
