# Bill-to-Tally Automation Solution (BillBooks)
### Comprehensive Project Documentation

---

## 1. Project Name
- **Official Name**: Bill-to-Tally Automation Solution
- **Product / Brand Name**: **BillBooks**
- **Organization / Developer**: Ashan Tech Labs

---

## 2. Project Description

### 2.1 Executive Summary
**BillBooks (Bill-to-Tally)** is an intelligent, multi-tenant accounts payable and purchase bill automation system designed to eliminate manual data entry for retail and wholesale business owners (such as merchants in wholesale trading hubs like Parrys Corner, Chennai). 

Traditional businesses process high volumes of thermal paper receipts (58mm/80mm POS rolls), dot-matrix printed bills, and supplier tax invoices. Manually typing each line item, HSN code, tax split, and total into accounting software is slow, expensive, and prone to costly accounting errors. 

BillBooks completely automates this workflow: users capture or upload bill images from a Flutter mobile app, an advanced OCR pipeline extracts coordinates and text blocks, Google Gemini AI structures the unstructured receipt into standardized invoice data, human-in-the-loop review ensures 100% accuracy, and verified records are exported to continuous Excel workbooks or synced directly into **TallyPrime** via native XML integration.

---

### 2.2 Core Workflow Pipeline
```
1. Capture & Ingest
   └── Mobile camera / gallery / PDF file upload (Flutter App)
2. OCR Processing
   └── PaddleOCR / Mock OCR (auto-orientation, bounding boxes, confidence scoring)
3. AI Multimodal Structuring
   └── Google Gemini API (gemini-3.8-flash) extracts Vendor, GSTIN, Invoice #, Date, 
       Line Items (HSN, Qty, Rate, Tax Splits: CGST, SGST, IGST), and Totals
4. Human Review & Verification
   └── Split-screen comparison (original receipt image alongside editable fields)
   └── Real-time arithmetic & tax split validation (Subtotal + Taxes = Grand Total)
5. Export & Accounting Sync
   └── Continuous multi-voucher Excel accumulation (.xlsx)
   └── Direct TallyPrime XML Voucher creation (HTTP port 9000) / Zoho Books ready
```

---

### 2.3 Key Features & Architecture
- **Multi-Tenant Architecture & Single-Device B2B Provisioning**:
  - Secure authentication powered by Supabase Auth with custom JWT claims.
  - Dedicated Admin Dashboard for reviewing access requests, 1-click account provisioning with temporary credentials, and monthly subscription lifecycle management.
  - Dynamic 1-month subscription billing automation with automatic end-date calculation.
- **Robust OCR & Multimodal Intelligence**:
  - Supports thermal rolls, faded carbon receipts, dot-matrix paper, and standard GST tax invoices.
  - Strict decimal arithmetic (no floating-point rounding errors on financial values).
- **Safety First (`POSTING_ENABLED=false` by default)**:
  - Strict human review gate — zero unreviewed vouchers are ever posted to accounting ledgers.
  - Built-in audit trail recording user verification timestamps and line-item corrections.

---

## 3. GitHub Repository Link
- **Repository URL**: [https://github.com/HariniMuhilan/Bill-To-Tally-Automation-Solution](https://github.com/HariniMuhilan/Bill-To-Tally-Automation-Solution)
- **Primary Branch**: `main`

---

## 4. Live Web Links
- **Backend API (Cloud Deployment)**:
  - [https://bill-to-tally-automation-solution-l68w.onrender.com](https://bill-to-tally-automation-solution-l68w.onrender.com)
  - Interactive API Docs (Swagger): [https://bill-to-tally-automation-solution-l68w.onrender.com/docs](https://bill-to-tally-automation-solution-l68w.onrender.com/docs)
- **Frontend / Admin Dashboard (Cloud Deployment)**:
  - [https://bill-to-tally-frontend.onrender.com](https://bill-to-tally-frontend.onrender.com)
- **Local Development Endpoints**:
  - Flutter Mobile / Web Client: `http://127.0.0.1:8080`
  - Admin Management Dashboard: `http://127.0.0.1:3000`
  - FastAPI Core Engine: `http://127.0.0.1:8000`

---

## 5. Mobile App APK
- **Android APK Download**: `[Google Drive Link - To be updated by user]`
  *(Placeholder: Paste your Google Drive link to `app-release.apk` here once uploaded)*

---

## 6. Project Demo Video
- **Walkthrough / Demo Video**: `[Google Drive Link - To be updated by user]`
  *(Placeholder: Paste your Google Drive link to the video walkthrough here once uploaded)*

---

## 7. Project Environment Variables (`.env`)

The project uses decoupled environment configurations across the FastAPI backend, Supabase, and client applications.

### 7.1 Backend Environment Configuration (`backend/.env`)

```ini
# ==========================================
# SERVER & RUNTIME ENVIRONMENT
# ==========================================
APP_ENV=development
API_HOST=127.0.0.1
API_PORT=8000
ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,http://localhost:8080,http://127.0.0.1:8080
MAX_UPLOAD_BYTES=10485760

# ==========================================
# SUPABASE MULTI-TENANT AUTHENTICATION
# ==========================================
AUTH_REQUIRED=true
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_JWT_SECRET=your_supabase_jwt_secret_here
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key_here
ADMIN_EMAILS=admin@billbooks.app
ACCESS_REQUEST_RATE_LIMIT=5

# ==========================================
# DATABASE & DOCUMENT STORAGE
# ==========================================
DATABASE_URL=sqlite:///./bill_to_tally.db
DOCUMENT_ROOT=./data

# ==========================================
# OCR & MULTIMODAL AI CONFIGURATION
# ==========================================
# Engine options: "paddleocr" (production) or "mock" (local dev)
OCR_ENGINE=paddleocr

# Google Gemini API
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-3.8-flash

# ==========================================
# TALLYPRIME INTEGRATION SETTINGS
# ==========================================
TALLY_HOST=127.0.0.1
TALLY_PORT=9000
TALLY_COMPANY_NAME=
TALLY_FORMAT=XML
POSTING_ENABLED=false
```

### 7.2 Variable Explanations
| Variable | Description | Default / Example |
|---|---|---|
| `APP_ENV` | Application environment state | `development` / `production` |
| `API_HOST` / `API_PORT` | Host interface and port for the FastAPI server | `127.0.0.1` : `8000` |
| `ALLOWED_ORIGINS` | Comma-separated list of CORS-permitted frontends | Localhost 3000, 8080, and Render URLs |
| `SUPABASE_URL` | Supabase project instance URL | `https://<ref>.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | Admin service key for user creation and provisioning | Supabase secret key |
| `ADMIN_EMAILS` | Authorized email addresses for B2B Admin Dashboard | `admin@billbooks.app` |
| `GEMINI_API_KEY` | Google GenAI API key for bill parsing | Secret API Key |
| `GEMINI_MODEL` | Gemini LLM model identifier | `gemini-3.8-flash` |
| `TALLY_HOST` / `TALLY_PORT` | TallyPrime local XML server network location | `127.0.0.1:9000` |
| `POSTING_ENABLED` | Hard safety kill-switch for direct Tally ledger posting | `false` (Always human-approved) |

---
*Document prepared for BillBooks / Ashan Tech Labs.*
