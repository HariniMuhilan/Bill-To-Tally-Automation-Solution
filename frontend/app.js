/**
 * Bill-to-Tally Automation - Frontend Application Logic
 * Ashan Tech Labs | TallyPrime Purchase Voucher Automation
 */

// ============================================================================
// 1. Mock Datasets & State Management
// ============================================================================

const state = {
  activeTab: 'inbox',
  currentInvoiceId: 'INV-01',
  zoomLevel: 100,
  rotationAngle: 0,
  showBBoxes: true,
  postingEnabled: false,
  activeFilter: 'all',
  activeMappingType: 'suppliers',
};

const mockInvoices = [
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

const mockMappings = {
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

const mockPostingAttempts = [
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

const mockAuditTimeline = [
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

// ============================================================================
// 2. DOM Elements Cache
// ============================================================================

const dom = {
  navItems: document.querySelectorAll('.sidebar-nav .nav-item'),
  tabPanes: document.querySelectorAll('.tab-pane'),
  pageTitle: document.querySelector('#current-page-title span'),
  pageIcon: document.querySelector('#current-page-title i'),
  pageDesc: document.getElementById('current-page-desc'),
  invoicesTbody: document.getElementById('invoices-table-body'),
  inboxSearch: document.getElementById('inbox-search-input'),
  filterPills: document.querySelectorAll('.filter-pill'),
  reviewSampleSelect: document.getElementById('review-sample-select'),
  reviewStatusBadge: document.getElementById('review-active-status-badge'),
  docViewport: document.getElementById('rendered-bill-paper'),
  zoomInBtn: document.getElementById('zoom-in-btn'),
  zoomOutBtn: document.getElementById('zoom-out-btn'),
  rotateBtn: document.getElementById('rotate-btn'),
  toggleBBoxesBtn: document.getElementById('toggle-bboxes-btn'),
  zoomLevelText: document.getElementById('zoom-level-text'),
  lineItemsTbody: document.getElementById('line-items-tbody'),
  sumTaxableDisplay: document.getElementById('sum-taxable-display'),
  sumGstDisplay: document.getElementById('sum-gst-display'),
  sumGrandDisplay: document.getElementById('sum-grand-display'),
  btnRejectInvoice: document.getElementById('btn-reject-invoice'),
  btnSaveDraft: document.getElementById('btn-save-draft'),
  btnPreviewXml: document.getElementById('btn-preview-xml'),
  btnApprovePost: document.getElementById('btn-approve-post'),
  modalXml: document.getElementById('modal-xml-inspector'),
  modalPostConfirm: document.getElementById('modal-post-confirm'),
  xmlCodeView: document.getElementById('xml-modal-content'),
  toastContainer: document.getElementById('toast-container'),
  mappingTabs: document.querySelectorAll('.mapping-tab-btn'),
  mappingsTbody: document.getElementById('mappings-table-body'),
  postingAttemptsTbody: document.getElementById('posting-attempts-tbody'),
  auditTimeline: document.getElementById('audit-timeline-container'),
  safetyToggle: document.getElementById('setting-posting-enabled'),
  safetyIndicator: document.getElementById('posting-safety-indicator'),
  btnViewRawOcr: document.getElementById('btn-view-raw-ocr'),
  modalOcr: document.getElementById('modal-ocr-inspector'),
  ocrModalContent: document.getElementById('ocr-modal-content'),
  ocrModalMeta: document.getElementById('ocr-modal-meta'),
  closeOcrBtn: document.getElementById('close-modal-ocr-btn'),
  doneOcrBtn: document.getElementById('btn-done-ocr'),
  copyOcrBtn: document.getElementById('btn-copy-ocr'),
  dropzoneBox: document.getElementById('upload-dropzone-box')
};

const API_BASE_URL = 'http://127.0.0.1:8000';
let defaultBillPaperHtml = '';

// ============================================================================
// 3. Navigation & Tab Switching
// ============================================================================

const tabMeta = {
  inbox: {
    title: 'Invoice Inbox',
    desc: 'Review incoming supplier invoices, OCR status, and posting progress',
    iconClass: 'fa-solid fa-inbox'
  },
  review: {
    title: 'Review & Validate Invoice',
    desc: 'Side-by-side verification: original document preview against extracted accounting fields',
    iconClass: 'fa-solid fa-magnifying-glass-chart'
  },
  mappings: {
    title: 'Master Mappings Registry',
    desc: 'Map raw OCR descriptions & supplier names to corresponding TallyPrime master ledgers',
    iconClass: 'fa-solid fa-diagram-project'
  },
  tally: {
    title: 'TallyPrime Connector & Gateway Logs',
    desc: 'Inspect XML HTTP transport, endpoint health, and immutable posting attempt history',
    iconClass: 'fa-solid fa-server'
  },
  audit: {
    title: 'Audit Trail & Compliance Log',
    desc: 'Full forensic lifecycle tracking of user edits, approvals, and system state changes',
    iconClass: 'fa-solid fa-clock-rotate-left'
  },
  settings: {
    title: 'Configuration & Safety Parameters',
    desc: 'Tally connection settings, idempotency rules, rounding tolerance, and role boundaries',
    iconClass: 'fa-solid fa-sliders'
  }
};

function switchTab(tabId) {
  state.activeTab = tabId;

  dom.navItems.forEach(item => {
    if (item.dataset.tab === tabId) {
      item.classList.add('active');
    } else {
      item.classList.remove('active');
    }
  });

  dom.tabPanes.forEach(pane => {
    if (pane.id === `tab-${tabId}`) {
      pane.classList.add('active');
    } else {
      pane.classList.remove('active');
    }
  });

  const meta = tabMeta[tabId];
  if (meta) {
    dom.pageTitle.textContent = meta.title;
    dom.pageDesc.textContent = meta.desc;
    dom.pageIcon.className = meta.iconClass;
  }

  // Refresh view contents
  if (tabId === 'inbox') renderInboxTable();
  if (tabId === 'review') loadInvoiceForReview(state.currentInvoiceId);
  if (tabId === 'mappings') renderMappingsTable();
  if (tabId === 'tally') renderPostingAttempts();
  if (tabId === 'audit') renderAuditTimeline();
}

dom.navItems.forEach(item => {
  item.addEventListener('click', () => {
    switchTab(item.dataset.tab);
  });
});

// ============================================================================
// 4. TAB 1: Inbox & Dashboard Logic
// ============================================================================

function renderInboxTable() {
  const searchTerm = dom.inboxSearch.value.toLowerCase().trim();
  const filter = state.activeFilter;

  const filtered = mockInvoices.filter(inv => {
    const matchesSearch = inv.supplierRaw.toLowerCase().includes(searchTerm) ||
                          inv.invoiceNo.toLowerCase().includes(searchTerm) ||
                          inv.id.toLowerCase().includes(searchTerm);
    if (!matchesSearch) return false;

    if (filter === 'all') return true;
    if (filter === 'needs-review') return inv.status === 'NEEDS_REVIEW' || inv.status === 'NEEDS_CORRECTION';
    if (filter === 'approved') return inv.status === 'APPROVED';
    if (filter === 'posted') return inv.status === 'POSTED';
    if (filter === 'failed') return inv.status === 'POST_FAILED';
    return true;
  });

  dom.invoicesTbody.innerHTML = filtered.map(inv => {
    let badgeClass = 'needs-review';
    let statusText = inv.status;
    let statusIcon = 'fa-clock';

    if (inv.status === 'APPROVED') {
      badgeClass = 'approved';
      statusIcon = 'fa-check';
    } else if (inv.status === 'POSTED') {
      badgeClass = 'posted';
      statusIcon = 'fa-circle-check';
    } else if (inv.status === 'POST_FAILED') {
      badgeClass = 'failed';
      statusIcon = 'fa-triangle-exclamation';
    } else if (inv.status === 'NEEDS_CORRECTION') {
      badgeClass = 'needs-review';
      statusIcon = 'fa-pen';
    }

    return `
      <tr>
        <td><strong class="mono" style="color: var(--color-azure-text);">${inv.id}</strong></td>
        <td>
          <div class="file-name-cell">
            <i class="fa-solid ${inv.sourceFilename.endsWith('.pdf') ? 'fa-file-pdf file-icon' : 'fa-file-image file-icon'}"></i>
            <div>
              <div>${inv.sourceFilename}</div>
              <div style="font-size: 0.7rem; color: var(--text-muted); font-family: var(--font-mono);">Confidence: ${inv.confidence}</div>
            </div>
          </div>
        </td>
        <td>
          <div style="font-weight: 700; color: var(--text-primary);">${inv.supplierRaw}</div>
          <div style="font-size: 0.74rem; color: ${inv.supplierMapped ? 'var(--color-azure-text)' : 'var(--color-amber-text)'};">
            ${inv.supplierMapped ? `<i class="fa-solid fa-link"></i> ${inv.supplierMapped}` : '<i class="fa-solid fa-triangle-exclamation"></i> Unmapped Supplier'}
          </div>
        </td>
        <td>
          <div class="mono" style="font-weight: 700;">${inv.invoiceNo}</div>
          <div style="font-size: 0.72rem; color: var(--text-muted); font-family: var(--font-mono);">${inv.invoiceDate}</div>
        </td>
        <td><span style="font-size: 0.75rem; color: var(--text-secondary);">${inv.type}</span></td>
        <td><strong class="mono" style="color: var(--text-primary);">₹ ${inv.grandTotal.toLocaleString('en-IN', { minimumFractionDigits: 2 })}</strong></td>
        <td>
          <span class="status-badge ${badgeClass}">
            <i class="fa-solid ${statusIcon}"></i> ${statusText}
          </span>
        </td>
        <td>
          <span class="mono" style="font-size: 0.75rem; color: ${inv.tallyRef.startsWith('PUR') ? 'var(--color-mint-text)' : 'var(--text-muted)'}; font-weight: 600;">
            ${inv.tallyRef}
          </span>
        </td>
        <td style="text-align: right;">
          <button class="btn btn-secondary btn-sm" onclick="openInvoiceReview('${inv.id}')">
            <i class="fa-solid fa-eye"></i> Review
          </button>
        </td>
      </tr>
    `;
  }).join('');
}

dom.inboxSearch.addEventListener('input', renderInboxTable);

dom.filterPills.forEach(pill => {
  pill.addEventListener('click', () => {
    dom.filterPills.forEach(p => p.classList.remove('active'));
    pill.classList.add('active');
    state.activeFilter = pill.dataset.filter;
    renderInboxTable();
  });
});

window.openInvoiceReview = function(invoiceId) {
  state.currentInvoiceId = invoiceId;
  dom.reviewSampleSelect.value = invoiceId;
  switchTab('review');
};

// ============================================================================
// 5. TAB 2: Review & Validation Logic
// ============================================================================

function loadInvoiceForReview(invoiceId) {
  const inv = mockInvoices.find(item => item.id === invoiceId) || mockInvoices[0];

  // Update Status Badge
  dom.reviewStatusBadge.className = `status-badge ${inv.status.toLowerCase().replace('_', '-')}`;
  dom.reviewStatusBadge.innerHTML = `<i class="fa-solid fa-tag"></i> ${inv.status}`;

  // Update Left Document Preview
  if (!defaultBillPaperHtml && dom.docViewport) {
    defaultBillPaperHtml = dom.docViewport.innerHTML;
  }

  if (inv.imageUrl && dom.docViewport) {
    let bboxesHtml = '';
    if (inv.ocrResult && inv.ocrResult.lines && state.showBBoxes) {
      bboxesHtml = inv.ocrResult.lines.map(l => {
        if (!l.bbox || l.bbox.length < 4) return '';
        const minX = Math.min(l.bbox[0][0], l.bbox[3][0]);
        const minY = Math.min(l.bbox[0][1], l.bbox[1][1]);
        const maxX = Math.max(l.bbox[1][0], l.bbox[2][0]);
        const maxY = Math.max(l.bbox[2][1], l.bbox[3][1]);
        const width = Math.max(20, maxX - minX);
        const height = Math.max(10, maxY - minY);
        return `<div class="ocr-bbox" style="position: absolute; left: ${minX}px; top: ${minY}px; width: ${width}px; height: ${height}px; border: 1.5px solid #0284c7; background: rgba(14, 165, 233, 0.15); border-radius: 2px;" title="${l.text} (${(l.confidence * 100).toFixed(0)}%)">
          <span class="ocr-tag" style="position: absolute; top: -18px; left: 0; background: #0284c7; color: white; font-size: 9px; padding: 1px 4px; border-radius: 2px; white-space: nowrap;">${l.text.substring(0, 20)} (${(l.confidence * 100).toFixed(0)}%)</span>
        </div>`;
      }).join('');
    }

    dom.docViewport.innerHTML = `
      <div style="position: relative; display: inline-block; width: 100%; text-align: center;">
        <img src="${inv.imageUrl}" alt="${inv.sourceFilename}" style="max-width: 100%; height: auto; border-radius: 4px; box-shadow: 0 4px 12px rgba(0,0,0,0.15);" id="live-bill-image">
        <div id="live-bboxes-container" style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none;">
          ${bboxesHtml}
        </div>
      </div>
    `;
  } else if (dom.docViewport && defaultBillPaperHtml) {
    dom.docViewport.innerHTML = defaultBillPaperHtml;
    const sellerEl = document.getElementById('doc-seller-name');
    if (sellerEl) sellerEl.textContent = inv.supplierRaw;
    const invNoEl = document.getElementById('doc-inv-no');
    if (invNoEl) invNoEl.textContent = inv.invoiceNo;
    const invDateEl = document.getElementById('doc-inv-date');
    if (invDateEl) invDateEl.textContent = inv.invoiceDate;
    const subtotalEl = document.getElementById('doc-subtotal-val');
    if (subtotalEl) subtotalEl.textContent = `₹ ${inv.subtotal.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;
    const cgstEl = document.getElementById('doc-cgst-val');
    if (cgstEl) cgstEl.textContent = `₹ ${inv.cgst.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;
    const sgstEl = document.getElementById('doc-sgst-val');
    if (sgstEl) sgstEl.textContent = `₹ ${inv.sgst.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;
    const totalEl = document.getElementById('doc-grand-total-val');
    if (totalEl) totalEl.textContent = `₹ ${inv.grandTotal.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;

    const docItemsTbody = document.getElementById('doc-items-tbody');
    if (docItemsTbody) {
      docItemsTbody.innerHTML = inv.lines.map((l, i) => `
        <tr>
          <td>${i + 1}</td>
          <td>${l.descRaw}</td>
          <td>${l.hsn || '84719000'}</td>
          <td style="text-align: right;">${l.qty} ${l.unit}</td>
          <td style="text-align: right;">${l.rate.toLocaleString('en-IN', { minimumFractionDigits: 2 })}</td>
          <td style="text-align: right;">${l.taxable.toLocaleString('en-IN', { minimumFractionDigits: 2 })}</td>
        </tr>
      `).join('');
    }
  }

  // Update Right Pane Form
  document.getElementById('form-raw-supplier').value = inv.supplierRaw;
  document.getElementById('form-mapped-supplier').value = inv.supplierMapped || '__NEW__';
  document.getElementById('form-invoice-no').value = inv.invoiceNo;
  document.getElementById('form-invoice-date').value = inv.invoiceDate;
  document.getElementById('form-gstin').value = inv.gstin;
  document.getElementById('form-tally-date').value = inv.tallyDate;
  document.getElementById('form-voucher-mode').value = inv.type;

  // Render Line Items in Editable Grid
  renderLineItemsGrid(inv.lines);

  // Run Real-Time Validation
  runPrePostingValidation(inv);
}

function renderLineItemsGrid(lines) {
  document.getElementById('line-count-badge').textContent = `${lines.length} items`;

  dom.lineItemsTbody.innerHTML = lines.map((l, index) => `
    <tr data-line-index="${index}">
      <td class="mono" style="font-weight: 700; color: var(--text-muted);">${index + 1}</td>
      <td>
        <input type="text" class="form-control" value="${l.descRaw}" onchange="updateLineField(${index}, 'descRaw', this.value)">
      </td>
      <td>
        <select class="form-control" onchange="updateLineField(${index}, 'stockItem', this.value)">
          <option value="${l.stockItem}">${l.stockItem || '— Select Tally Item / Ledger —'}</option>
          <option value="Sensor Module XYZ-400">Sensor Module XYZ-400</option>
          <option value="ARM Controller Board v3.2">ARM Controller Board v3.2</option>
          <option value="Shielded Interface Cable 1.5m">Shielded Interface Cable 1.5m</option>
          <option value="Precision Torque Screwdriver">Precision Torque Screwdriver</option>
          <option value="Printing & Stationery Exp">Printing & Stationery Exp</option>
        </select>
      </td>
      <td>
        <input type="number" class="form-control mono" style="text-align: right;" value="${l.qty}" onchange="updateLineField(${index}, 'qty', parseFloat(this.value) || 0)">
      </td>
      <td>
        <input type="text" class="form-control mono" style="text-align: center;" value="${l.unit}" onchange="updateLineField(${index}, 'unit', this.value)">
      </td>
      <td>
        <input type="number" class="form-control mono" style="text-align: right;" value="${l.rate}" step="0.01" onchange="updateLineField(${index}, 'rate', parseFloat(this.value) || 0)">
      </td>
      <td>
        <input type="number" class="form-control mono" style="text-align: right; background: var(--bg-surface); color: var(--text-secondary);" value="${l.taxable}" readonly>
      </td>
      <td>
        <select class="form-control mono" onchange="updateLineField(${index}, 'taxRate', parseFloat(this.value) || 0)">
          <option value="18" ${l.taxRate === 18 ? 'selected' : ''}>18%</option>
          <option value="12" ${l.taxRate === 12 ? 'selected' : ''}>12%</option>
          <option value="5" ${l.taxRate === 5 ? 'selected' : ''}>5%</option>
          <option value="0" ${l.taxRate === 0 ? 'selected' : ''}>0%</option>
        </select>
      </td>
      <td>
        <input type="number" class="form-control mono" style="text-align: right; background: var(--bg-surface); color: var(--text-secondary);" value="${l.taxAmount.toFixed(2)}" readonly>
      </td>
      <td>
        <strong class="mono" style="color: #059669;">₹ ${l.total.toLocaleString('en-IN', { minimumFractionDigits: 2 })}</strong>
      </td>
      <td style="text-align: center;">
        <button class="btn btn-secondary btn-icon" style="width: 24px; height: 24px; color: #ef4444;" onclick="deleteLineItem(${index})" title="Remove item">
          <i class="fa-solid fa-trash-can" style="font-size: 0.7rem;"></i>
        </button>
      </td>
    </tr>
  `).join('');

  recalculateTotals();
}

window.updateLineField = function(index, field, value) {
  const inv = mockInvoices.find(item => item.id === state.currentInvoiceId);
  if (!inv || !inv.lines[index]) return;

  inv.lines[index][field] = value;

  // Recalculate line
  const l = inv.lines[index];
  l.taxable = l.qty * l.rate;
  l.taxAmount = (l.taxable * (l.taxRate / 100));
  l.total = l.taxable + l.taxAmount;

  renderLineItemsGrid(inv.lines);
  runPrePostingValidation(inv);
};

window.deleteLineItem = function(index) {
  const inv = mockInvoices.find(item => item.id === state.currentInvoiceId);
  if (!inv || inv.lines.length <= 1) {
    showToast('Cannot delete the only line item of an invoice.', 'warning');
    return;
  }
  inv.lines.splice(index, 1);
  renderLineItemsGrid(inv.lines);
  runPrePostingValidation(inv);
  showToast('Line item removed.', 'success');
};

document.getElementById('btn-add-line-row').addEventListener('click', () => {
  const inv = mockInvoices.find(item => item.id === state.currentInvoiceId);
  if (!inv) return;

  inv.lines.push({
    lineNo: inv.lines.length + 1,
    descRaw: 'New Unspecified Item',
    stockItem: '',
    qty: 1,
    unit: 'NOS',
    rate: 1000.00,
    taxable: 1000.00,
    taxRate: 18,
    taxAmount: 180.00,
    total: 1180.00,
    confidence: 100.0
  });

  renderLineItemsGrid(inv.lines);
  runPrePostingValidation(inv);
  showToast('New line item added to invoice grid.', 'success');
});

function recalculateTotals() {
  const inv = mockInvoices.find(item => item.id === state.currentInvoiceId);
  if (!inv) return;

  let sumTaxable = 0;
  let sumGst = 0;

  inv.lines.forEach(l => {
    sumTaxable += l.taxable;
    sumGst += l.taxAmount;
  });

  const grandTotal = sumTaxable + sumGst;
  inv.subtotal = sumTaxable;
  inv.cgst = sumGst / 2;
  inv.sgst = sumGst / 2;
  inv.grandTotal = grandTotal;

  dom.sumTaxableDisplay.textContent = `₹ ${sumTaxable.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;
  dom.sumGstDisplay.textContent = `₹ ${sumGst.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;
  dom.sumGrandDisplay.textContent = `₹ ${grandTotal.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;
}

function runPrePostingValidation(inv) {
  const checkRequired = document.getElementById('check-required-fields');
  const checkMath = document.getElementById('check-math-reconciliation');
  const checkMapping = document.getElementById('check-ledger-mapping');
  const checkDup = document.getElementById('check-duplicate-guard');
  const overallBadge = document.getElementById('validation-overall-badge');
  const postBtn = dom.btnApprovePost;

  let allPassed = true;

  // 1. Required fields
  const hasRequired = inv.invoiceNo && inv.invoiceDate && inv.supplierRaw;
  updateCheckItem(checkRequired, hasRequired, 'Required Fields', 'Supplier, invoice # and date present');
  if (!hasRequired) allPassed = false;

  // 2. Math reconciliation
  const linesSum = inv.lines.reduce((acc, l) => acc + l.total, 0);
  const mathDiff = Math.abs(linesSum - inv.grandTotal);
  const mathPass = mathDiff <= 0.50; // Rounding tolerance
  updateCheckItem(checkMath, mathPass, 'Math Reconciliation', `Line sum diff: ₹ ${mathDiff.toFixed(2)} (Tolerance: ±₹0.50)`);
  if (!mathPass) allPassed = false;

  // 3. Mapping completeness
  const unmappedCount = inv.lines.filter(l => !l.stockItem).length;
  const supplierMapped = !!inv.supplierMapped;
  const mappingPass = unmappedCount === 0 && supplierMapped;
  updateCheckItem(checkMapping, mappingPass, 'Master Ledger Mapping', mappingPass ? 'All items & supplier mapped to Tally' : `${unmappedCount} items or supplier unmapped`);
  if (!mappingPass) allPassed = false;

  // 4. Duplicate Guard
  const isDup = inv.status === 'POSTED';
  updateCheckItem(checkDup, !isDup, 'Duplicate Guard', isDup ? 'Invoice already posted in Tally!' : 'No duplicate voucher detected');
  if (isDup) allPassed = false;

  // Overall status
  if (allPassed) {
    overallBadge.className = 'status-badge approved';
    overallBadge.innerHTML = '<i class="fa-solid fa-circle-check"></i> ALL CHECKS PASSED';
    postBtn.disabled = false;
    postBtn.style.opacity = '1';
  } else {
    overallBadge.className = 'status-badge failed';
    overallBadge.innerHTML = '<i class="fa-solid fa-triangle-exclamation"></i> ACTION REQUIRED';
    postBtn.disabled = true;
    postBtn.style.opacity = '0.6';
  }
}

function updateCheckItem(el, passed, title, msg) {
  const icon = el.querySelector('.check-icon');
  const titleEl = el.querySelector('strong');
  const msgEl = el.querySelector('div div');

  titleEl.textContent = title;
  msgEl.textContent = msg;

  if (passed) {
    icon.className = 'fa-solid fa-circle-check check-icon pass';
  } else {
    icon.className = 'fa-solid fa-circle-exclamation check-icon fail';
  }
}

dom.reviewSampleSelect.addEventListener('change', (e) => {
  state.currentInvoiceId = e.target.value;
  loadInvoiceForReview(state.currentInvoiceId);
});

// Viewport Zoom & Rotate Controls
dom.zoomInBtn.addEventListener('click', () => {
  if (state.zoomLevel < 180) state.zoomLevel += 15;
  applyViewportTransform();
});

dom.zoomOutBtn.addEventListener('click', () => {
  if (state.zoomLevel > 60) state.zoomLevel -= 15;
  applyViewportTransform();
});

dom.rotateBtn.addEventListener('click', () => {
  state.rotationAngle = (state.rotationAngle + 90) % 360;
  applyViewportTransform();
});

dom.toggleBBoxesBtn.addEventListener('click', () => {
  state.showBBoxes = !state.showBBoxes;
  document.querySelectorAll('.ocr-bbox').forEach(box => {
    box.style.display = state.showBBoxes ? 'block' : 'none';
  });
  dom.toggleBBoxesBtn.innerHTML = state.showBBoxes ? 
    '<i class="fa-solid fa-vector-square"></i> Bounding Boxes: ON' : 
    '<i class="fa-regular fa-vector-square"></i> Bounding Boxes: OFF';
});

function applyViewportTransform() {
  dom.zoomLevelText.textContent = `${state.zoomLevel}%`;
  dom.docViewport.style.transform = `scale(${state.zoomLevel / 100}) rotate(${state.rotationAngle}deg)`;
}

// Action Buttons
dom.btnSaveDraft.addEventListener('click', () => {
  showToast('Draft invoice edits saved to database successfully.', 'success');
});

dom.btnRejectInvoice.addEventListener('click', () => {
  const inv = mockInvoices.find(item => item.id === state.currentInvoiceId);
  if (inv) {
    inv.status = 'NEEDS_CORRECTION';
    dom.reviewStatusBadge.className = 'status-badge needs-review';
    dom.reviewStatusBadge.innerHTML = '<i class="fa-solid fa-pen"></i> NEEDS_CORRECTION';
    showToast('Invoice sent back for operator correction.', 'warning');
  }
});

// ============================================================================
// 6. Tally XML Payload Generator & Inspector Modal
// ============================================================================

function generateTallyPurchaseXml(inv) {
  const dateStr = inv.tallyDate || '20261018';
  return `<ENVELOPE>
  <HEADER>
    <TALLYREQUEST>Import Data</TALLYREQUEST>
  </HEADER>
  <BODY>
    <IMPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Vouchers</REPORTNAME>
        <STATICVARIABLES>
          <SVCURRENTCOMPANY>ASHAN TEST LABS PVT LTD</SVCURRENTCOMPANY>
        </STATICVARIABLES>
      </REQUESTDESC>
      <REQUESTDATA>
        <TALLYMESSAGE xmlns:UDF="TallyUDF">
          <VOUCHER VCHTYPE="Purchase" ACTION="Create" OBJVIEW="Invoice Voucher View">
            <DATE>${dateStr}</DATE>
            <VOUCHERTYPENAME>Purchase</VOUCHERTYPENAME>
            <REFERENCE>${inv.invoiceNo}</REFERENCE>
            <REFERENCEDATE>${dateStr}</REFERENCEDATE>
            <PARTYLEDGERNAME>${inv.supplierMapped || inv.supplierRaw}</PARTYLEDGERNAME>
            <PERSISTEDVIEW>Invoice Voucher View</PERSISTEDVIEW>
            <NARRATION>Purchase Invoice ${inv.invoiceNo} auto-generated via Bill-to-Tally Automation</NARRATION>
            
            <!-- Supplier Ledger Credit Entry -->
            <ALLLEDGERENTRIES.LIST>
              <LEDGERNAME>${inv.supplierMapped || inv.supplierRaw}</LEDGERNAME>
              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>
              <AMOUNT>${inv.grandTotal.toFixed(2)}</AMOUNT>
            </ALLLEDGERENTRIES.LIST>

            <!-- Line Items Inventory Allocations -->
${inv.lines.map(line => `            <ALLINVENTORYENTRIES.LIST>
              <STOCKITEMNAME>${line.stockItem || 'Default Stock Item'}</STOCKITEMNAME>
              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>
              <RATE>${line.rate.toFixed(2)} / ${line.unit}</RATE>
              <ACTUALQTY>${line.qty} ${line.unit}</ACTUALQTY>
              <BILLEDQTY>${line.qty} ${line.unit}</BILLEDQTY>
              <AMOUNT>-${line.taxable.toFixed(2)}</AMOUNT>
              <ACCOUNTINGALLOCATIONS.LIST>
                <LEDGERNAME>Purchase - GST 18%</LEDGERNAME>
                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>
                <AMOUNT>-${line.taxable.toFixed(2)}</AMOUNT>
              </ACCOUNTINGALLOCATIONS.LIST>
            </ALLINVENTORYENTRIES.LIST>`).join('\n')}

            <!-- Tax Ledgers -->
            <ALLLEDGERENTRIES.LIST>
              <LEDGERNAME>Input CGST @ 9%</LEDGERNAME>
              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>
              <AMOUNT>-${inv.cgst.toFixed(2)}</AMOUNT>
            </ALLLEDGERENTRIES.LIST>
            <ALLLEDGERENTRIES.LIST>
              <LEDGERNAME>Input SGST @ 9%</LEDGERNAME>
              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>
              <AMOUNT>-${inv.sgst.toFixed(2)}</AMOUNT>
            </ALLLEDGERENTRIES.LIST>
          </VOUCHER>
        </TALLYMESSAGE>
      </REQUESTDATA>
    </IMPORTDATA>
  </BODY>
</ENVELOPE>`;
}

dom.btnPreviewXml.addEventListener('click', () => {
  const inv = mockInvoices.find(item => item.id === state.currentInvoiceId);
  if (!inv) return;

  dom.xmlCodeView.textContent = generateTallyPurchaseXml(inv);
  dom.modalXml.classList.add('open');
});

document.getElementById('close-modal-xml-btn').addEventListener('click', () => dom.modalXml.classList.remove('open'));
document.getElementById('btn-done-xml').addEventListener('click', () => dom.modalXml.classList.remove('open'));
document.getElementById('btn-copy-xml').addEventListener('click', () => {
  navigator.clipboard.writeText(dom.xmlCodeView.textContent);
  showToast('Tally XML copied to clipboard!', 'success');
});

// Post to Tally Flow & Modal
dom.btnApprovePost.addEventListener('click', () => {
  const inv = mockInvoices.find(item => item.id === state.currentInvoiceId);
  if (!inv) return;

  document.getElementById('modal-confirm-supplier').textContent = inv.supplierMapped || inv.supplierRaw;
  document.getElementById('modal-confirm-inv-no').textContent = inv.invoiceNo;
  document.getElementById('modal-confirm-date').textContent = inv.tallyDate;
  document.getElementById('modal-confirm-total').textContent = `₹ ${inv.grandTotal.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;
  document.getElementById('modal-confirm-key').textContent = `ATL_TEST:${inv.invoiceNo}:${inv.tallyDate}`;

  dom.modalPostConfirm.classList.add('open');
});

document.getElementById('close-modal-post-btn').addEventListener('click', () => dom.modalPostConfirm.classList.remove('open'));
document.getElementById('btn-cancel-post').addEventListener('click', () => dom.modalPostConfirm.classList.remove('open'));

document.getElementById('btn-execute-post').addEventListener('click', () => {
  dom.modalPostConfirm.classList.remove('open');
  const inv = mockInvoices.find(item => item.id === state.currentInvoiceId);
  if (!inv) return;

  showToast('Connecting to TallyPrime at 127.0.0.1:9000...', 'warning');

  setTimeout(() => {
    const voucherRef = `PUR/2026/01${Math.floor(10 + Math.random() * 89)}`;
    inv.status = 'POSTED';
    inv.tallyRef = voucherRef;

    mockPostingAttempts.unshift({
      id: `ATT-2026-${Math.floor(1000 + Math.random() * 9000)}`,
      invoiceId: inv.id,
      idempotencyKey: `ATL_TEST:${inv.invoiceNo}:${inv.tallyDate}`,
      voucherNo: voucherRef,
      startedAt: new Date().toISOString().replace('T', ' ').substring(0, 19),
      status: 'POSTED',
      responseMessage: `Tally voucher created successfully: ${voucherRef}`
    });

    mockAuditTimeline.unshift({
      time: new Date().toISOString().replace('T', ' ').substring(0, 19),
      actor: 'accounts_user_01',
      action: 'VOUCHER_POSTED_TO_TALLY',
      summary: `Posted purchase voucher ${voucherRef} to ASHAN TEST LABS PVT LTD`,
      diff: {
        status: { before: 'APPROVED', after: 'POSTED' },
        tally_voucher_no: voucherRef
      }
    });

    loadInvoiceForReview(inv.id);
    renderInboxTable();
    showToast(`Voucher posted successfully! Ref: ${voucherRef}`, 'success');
  }, 1200);
});

// ============================================================================
// 7. TAB 3: Master Mappings Logic
// ============================================================================

function renderMappingsTable() {
  const type = state.activeMappingType;
  const list = mockMappings[type] || [];
  const search = (document.getElementById('mappings-search-input').value || '').toLowerCase();

  const titleMap = {
    suppliers: 'Supplier Name Mappings (OCR string &rarr; Tally Sundry Creditor)',
    items: 'Stock Item Mappings (OCR line description &rarr; Tally Stock Item)',
    ledgers: 'Purchase Account Mappings (Expense category &rarr; Tally Purchase Ledger)',
    units: 'Unit of Measure Mappings (Raw unit &rarr; Tally UOM)'
  };
  document.getElementById('mappings-table-title').querySelector('span').innerHTML = titleMap[type];

  const filtered = list.filter(m => m.raw.toLowerCase().includes(search) || m.tally.toLowerCase().includes(search));

  dom.mappingsTbody.innerHTML = filtered.map(m => `
    <tr>
      <td><strong class="mono" style="color: var(--color-azure-text);">${m.id}</strong></td>
      <td><strong style="color: var(--text-primary);">${m.raw}</strong></td>
      <td>
        <span style="color: ${m.status === 'UNMAPPED' ? '#dc2626' : 'var(--color-azure-text)'}; font-weight: 700;">
          <i class="fa-solid fa-link"></i> ${m.tally}
        </span>
      </td>
      <td><span style="font-size: 0.75rem; color: var(--text-secondary); font-weight: 600;">${m.category}</span></td>
      <td><span class="mono" style="font-size: 0.7rem; color: var(--text-muted);">${m.guid || '—'}</span></td>
      <td>
        <span class="status-badge ${m.status === 'VERIFIED' ? 'posted' : (m.status === 'SUGGESTED' ? 'needs-review' : 'failed')}">
          ${m.status}
        </span>
      </td>
      <td><span class="mono" style="font-size: 0.72rem; color: var(--text-muted);">${m.date}</span></td>
      <td style="text-align: right;">
        <button class="btn btn-secondary btn-sm" onclick="showToast('Mapping edit dialog', 'success')">
          <i class="fa-solid fa-pen-to-square"></i> Edit
        </button>
      </td>
    </tr>
  `).join('');
}

dom.mappingTabs.forEach(btn => {
  btn.addEventListener('click', () => {
    dom.mappingTabs.forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    state.activeMappingType = btn.dataset.type;
    renderMappingsTable();
  });
});

document.getElementById('mappings-search-input').addEventListener('input', renderMappingsTable);

document.getElementById('btn-sync-tally-masters').addEventListener('click', () => {
  showToast('Connecting to Tally at 127.0.0.1:9000 to fetch master ledgers & stock items...', 'warning');
  setTimeout(() => {
    showToast('Masters synchronized! 42 ledgers, 88 stock items updated.', 'success');
  }, 1200);
});

// ============================================================================
// 8. TAB 4: Tally Connector & Posting Logs
// ============================================================================

function renderPostingAttempts() {
  dom.postingAttemptsTbody.innerHTML = mockPostingAttempts.map(att => `
    <tr>
      <td><strong class="mono" style="color: var(--color-azure-text);">${att.id}</strong></td>
      <td><span class="mono" style="font-weight: 600;">${att.invoiceId}</span></td>
      <td><span class="mono" style="font-size: 0.72rem; color: var(--text-muted);">${att.idempotencyKey}</span></td>
      <td><strong class="mono" style="color: #059669;">${att.voucherNo}</strong></td>
      <td><span class="mono" style="font-size: 0.72rem; color: var(--text-muted);">${att.startedAt}</span></td>
      <td>
        <span class="status-badge ${att.status === 'POSTED' ? 'posted' : (att.status === 'VALIDATED' ? 'approved' : 'failed')}">
          ${att.status}
        </span>
      </td>
      <td><span style="font-size: 0.75rem; color: var(--text-secondary); font-weight: 500;">${att.responseMessage}</span></td>
      <td style="text-align: right;">
        <button class="btn btn-secondary btn-sm" onclick="showToast('XML payload inspect', 'success')">
          <i class="fa-solid fa-code"></i> XML
        </button>
      </td>
    </tr>
  `).join('');
}

document.getElementById('btn-test-connection').addEventListener('click', () => {
  showToast('Sending HTTP GET ping to http://127.0.0.1:9000...', 'warning');
  setTimeout(() => {
    showToast('TallyPrime HTTP XML gateway is reachable and responding (200 OK)', 'success');
  }, 800);
});

// ============================================================================
// 9. TAB 5: Audit Trail Logic
// ============================================================================

function renderAuditTimeline() {
  dom.auditTimeline.innerHTML = mockAuditTimeline.map(item => `
    <div class="timeline-item">
      <div class="timeline-node">
        <i class="fa-solid fa-bolt"></i>
      </div>
      <div class="timeline-content">
        <div class="timeline-header">
          <div class="timeline-title">${item.action} &bull; <span style="color: #818cf8; font-weight: normal;">${item.actor}</span></div>
          <div class="timeline-time">${item.time}</div>
        </div>
        <p style="font-size: 0.8rem; color: var(--text-secondary); margin-bottom: 8px;">${item.summary}</p>
        <pre class="xml-code-view" style="max-height: 100px; padding: 8px; font-size: 0.7rem; color: #a5f3fc;">${JSON.stringify(item.diff, null, 2)}</pre>
      </div>
    </div>
  `).join('');
}

// ============================================================================
// 10. Settings & Security
// ============================================================================

dom.safetyToggle.addEventListener('change', (e) => {
  state.postingEnabled = e.target.checked;
  const slider = document.getElementById('toggle-slider');
  const indicator = dom.safetyIndicator;

  if (state.postingEnabled) {
    slider.style.backgroundColor = '#10b981';
    indicator.style.color = 'var(--color-mint-text)';
    indicator.style.borderColor = 'rgba(39, 245, 190, 0.6)';
    indicator.style.background = 'rgba(39, 245, 190, 0.18)';
    indicator.innerHTML = '<i class="fa-solid fa-shield-halved"></i> <span>POSTING_ENABLED: true (Active Gateway)</span>';
    showToast('WARNING: Live posting enabled. Vouchers can now be committed to Tally.', 'warning');
  } else {
    slider.style.backgroundColor = '#cbd5e1';
    indicator.style.color = 'var(--color-amber-text)';
    indicator.style.borderColor = 'rgba(245, 156, 39, 0.35)';
    indicator.style.background = 'rgba(245, 156, 39, 0.12)';
    indicator.innerHTML = '<i class="fa-solid fa-shield-halved"></i> <span>POSTING_ENABLED: false (Test Mode)</span>';
    showToast('Safe Mode active: live posting disabled.', 'success');
  }
});

document.getElementById('btn-save-settings').addEventListener('click', () => {
  showToast('Configuration settings updated and persisted.', 'success');
});

// Real API Upload Handler
async function handleFileUpload(file) {
  if (!file) return;

  const validTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/bmp'];
  const ext = file.name.substring(file.name.lastIndexOf('.')).toLowerCase();
  if (!validTypes.includes(file.type) && !['.jpg', '.jpeg', '.png', '.webp', '.bmp'].includes(ext)) {
    showToast(`Please upload a photo image (JPG, PNG, WEBP). Document PDFs will be added in the next step.`, 'error');
    return;
  }

  showToast(`Uploading ${file.name} to PaddleOCR engine...`, 'warning');

  const formData = new FormData();
  formData.append('file', file);

  try {
    const res = await fetch(`${API_BASE_URL}/api/invoices/ocr`, {
      method: 'POST',
      body: formData
    });

    if (!res.ok) {
      const errData = await res.json().catch(() => ({ detail: res.statusText }));
      throw new Error(errData.detail || `Upload failed with status ${res.status}`);
    }

    const data = await res.json();
    const confPercent = (data.ocr_result.average_confidence * 100).toFixed(1);
    showToast(`PaddleOCR Scanned ${data.line_count} text lines! (${confPercent}% confidence)`, 'success');

    const extractedLines = data.ocr_result.lines || [];
    const rawText = data.ocr_result.raw_text || '';

    // Create an invoice entry from real OCR scan
    const newInvoice = {
      id: data.id,
      sourceFilename: data.filename,
      fileHash: data.file_hash_sha256,
      imageUrl: `${API_BASE_URL}${data.image_url}`,
      ocrResult: data.ocr_result,
      rawOcrText: rawText,
      supplierRaw: extractedLines.length > 0 ? extractedLines[0].text : 'Scanned Bill',
      supplierMapped: '',
      invoiceNo: data.id.replace('INV-', 'BILL-'),
      invoiceDate: new Date().toISOString().split('T')[0],
      tallyDate: new Date().toISOString().split('T')[0].replace(/-/g, ''),
      gstin: '—',
      type: 'Accounting Purchase',
      subtotal: 0.00,
      cgst: 0.00,
      sgst: 0.00,
      grandTotal: 0.00,
      status: 'NEEDS_REVIEW',
      tallyRef: '—',
      confidence: `${confPercent}%`,
      lines: extractedLines.slice(0, 15).map((l, idx) => ({
        lineNo: idx + 1,
        descRaw: l.text,
        stockItem: '',
        qty: 1,
        unit: 'NOS',
        rate: 0.00,
        taxable: 0.00,
        taxRate: 18,
        taxAmount: 0.00,
        total: 0.00,
        confidence: (l.confidence * 100).toFixed(1),
        bbox: l.bbox
      }))
    };

    // Prepend to active invoices
    mockInvoices.unshift(newInvoice);

    // Update Sample Selector dropdown
    if (dom.reviewSampleSelect) {
      const opt = document.createElement('option');
      opt.value = newInvoice.id;
      opt.textContent = `${newInvoice.id}: ${newInvoice.sourceFilename} (${data.line_count} lines)`;
      dom.reviewSampleSelect.insertBefore(opt, dom.reviewSampleSelect.firstChild);
      dom.reviewSampleSelect.value = newInvoice.id;
    }

    // Refresh inbox table
    renderInboxTable();

    // Switch to review tab and load the scanned invoice
    openInvoiceReview(newInvoice.id);

  } catch (err) {
    console.error('OCR Upload Error:', err);
    showToast(`Error connecting to OCR backend: ${err.message}. Is backend running on http://127.0.0.1:8000?`, 'error');
  }
}

// Quick upload trigger
document.getElementById('btn-quick-upload').addEventListener('click', () => {
  document.getElementById('hidden-file-input').click();
});

document.getElementById('hidden-file-input').addEventListener('change', (e) => {
  if (e.target.files.length > 0) {
    handleFileUpload(e.target.files[0]);
  }
});

// Drag & drop zone listeners
const dropzone = document.getElementById('upload-dropzone-box');
if (dropzone) {
  dropzone.addEventListener('dragover', (e) => {
    e.preventDefault();
    dropzone.style.borderColor = 'var(--palette-azure)';
    dropzone.style.background = 'rgba(14, 165, 233, 0.08)';
  });
  dropzone.addEventListener('dragleave', (e) => {
    e.preventDefault();
    dropzone.style.borderColor = '';
    dropzone.style.background = '';
  });
  dropzone.addEventListener('drop', (e) => {
    e.preventDefault();
    dropzone.style.borderColor = '';
    dropzone.style.background = '';
    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      handleFileUpload(e.dataTransfer.files[0]);
    }
  });
}

// Raw OCR Text Inspector Modal Wire
if (dom.btnViewRawOcr && dom.modalOcr) {
  dom.btnViewRawOcr.addEventListener('click', () => {
    const inv = mockInvoices.find(item => item.id === state.currentInvoiceId);
    if (!inv) return;

    const raw = inv.rawOcrText || (inv.lines ? inv.lines.map(l => l.descRaw).join('\n') : 'No OCR text available');
    if (dom.ocrModalContent) dom.ocrModalContent.textContent = raw;
    if (dom.ocrModalMeta) {
      dom.ocrModalMeta.textContent = `Invoice: ${inv.id} | Confidence: ${inv.confidence} | Source: ${inv.sourceFilename}`;
    }
    dom.modalOcr.classList.add('active');
  });
}

[dom.closeOcrBtn, dom.doneOcrBtn].forEach(btn => {
  if (btn) btn.addEventListener('click', () => {
    if (dom.modalOcr) dom.modalOcr.classList.remove('active');
  });
});

if (dom.copyOcrBtn && dom.ocrModalContent) {
  dom.copyOcrBtn.addEventListener('click', () => {
    navigator.clipboard.writeText(dom.ocrModalContent.textContent);
    showToast('Raw OCR text copied to clipboard!', 'success');
  });
}

// ============================================================================
// 11. Toast Notifications Utility
// ============================================================================

function showToast(message, type = 'success') {
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  
  let icon = 'fa-circle-check';
  if (type === 'warning') icon = 'fa-triangle-exclamation';
  if (type === 'error') icon = 'fa-circle-xmark';

  toast.innerHTML = `
    <i class="fa-solid ${icon}" style="font-size: 1.1rem; color: ${type === 'success' ? '#10b981' : (type === 'warning' ? '#f59e0b' : '#ef4444')};"></i>
    <span>${message}</span>
  `;

  dom.toastContainer.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(100%)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 4000);
}

// ============================================================================
// Initialization on Page Load
// ============================================================================

window.addEventListener('DOMContentLoaded', () => {
  switchTab('inbox');
  loadInvoiceForReview(state.currentInvoiceId);
});
