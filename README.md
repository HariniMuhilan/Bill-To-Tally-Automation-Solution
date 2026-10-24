# Bill-to-Tally Automation Solution

Automated purchase invoice extraction, review, validation, and direct XML voucher posting into TallyPrime. Developed by **Ashan Tech Labs**.

## 🚀 Overview

Bill-to-Tally Automation streamlines the accounts payable workflow by:
- Ingesting PDF purchase invoices and bills
- Extracting header and line-item details (OCR/AI parsing)
- Validating GSTIN, arithmetic, tax splits (CGST/SGST/IGST), and duplicate invoices
- Mapping supplier ledgers and inventory stock items to Tally masters
- Generating Tally-compliant XML vouchers and posting directly to TallyPrime via its XML/HTTP server port (default: 9000)

## 📁 Repository Contents

- `frontend/`
  - `login.html` - Test authentication portal with Sign In, Create Account (Sign Up), and 1-click test credentials quick-fill.
  - `index.html` - Interactive web application interface for invoice inbox, review & validation, master mapping, Tally connector, and audit logs.
  - `styles.css` - UI stylesheets with responsive layouts and modern design tokens.
  - `app.js` - Application logic, state management, validation engine, Tally XML generator, and simulation pipelines.
- `AGENTS.md` - Agent rules and system specifications.

### 🔑 Test Credentials

| Role | Username | Password |
|---|---|---|
| **Reviewer & Approver** | `accounts_user_01` | `tally@2026` |
| **Administrator** | `admin` | `admin@2026` |
| **Data Entry Operator** | `operator` | `operator123` |


## 🛠️ How to Run

1. Clone this repository:
   ```bash
   git clone https://github.com/HariniMuhilan/Bill-To-Tally-Automation-Solution.git
   ```
2. Open `frontend/index.html` in any modern web browser, or serve the directory using a local static file server:
   ```bash
   # Using Python
   python -m http.server 3000 --directory frontend

   # Or using npx
   npx serve frontend
   ```
3. Connect to your local TallyPrime instance (ensure XML server is enabled on port 9000 in Tally configuration).

## 📄 License

Proprietary / Ashan Tech Labs
