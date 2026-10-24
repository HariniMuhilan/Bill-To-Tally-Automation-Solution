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
 * Downloads a specific draft sheet (which may contain one or multiple vouchers).
 */
export function downloadDraftSheetWorkbook(sheet) {
  if (!sheet) return;
  const invoices = sheet.invoices && sheet.invoices.length > 0 
    ? sheet.invoices 
    : (sheet.invoice ? [sheet.invoice] : []);

  if (invoices.length === 0) return;

  const wb = XLSX.utils.book_new();

  // Sheet 1: Line-by-line Tally voucher ledger
  const allRows = invoices.flatMap(inv => formatInvoiceForTallyExcel(inv));
  const ws = XLSX.utils.json_to_sheet(allRows);

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

  XLSX.utils.book_append_sheet(wb, ws, 'Voucher Items');

  // Sheet 2: Summary Register
  const summaryRows = invoices.map((inv, idx) => ({
    'S.No': idx + 1,
    'Invoice ID': inv.id,
    'Invoice / Bill No': inv.invoiceNo || '—',
    'Voucher Date': inv.invoiceDate || '—',
    'Supplier Name': inv.supplierRaw || '—',
    'Mapped Tally Ledger': inv.supplierMapped || 'Pending',
    'Line Items Count': (inv.lines || []).length,
    'Taxable Amount (₹)': Number(inv.subtotal || 0),
    'Total Tax (₹)': Number((inv.cgst || 0) + (inv.sgst || 0) + (inv.igst || 0)),
    'Grand Total (₹)': Number(inv.grandTotal || 0),
    'Voucher Mode': inv.type || 'Accounting Purchase'
  }));

  const summaryWs = XLSX.utils.json_to_sheet(summaryRows);
  summaryWs['!cols'] = [
    { wch: 6 }, { wch: 14 }, { wch: 18 }, { wch: 14 }, { wch: 28 },
    { wch: 24 }, { wch: 16 }, { wch: 16 }, { wch: 14 }, { wch: 18 }, { wch: 22 }
  ];
  XLSX.utils.book_append_sheet(wb, summaryWs, 'Voucher Register');

  const safeName = (sheet.fileName || `Tally_Draft_${sheet.id}`)
    .replace(/[\\/?*[\]:]/g, '_');
  const finalFilename = safeName.endsWith('.xlsx') ? safeName : `${safeName}.xlsx`;

  XLSX.writeFile(wb, finalFilename);
}

/**
 * Downloads all stored draft sheets consolidated into one master file.
 */
export function downloadAllDraftsExcel(draftSheets, filename = 'Tally_All_Draft_Sheets_Master.xlsx') {
  if (!draftSheets || draftSheets.length === 0) return;

  const wb = XLSX.utils.book_new();

  // Flatten all invoices across all sheets
  const allInvoices = draftSheets.flatMap(sheet => 
    sheet.invoices && sheet.invoices.length > 0 
      ? sheet.invoices 
      : (sheet.invoice ? [sheet.invoice] : [])
  );

  const allRows = allInvoices.flatMap(inv => formatInvoiceForTallyExcel(inv));
  const ws = XLSX.utils.json_to_sheet(allRows);
  ws['!cols'] = [
    { wch: 14 }, { wch: 13 }, { wch: 18 }, { wch: 28 }, { wch: 18 },
    { wch: 8 }, { wch: 30 }, { wch: 24 }, { wch: 14 }, { wch: 10 },
    { wch: 10 }, { wch: 12 }, { wch: 16 }, { wch: 12 }, { wch: 12 },
    { wch: 12 }, { wch: 12 }, { wch: 14 }, { wch: 20 }, { wch: 25 }, { wch: 10 }
  ];
  XLSX.utils.book_append_sheet(wb, ws, 'All Draft Vouchers');

  // Summary per sheet
  const sheetSummary = draftSheets.map((sheet, idx) => {
    const invs = sheet.invoices && sheet.invoices.length > 0 
      ? sheet.invoices 
      : (sheet.invoice ? [sheet.invoice] : []);
    const sumTotal = invs.reduce((acc, i) => acc + Number(i.grandTotal || 0), 0);
    return {
      'S.No': idx + 1,
      'Sheet / File Name': sheet.fileName,
      'Sheet ID': sheet.id,
      'Vouchers Count': invs.length,
      'Total Amount (₹)': sumTotal,
      'Created / Saved At': sheet.savedAt || '—',
      'Last Updated': sheet.updatedAt || sheet.savedAt || '—'
    };
  });
  const sheetWs = XLSX.utils.json_to_sheet(sheetSummary);
  sheetWs['!cols'] = [
    { wch: 6 }, { wch: 32 }, { wch: 16 }, { wch: 16 }, { wch: 18 }, { wch: 22 }, { wch: 22 }
  ];
  XLSX.utils.book_append_sheet(wb, sheetWs, 'Sheets Summary');

  const finalName = filename.endsWith('.xlsx') ? filename : `${filename}.xlsx`;
  XLSX.writeFile(wb, finalName);
}
