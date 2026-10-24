/**
 * Default Seed Mock Data for Bill-to-Tally Automation
 * Ashan Tech Labs
 */

export const INITIAL_INVOICES = [
  {
    id: 'INV-01',
    sourceFilename: 'DeltaTech_Tax_Invoice_891.pdf',
    supplierRaw: 'DELTA TECH ELECTRONICS & SUPPLIES PVT LTD',
    supplierMapped: 'Delta Tech Electronics Pvt Ltd',
    invoiceNo: 'DTE-2026-0891',
    invoiceDate: '2026-10-18',
    tallyDate: '20261018',
    gstin: '33AAAAA1234A1Z5',
    type: 'Inventory Purchase',
    subtotal: 118000.00,
    cgst: 10620.00,
    sgst: 10620.00,
    grandTotal: 139240.00,
    status: 'NEEDS_REVIEW',
    tallyRef: '—',
    confidence: '98.4%',
    lines: [
      {
        lineNo: 1,
        descRaw: 'Industrial Optical Sensor XYZ-400',
        stockItem: 'Sensor Module XYZ-400',
        qty: 10,
        unit: 'NOS',
        rate: 4500.00,
        taxable: 45000.00,
        taxRate: 18,
        taxAmount: 8100.00,
        total: 53100.00,
        confidence: 99.2
      },
      {
        lineNo: 2,
        descRaw: 'Embedded ARM Controller Dev Board v3.2',
        stockItem: 'ARM Controller Board v3.2',
        qty: 25,
        unit: 'NOS',
        rate: 2200.00,
        taxable: 55000.00,
        taxRate: 18,
        taxAmount: 9900.00,
        total: 64900.00,
        confidence: 98.7
      },
      {
        lineNo: 3,
        descRaw: 'Shielded High-Speed Interface Cable 1.5m',
        stockItem: 'Shielded Interface Cable 1.5m',
        qty: 50,
        unit: 'PCS',
        rate: 360.00,
        taxable: 18000.00,
        taxRate: 18,
        taxAmount: 3240.00,
        total: 21240.00,
        confidence: 97.4
      }
    ]
  },
  {
    id: 'INV-02',
    sourceFilename: 'Sri_Vari_Corrugated_Boxes.jpg',
    supplierRaw: 'SRI VARI PACKING & CARTONS',
    supplierMapped: '',
    invoiceNo: 'SVP-4412',
    invoiceDate: '2026-10-17',
    tallyDate: '20261017',
    gstin: '33BCDE1234F1Z8',
    type: 'Accounting Purchase',
    subtotal: 38813.56,
    cgst: 3493.22,
    sgst: 3493.22,
    grandTotal: 45800.00,
    status: 'NEEDS_CORRECTION',
    tallyRef: '—',
    confidence: '91.2%',
    lines: [
      {
        lineNo: 1,
        descRaw: 'Heavy Duty 5-Ply Packing Boxes 18x12x10',
        stockItem: '',
        qty: 500,
        unit: 'NOS',
        rate: 77.62,
        taxable: 38813.56,
        taxRate: 18,
        taxAmount: 6986.44,
        total: 45800.00,
        confidence: 91.2
      }
    ]
  },
  {
    id: 'INV-03',
    sourceFilename: 'Apex_Tools_Workshop_Scan.pdf',
    supplierRaw: 'APEX TOOLS & SPARES LTD',
    supplierMapped: 'Apex Tools & Spares',
    invoiceNo: 'AT-9021',
    invoiceDate: '2026-10-15',
    tallyDate: '20261015',
    gstin: '33CDEF5678G1Z1',
    type: 'Inventory Purchase',
    subtotal: 75000.00,
    cgst: 6750.00,
    sgst: 6750.00,
    grandTotal: 88500.00,
    status: 'APPROVED',
    tallyRef: 'Ready to Post',
    confidence: '99.1%',
    lines: [
      {
        lineNo: 1,
        descRaw: 'Precision Torque Screwdriver Kit 0.1-2.0Nm',
        stockItem: 'Precision Torque Screwdriver',
        qty: 15,
        unit: 'SETS',
        rate: 5000.00,
        taxable: 75000.00,
        taxRate: 18,
        taxAmount: 13500.00,
        total: 88500.00,
        confidence: 99.1
      }
    ]
  },
  {
    id: 'INV-04',
    sourceFilename: 'Precision_Hardware_Fixings.pdf',
    supplierRaw: 'PRECISION HARDWARE FASTENERS',
    supplierMapped: 'Precision Hardware Fasteners',
    invoiceNo: 'PHF-2026-104',
    invoiceDate: '2026-10-12',
    tallyDate: '20261012',
    gstin: '33DEFG9012H1Z4',
    type: 'Inventory Purchase',
    subtotal: 28949.15,
    cgst: 2605.42,
    sgst: 2605.42,
    grandTotal: 34160.00,
    status: 'POSTED',
    tallyRef: 'PUR/2026/0104',
    confidence: '99.8%',
    lines: [
      {
        lineNo: 1,
        descRaw: 'M3 Stainless Steel Hex Standoffs 12mm',
        stockItem: 'M3 Hex Standoffs 12mm',
        qty: 2000,
        unit: 'PCS',
        rate: 14.47,
        taxable: 28949.15,
        taxRate: 18,
        taxAmount: 5210.85,
        total: 34160.00,
        confidence: 99.8
      }
    ]
  },
  {
    id: 'INV-05',
    sourceFilename: 'Mobile_Photo_Store_Bill.jpg',
    supplierRaw: 'SRI GANESH ENTERPRISES [BLURRY]',
    supplierMapped: '',
    invoiceNo: 'SGE-??19',
    invoiceDate: '2026-10-10',
    tallyDate: '20261010',
    gstin: '33ZZZZ9999Z1Z0',
    type: 'Accounting Purchase',
    subtotal: 10550.85,
    cgst: 949.58,
    sgst: 949.58,
    grandTotal: 12450.00,
    status: 'NEEDS_REVIEW',
    tallyRef: '—',
    confidence: '68.5% (LOW)',
    lines: [
      {
        lineNo: 1,
        descRaw: 'General Workshop Consumables & Solvents',
        stockItem: '',
        qty: 1,
        unit: 'LOT',
        rate: 10550.85,
        taxable: 10550.85,
        taxRate: 18,
        taxAmount: 1899.15,
        total: 12450.00,
        confidence: 68.5
      }
    ]
  },
  {
    id: 'INV-06',
    sourceFilename: 'Demo_Stationers_Paper.pdf',
    supplierRaw: 'DEMO STATIONERS PVT LTD',
    supplierMapped: 'Demo Stationers',
    invoiceNo: 'DS-1001',
    invoiceDate: '2026-09-15',
    tallyDate: '20260915',
    gstin: '33AABC1234D1Z2',
    type: 'Accounting Purchase',
    subtotal: 1000.00,
    cgst: 0.00,
    sgst: 0.00,
    grandTotal: 1000.00,
    status: 'POST_FAILED',
    tallyRef: 'Error: Ledger missing in Tally',
    confidence: '99.5%',
    lines: [
      {
        lineNo: 1,
        descRaw: 'Executive Printing & Copier Paper 75GSM',
        stockItem: 'Printing & Stationery Exp',
        qty: 4,
        unit: 'REAMS',
        rate: 250.00,
        taxable: 1000.00,
        taxRate: 0,
        taxAmount: 0.00,
        total: 1000.00,
        confidence: 99.5
      }
    ]
  }
];

export const INITIAL_MAPPINGS = {
  suppliers: [
    { id: 'MAP-SUP-01', raw: 'DELTA TECH ELECTRONICS & SUPPLIES PVT LTD', tally: 'Delta Tech Electronics Pvt Ltd', category: 'Sundry Creditors', guid: 'd41d8cd9-8f00-4b82-9642-120000000001', status: 'VERIFIED', date: '2026-10-18' },
    { id: 'MAP-SUP-02', raw: 'APEX TOOLS & SPARES LTD', tally: 'Apex Tools & Spares', category: 'Sundry Creditors', guid: 'd41d8cd9-8f00-4b82-9642-120000000002', status: 'VERIFIED', date: '2026-10-15' },
    { id: 'MAP-SUP-03', raw: 'PRECISION HARDWARE FASTENERS', tally: 'Precision Hardware Fasteners', category: 'Sundry Creditors', guid: 'd41d8cd9-8f00-4b82-9642-120000000003', status: 'VERIFIED', date: '2026-10-12' },
    { id: 'MAP-SUP-04', raw: 'DEMO STATIONERS PVT LTD', tally: 'Demo Stationers', category: 'Sundry Creditors', guid: 'd41d8cd9-8f00-4b82-9642-120000000004', status: 'VERIFIED', date: '2026-09-15' },
    { id: 'MAP-SUP-05', raw: 'BHARAT INDUSTRIAL OILS & LUBRICANTS', tally: 'Bharat Industrial Oils', category: 'Sundry Creditors', guid: 'd41d8cd9-8f00-4b82-9642-120000000005', status: 'SUGGESTED', date: '2026-10-19' },
    { id: 'MAP-SUP-06', raw: 'SRI VARI PACKING & CARTONS', tally: 'Pending Manual Mapping', category: 'Sundry Creditors', guid: null, status: 'UNMAPPED', date: '—' },
  ],
  items: [
    { id: 'MAP-ITM-01', raw: 'Industrial Optical Sensor XYZ-400', tally: 'Sensor Module XYZ-400', category: 'Sensors & Transducers', guid: 'e10adc39-49ba-42e9-8611-340000000001', status: 'VERIFIED', date: '2026-10-18' },
    { id: 'MAP-ITM-02', raw: 'Embedded ARM Controller Dev Board v3.2', tally: 'ARM Controller Board v3.2', category: 'Microcontrollers', guid: 'e10adc39-49ba-42e9-8611-340000000002', status: 'VERIFIED', date: '2026-10-18' },
    { id: 'MAP-ITM-03', raw: 'Shielded High-Speed Interface Cable 1.5m', tally: 'Shielded Interface Cable 1.5m', category: 'Cables & Wiring', guid: 'e10adc39-49ba-42e9-8611-340000000003', status: 'VERIFIED', date: '2026-10-18' },
    { id: 'MAP-ITM-04', raw: 'Precision Torque Screwdriver Kit', tally: 'Precision Torque Screwdriver', category: 'Tools & Fixtures', guid: 'e10adc39-49ba-42e9-8611-340000000004', status: 'VERIFIED', date: '2026-10-15' },
    { id: 'MAP-ITM-05', raw: 'M3 Stainless Steel Hex Standoffs 12mm', tally: 'M3 Hex Standoffs 12mm', category: 'Hardware Fasteners', guid: 'e10adc39-49ba-42e9-8611-340000000005', status: 'VERIFIED', date: '2026-10-12' },
  ],
  ledgers: [
    { id: 'MAP-LED-01', raw: 'Purchase Accounts 18% GST', tally: 'Purchase - GST 18%', category: 'Purchase Accounts', guid: 'c31d8cd9-8f00-4b82-9642-120000000010', status: 'VERIFIED', date: '2026-09-01' },
    { id: 'MAP-LED-02', raw: 'Printing and Stationery Expenses', tally: 'Printing & Stationery Exp', category: 'Indirect Expenses', guid: 'c31d8cd9-8f00-4b82-9642-120000000011', status: 'VERIFIED', date: '2026-09-01' },
    { id: 'MAP-LED-03', raw: 'Input CGST 9%', tally: 'Input CGST @ 9%', category: 'Duties & Taxes', guid: 'c31d8cd9-8f00-4b82-9642-120000000012', status: 'VERIFIED', date: '2026-09-01' },
    { id: 'MAP-LED-04', raw: 'Input SGST 9%', tally: 'Input SGST @ 9%', category: 'Duties & Taxes', guid: 'c31d8cd9-8f00-4b82-9642-120000000013', status: 'VERIFIED', date: '2026-09-01' },
  ],
  units: [
    { id: 'MAP-UNT-01', raw: 'NOS / NUMBERS', tally: 'NOS (Numbers)', category: 'Simple Unit', guid: null, status: 'VERIFIED', date: '2026-09-01' },
    { id: 'MAP-UNT-02', raw: 'PCS / PIECES', tally: 'PCS (Pieces)', category: 'Simple Unit', guid: null, status: 'VERIFIED', date: '2026-09-01' },
    { id: 'MAP-UNT-03', raw: 'SETS / KITS', tally: 'SETS (Sets)', category: 'Simple Unit', guid: null, status: 'VERIFIED', date: '2026-09-01' },
    { id: 'MAP-UNT-04', raw: 'REAMS', tally: 'RMS (Reams)', category: 'Simple Unit', guid: null, status: 'VERIFIED', date: '2026-09-01' },
  ]
};

export const INITIAL_POSTING_ATTEMPTS = [
  {
    id: 'ATT-2026-0042',
    invoiceId: 'INV-04',
    idempotencyKey: 'ATL_TEST:PRECISION:PHF-2026-104:20261012',
    voucherNo: 'PUR/2026/0104',
    startedAt: '2026-10-12 14:32:01',
    status: 'POSTED',
    responseMessage: 'Tally import accepted (CREATED: 1, ERRORS: 0)'
  },
  {
    id: 'ATT-2026-0041',
    invoiceId: 'INV-06',
    idempotencyKey: 'ATL_TEST:DEMO_STAT:DS-1001:20260915',
    voucherNo: '—',
    startedAt: '2026-09-15 16:11:45',
    status: 'FAILED',
    responseMessage: 'Tally error: Ledger "Demo Stationers" not found in active company'
  },
  {
    id: 'ATT-2026-0040',
    invoiceId: 'INV-03',
    idempotencyKey: 'ATL_TEST:APEX_TOOLS:AT-9021:20261015',
    voucherNo: '—',
    startedAt: '2026-10-15 11:20:00',
    status: 'VALIDATED',
    responseMessage: 'Awaiting operator trigger; idempotency hash pre-computed'
  }
];

export const INITIAL_AUDIT_LOGS = [
  {
    time: '2026-10-23 19:14:02',
    actor: 'accounts_user_01',
    action: 'APPROVAL_RECORDED',
    summary: 'Approved invoice draft for Delta Tech Electronics (DTE-2026-0891)',
    diff: {
      status: { before: 'NEEDS_REVIEW', after: 'APPROVED' },
      verified_by: { before: null, after: 'accounts_user_01' }
    }
  },
  {
    time: '2026-10-23 18:45:10',
    actor: 'accounts_user_01',
    action: 'LINE_ITEM_MAPPING_UPDATED',
    summary: 'Mapped raw item "Industrial Optical Sensor XYZ-400" to Tally Stock Item "Sensor Module XYZ-400"',
    diff: {
      line_1_stock_item: { before: 'UNMAPPED', after: 'Sensor Module XYZ-400' }
    }
  },
  {
    time: '2026-10-23 18:30:22',
    actor: 'system_ocr_worker',
    action: 'OCR_EXTRACTION_COMPLETED',
    summary: 'PaddleOCR engine processed 3 line items with 98.4% average confidence',
    diff: {
      status: { before: 'OCR_PROCESSING', after: 'NEEDS_REVIEW' },
      total_extracted: '₹ 1,39,240.00'
    }
  },
  {
    time: '2026-10-23 18:29:48',
    actor: 'accounts_user_01',
    action: 'DOCUMENT_UPLOADED',
    summary: 'Source file "DeltaTech_Tax_Invoice_891.pdf" saved to ./data/incoming/',
    diff: {
      file_sha256: 'a6f9c8d1e2b34a5c6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d'
    }
  }
];
