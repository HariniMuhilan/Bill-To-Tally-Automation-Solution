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

- `index.html` - Interactive web application interface for invoice inbox, review & validation, master mapping, Tally connector, and audit logs.
- `styles.css` - UI stylesheets with responsive layouts and modern design tokens.
- `app.js` - Application logic, state management, validation engine, Tally XML generator, and simulation pipelines.
- `Ashan_Tech_Labs_Bill_to_Tally_Automation_Proposal.pdf` - Project proposal document.
- `Ashan_Tech_Labs_Final_Bill_to_Tally_Prototype_Specification.pdf` - Technical prototype specification document.

## 🛠️ How to Run

1. Clone this repository:
   ```bash
   git clone https://github.com/HariniMuhilan/Bill-To-Tally-Automation-Solution.git
   ```
2. Open `index.html` in any modern web browser, or serve it using a local static file server:
   ```bash
   # Using Python
   python -m http.server 3000

   # Or using npx
   npx serve .
   ```
3. Connect to your local TallyPrime instance (ensure XML server is enabled on port 9000 in Tally configuration).

## 📄 License

Proprietary / Ashan Tech Labs
