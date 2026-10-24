import * as XLSX from 'xlsx';

/**
 * Transforms an invoice object into tabular rows formatted for TallyPrime Excel Import.
 */
export function formatInvoiceForTallyExcel(inv) {
  const lines = inv.lines && inv.lines.length > 0 ? inv.lines : [
    {
      lineNo: 1,
      descRaw: 'General Accounting Purchase',
      stockItem: inv.supplierMapped || inv.supplierRaw || 'Purchase Account',
      hsn: '',
      qty: 1,
      unit: 'NOS',
      rate: Number(inv.subtotal || inv.grandTotal || 0),
      taxable: Number(inv.subtotal || inv.grandTotal || 0),
      taxRate: Number(inv.taxRate || 0),
      taxAmount: Number((inv.cgst || 0) + (inv.sgst || 0) + (inv.igst || 0)),
      total: Number(inv.grandTotal || 0)
    }
  ];

  return lines.map((line, idx) => ({
    'Voucher Type': inv.type || 'Purchase',
    'Voucher Date': inv.invoiceDate || new Date().toISOString().split('T')[0],
    'Invoice / Bill No': inv.invoiceNo || inv.id || 'DRAFT-01',
    'Supplier / Party Ledger': inv.supplierMapped || inv.supplierRaw || 'Sundry Creditors',
    'Supplier GSTIN': inv.gstin || '',
    'Item No': line.lineNo || (idx + 1),
    'Extracted Item Description': line.descRaw || 'Line Item',
    'Tally Stock Item': line.stockItem || line.descRaw || 'Stock Item',
    'HSN / SAC Code': line.hsn || '',
    'Quantity': Number(line.qty || 1),
    'Unit of Measure': line.unit || 'NOS',
    'Rate (₹)': Number(line.rate || 0),
    'Taxable Amount (₹)': Number(line.taxable || 0),
    'GST Rate (%)': Number(line.taxRate || 0),
    'CGST (₹)': Number(line.taxAmount ? line.taxAmount / 2 : (inv.cgst || 0)),
    'SGST (₹)': Number(line.taxAmount ? line.taxAmount / 2 : (inv.sgst || 0)),
    'IGST (₹)': Number(inv.igst || 0),
    'Line Total (₹)': Number(line.total || 0),
    'Invoice Grand Total (₹)': Number(inv.grandTotal || 0),
    'Document Source': inv.sourceFilename || 'Scanned Document',
    'Status': 'DRAFT'
  }));
}

/**
 * Generates an XLSX workbook for a single invoice.
 */
export function generateInvoiceWorkbook(inv) {
  const wb = XLSX.utils.book_new();
  const rows = formatInvoiceForTallyExcel(inv);
  const ws = XLSX.utils.json_to_sheet(rows);

  // Set column widths for clean readability in Microsoft Excel
  ws['!cols'] = [
    { wch: 14 }, // Voucher Type
    { wch: 13 }, // Voucher Date
    { wch: 18 }, // Invoice No
    { wch: 28 }, // Supplier / Party Ledger
    { wch: 18 }, // Supplier GSTIN
    { wch: 8 },  // Item No
    { wch: 30 }, // Description
    { wch: 24 }, // Stock Item
    { wch: 14 }, // HSN/SAC
    { wch: 10 }, // Qty
    { wch: 10 }, // UOM
    { wch: 12 }, // Rate
    { wch: 16 }, // Taxable Amount
    { wch: 12 }, // GST Rate
    { wch: 12 }, // CGST
    { wch: 12 }, // SGST
    { wch: 12 }, // IGST
    { wch: 14 }, // Line Total
    { wch: 20 }, // Grand Total
    { wch: 25 }, // Document Source
    { wch: 10 }  // Status
  ];

  const sheetName = (inv.invoiceNo && inv.invoiceNo !== '—' ? `Voucher_${inv.invoiceNo}` : `Draft_${inv.id}`)
    .replace(/[\\/?*[\]:]/g, '_')
    .substring(0, 31);

  XLSX.utils.book_append_sheet(wb, ws, sheetName);
  return wb;
}

/**
 * Triggers browser download of a single draft invoice Excel file.
 */
export function downloadTallyInvoiceExcel(inv, customFilename) {
  const wb = generateInvoiceWorkbook(inv);
  const safeName = customFilename || `Tally_Draft_${inv.invoiceNo || inv.id}_${inv.supplierRaw || 'Supplier'}`.replace(/[^a-zA-Z0-9_-]/g, '_');
  XLSX.writeFile(wb, `${safeName}.xlsx`);
}

/**
 * Generates and downloads a consolidated workbook containing all saved draft invoices.
 */
export function downloadAllDraftsExcel(drafts, filename = 'Tally_Draft_Invoices_Master') {
  if (!drafts || drafts.length === 0) return;

  const wb = XLSX.utils.book_new();
  
  // Sheet 1: Master Consolidated Table
  const allRows = drafts.flatMap(draft => formatInvoiceForTallyExcel(draft.invoice || draft));
  const masterWs = XLSX.utils.json_to_sheet(allRows);
  masterWs['!cols'] = [
    { wch: 14 }, { wch: 13 }, { wch: 18 }, { wch: 28 }, { wch: 18 },
    { wch: 8 }, { wch: 30 }, { wch: 24 }, { wch: 14 }, { wch: 10 },
    { wch: 10 }, { wch: 12 }, { wch: 16 }, { wch: 12 }, { wch: 12 },
    { wch: 12 }, { wch: 12 }, { wch: 14 }, { wch: 20 }, { wch: 25 }, { wch: 10 }
  ];
  XLSX.utils.book_append_sheet(wb, masterWs, 'Consolidated Drafts');

  // Sheet 2: Voucher Summary
  const summaryRows = drafts.map((draft, idx) => {
    const inv = draft.invoice || draft;
    return {
      'S.No': idx + 1,
      'Draft ID': draft.id || `DFT-${idx + 1}`,
      'Invoice No': inv.invoiceNo || '—',
      'Invoice Date': inv.invoiceDate || '—',
      'Supplier Name': inv.supplierRaw || '—',
      'Mapped Ledger': inv.supplierMapped || 'Pending',
      'Line Items': (inv.lines || []).length,
      'Taxable (₹)': Number(inv.subtotal || 0),
      'GST (₹)': Number((inv.cgst || 0) + (inv.sgst || 0) + (inv.igst || 0)),
      'Grand Total (₹)': Number(inv.grandTotal || 0),
      'Saved At': draft.savedAt || new Date().toISOString().replace('T', ' ').substring(0, 19)
    };
  });
  const summaryWs = XLSX.utils.json_to_sheet(summaryRows);
  summaryWs['!cols'] = [
    { wch: 6 }, { wch: 16 }, { wch: 16 }, { wch: 14 }, { wch: 28 },
    { wch: 24 }, { wch: 12 }, { wch: 14 }, { wch: 12 }, { wch: 16 }, { wch: 20 }
  ];
  XLSX.utils.book_append_sheet(wb, summaryWs, 'Voucher Register');

  XLSX.writeFile(wb, `${filename}.xlsx`);
}
