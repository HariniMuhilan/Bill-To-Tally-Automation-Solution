import React, { useState } from 'react';
import { extractFromRawOcr } from '../services/api';

export default function ReviewView({
  invoices,
  currentInvoiceId,
  onSelectInvoice,
  onUpdateInvoice,
  onPreviewXml,
  onApprove,
  onShowToast
}) {
  const inv = invoices.find(i => i.id === currentInvoiceId) || invoices[0] || {};

  const [zoom, setZoom] = useState(100);
  const [rotation, setRotation] = useState(0);
  const [showBBoxes, setShowBBoxes] = useState(true);
  const [isReExtracting, setIsReExtracting] = useState(false);

  if (!inv.id) {
    return (
      <section className="tab-pane active" id="tab-review">
        <div className="glass-card" style={{ padding: '64px 32px', textAlign: 'center', maxWidth: '640px', margin: '40px auto' }}>
          <i className="fa-solid fa-file-invoice" style={{ fontSize: '3rem', color: 'var(--palette-azure)', marginBottom: '16px', display: 'block' }}></i>
          <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '8px' }}>No Bill Selected for Review</h3>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem', marginBottom: '12px', lineHeight: 1.5 }}>
            Upload an invoice or receipt image in the Invoice Inbox to scan it with PaddleOCR and extract structured data with Gemini.
          </p>
        </div>
      </section>
    );
  }

  // Update line item
  function handleLineChange(index, field, value) {
    const updatedLines = [...(inv.lines || [])];
    const currentLine = { ...updatedLines[index], [field]: value };

    // Recalculate line totals
    const qty = Number(currentLine.qty) || 0;
    const rate = Number(currentLine.rate) || 0;
    const taxRate = Number(currentLine.taxRate) || 0;

    currentLine.taxable = Math.round(qty * rate * 100) / 100;
    currentLine.taxAmount = Math.round(currentLine.taxable * (taxRate / 100) * 100) / 100;
    currentLine.total = Math.round((currentLine.taxable + currentLine.taxAmount) * 100) / 100;

    updatedLines[index] = currentLine;

    // Recalculate invoice totals
    let sumTaxable = 0;
    let sumTax = 0;
    updatedLines.forEach(l => {
      sumTaxable += l.taxable || 0;
      sumTax += l.taxAmount || 0;
    });

    const grandTotal = Math.round((sumTaxable + sumTax) * 100) / 100;
    const cgst = Math.round((sumTax / 2) * 100) / 100;
    const sgst = Math.round((sumTax / 2) * 100) / 100;

    onUpdateInvoice({
      ...inv,
      lines: updatedLines,
      subtotal: sumTaxable,
      cgst,
      sgst,
      grandTotal
    });
  }

  function handleAddLine() {
    const newLines = [...(inv.lines || [])];
    newLines.push({
      lineNo: newLines.length + 1,
      descRaw: 'New Line Item',
      stockItem: '',
      qty: 1,
      unit: 'NOS',
      rate: 1000,
      taxable: 1000,
      taxRate: 18,
      taxAmount: 180,
      total: 1180,
      confidence: 100.0
    });

    let sumTaxable = 0;
    let sumTax = 0;
    newLines.forEach(l => {
      sumTaxable += l.taxable || 0;
      sumTax += l.taxAmount || 0;
    });

    onUpdateInvoice({
      ...inv,
      lines: newLines,
      subtotal: sumTaxable,
      cgst: sumTax / 2,
      sgst: sumTax / 2,
      grandTotal: sumTaxable + sumTax
    });
    onShowToast('New line item added to invoice grid.', 'success');
  }

  function handleDeleteLine(index) {
    if ((inv.lines || []).length <= 1) {
      onShowToast('Cannot delete the only line item of an invoice.', 'warning');
      return;
    }
    const newLines = inv.lines.filter((_, idx) => idx !== index);
    let sumTaxable = 0;
    let sumTax = 0;
    newLines.forEach(l => {
      sumTaxable += l.taxable || 0;
      sumTax += l.taxAmount || 0;
    });

    onUpdateInvoice({
      ...inv,
      lines: newLines,
      subtotal: sumTaxable,
      cgst: sumTax / 2,
      sgst: sumTax / 2,
      grandTotal: sumTaxable + sumTax
    });
    onShowToast('Line item removed.', 'success');
  }

  async function handleReExtract() {
    if (!inv.rawOcrText) {
      onShowToast('No raw OCR text captured for this invoice.', 'warning');
      return;
    }
    setIsReExtracting(true);
    onShowToast('Submitting PaddleOCR text to Gemini 2.5 Flash...', 'warning');

    try {
      const ext = await extractFromRawOcr({
        raw_text: inv.rawOcrText,
        lines: inv.ocrLines || []
      });

      const lineItems = (ext.line_items || []).map((l, idx) => ({
        lineNo: idx + 1,
        descRaw: l.item_description || 'Item',
        hsn: l.hsn_sac_code || '',
        stockItem: l.tally_item_name || '',
        qty: l.quantity != null ? Number(l.quantity) : 1,
        unit: l.unit_of_measure || 'NOS',
        rate: l.unit_price != null ? Number(l.unit_price) : 0,
        taxable: l.taxable_amount != null ? Number(l.taxable_amount) : 0,
        taxRate: l.gst_rate_percent != null ? Number(l.gst_rate_percent) : 0,
        taxAmount: (Number(l.cgst_amount || 0) + Number(l.sgst_amount || 0) + Number(l.igst_amount || 0)),
        total: l.total_line_amount != null ? Number(l.total_line_amount) : 0,
        confidence: Math.round((l.confidence_score || 0.95) * 1000) / 10
      }));

      const subtotal = ext.subtotal_amount != null 
        ? Number(ext.subtotal_amount) 
        : (lineItems.reduce((acc, l) => acc + (l.taxable || 0), 0) || 0);
      const cgst = ext.cgst_amount != null ? Number(ext.cgst_amount) : 0;
      const sgst = ext.sgst_amount != null ? Number(ext.sgst_amount) : 0;
      const igst = ext.igst_amount != null ? Number(ext.igst_amount) : 0;
      const grandTotal = ext.total_amount != null 
        ? Number(ext.total_amount) 
        : (subtotal + cgst + sgst + igst);

      const updated = {
        ...inv,
        supplierRaw: ext.supplier_name || inv.supplierRaw,
        invoiceNo: ext.invoice_number || inv.invoiceNo,
        invoiceDate: ext.invoice_date || inv.invoiceDate,
        tallyDate: ext.invoice_date ? ext.invoice_date.replace(/-/g, '') : inv.tallyDate,
        gstin: ext.supplier_gstin || inv.gstin,
        type: ext.invoice_mode === 'inventory' ? 'Inventory Purchase' : 'Accounting Purchase',
        subtotal,
        cgst,
        sgst,
        igst,
        grandTotal,
        confidence: ext.overall_confidence ? `${Math.round(ext.overall_confidence * 1000) / 10}%` : inv.confidence,
        warnings: ext.warnings || [],
        lines: lineItems.length > 0 ? lineItems : inv.lines
      };

      onUpdateInvoice(updated);

      const hasKeyWarning = (ext.warnings || []).some(w => w.field_name === 'gemini_api_key');
      if (hasKeyWarning) {
        onShowToast('GEMINI_API_KEY is not set in backend/.env. Used fallback parser.', 'warning');
      } else {
        onShowToast(`Gemini extraction complete! Extracted ${lineItems.length} line items.`, 'success');
      }
    } catch (err) {
      onShowToast(`Extraction request failed: ${err.message}`, 'danger');
    } finally {
      setIsReExtracting(false);
    }
  }

  // Pre-posting validation checks
  const hasRequired = Boolean(inv.invoiceNo && inv.invoiceDate && inv.supplierRaw && inv.grandTotal > 0);
  const mathMatches = Math.abs(
    (inv.lines || []).reduce((acc, l) => acc + (l.total || 0), 0) - (inv.grandTotal || 0)
  ) < 0.05;
  const supplierMapped = Boolean(inv.supplierMapped);
  const itemsMapped = (inv.lines || []).every(l => Boolean(l.stockItem));
  const isDuplicate = Boolean(inv.invoiceNo && inv.invoiceNo !== '—' && inv.invoiceNo !== '') && 
    invoices.some(other => other.id !== inv.id && other.invoiceNo === inv.invoiceNo && other.supplierRaw === inv.supplierRaw);
  
  const canApprove = Boolean(inv.supplierRaw && (inv.grandTotal != null && inv.grandTotal > 0));

  const geminiWarning = (inv.warnings || []).find(w => w.field_name === 'gemini_api_key');
  const rateLimitWarning = (inv.warnings || []).find(w => w.field_name === 'gemini_rate_limit');
  const apiErrorWarning = (inv.warnings || []).find(w => w.field_name === 'gemini_api');
  const isFallbackUsed = Boolean(geminiWarning || rateLimitWarning || apiErrorWarning);

  return (
    <section className="tab-pane active" id="tab-review">
      {/* Sample Invoice Selector & Context Bar */}
      <div className="review-selector-bar">
        <div className="sample-picker-group">
          <label className="form-label" style={{ margin: 0, fontWeight: 700 }}>Active Invoice:</label>
          <select 
            className="form-control review-select-input" 
            value={inv.id}
            onChange={(e) => onSelectInvoice(e.target.value)}
          >
            {invoices.map(item => (
              <option key={item.id} value={item.id}>
                {item.id}: {item.supplierRaw?.substring(0, 22)} (₹{Number(item.grandTotal || 0).toLocaleString('en-IN')}) - {item.status}
              </option>
            ))}
          </select>
          <span className={`status-badge ${inv.status === 'APPROVED' ? 'approved' : (inv.status === 'POSTED' ? 'posted' : 'needs-review')}`}>
            <i className={`fa-solid ${inv.status === 'APPROVED' ? 'fa-check' : 'fa-clock'}`}></i> {inv.status}
          </span>
        </div>

        <div style={{ display: 'flex', gap: '8px' }}>
          <button 
            type="button" 
            className="btn btn-secondary btn-sm" 
            disabled={isReExtracting}
            onClick={handleReExtract}
          >
            <i className={`fa-solid ${isReExtracting ? 'fa-spinner fa-spin' : 'fa-wand-magic-sparkles'}`}></i> {isReExtracting ? 'Extracting...' : 'Re-Extract (Gemini)'}
          </button>
          <button 
            type="button" 
            className="btn btn-secondary btn-sm" 
            onClick={() => onPreviewXml(inv)}
          >
            <i className="fa-solid fa-code"></i> Tally XML
          </button>
        </div>
      </div>

      {/* Split Screen Container */}
      <div className="split-review-container">
        
        {/* Left Pane: Original Document Preview */}
        <div className="doc-preview-pane">
          <div className="doc-toolbar">
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)' }}>PREVIEW</span>
              <span className="badge" style={{ fontSize: '0.72rem', background: 'var(--bg-card)', padding: '2px 8px', borderRadius: '4px', border: '1px solid var(--border-subtle)' }}>
                Page 1 / 1
              </span>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <button 
                type="button" 
                className="btn btn-secondary btn-icon" 
                onClick={() => setZoom(Math.max(60, zoom - 15))}
              >
                <i className="fa-solid fa-minus"></i>
              </button>
              <span style={{ fontSize: '0.75rem', fontFamily: 'var(--font-mono)', color: 'var(--text-muted)', width: '44px', textAlign: 'center' }}>
                {zoom}%
              </span>
              <button 
                type="button" 
                className="btn btn-secondary btn-icon" 
                onClick={() => setZoom(Math.min(180, zoom + 15))}
              >
                <i className="fa-solid fa-plus"></i>
              </button>
              <button 
                type="button" 
                className="btn btn-secondary btn-icon" 
                onClick={() => setRotation((rotation + 90) % 360)}
              >
                <i className="fa-solid fa-rotate-right"></i>
              </button>
              <button 
                type="button" 
                className="btn btn-secondary btn-sm" 
                onClick={() => setShowBBoxes(!showBBoxes)}
              >
                <i className="fa-solid fa-vector-square"></i> Bounding Boxes: {showBBoxes ? 'ON' : 'OFF'}
              </button>
            </div>
          </div>

          <div className="doc-viewport" style={{ overflow: 'auto', display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '16px', background: '#0b1120' }}>
            <div 
              style={{ 
                transform: `scale(${zoom / 100}) rotate(${rotation}deg)`, 
                transformOrigin: 'top center',
                transition: 'transform 0.15s ease',
                maxWidth: '100%',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center'
              }}
            >
              {/* Scanned Bill Image */}
              {(inv.imageUrl || inv.previewUrl) ? (
                <div style={{ position: 'relative', borderRadius: '8px', overflow: 'hidden', boxShadow: '0 8px 30px rgba(0,0,0,0.5)', background: '#1e293b' }}>
                  <img 
                    src={inv.imageUrl || inv.previewUrl} 
                    style={{ maxWidth: '100%', maxHeight: '550px', objectFit: 'contain', display: 'block' }} 
                    alt="Original Bill Scan" 
                  />
                  {/* Real PaddleOCR Detected Lines Overlay */}
                  {showBBoxes && (inv.ocrLines || []).length > 0 && (
                    <div style={{ position: 'absolute', top: '10px', right: '10px', background: 'rgba(2, 132, 199, 0.9)', color: '#fff', padding: '4px 10px', borderRadius: '4px', fontSize: '0.72rem', fontWeight: 700, boxShadow: '0 2px 8px rgba(0,0,0,0.3)' }}>
                      <i className="fa-solid fa-vector-square"></i> PaddleOCR: {(inv.ocrLines || []).length} text lines detected
                    </div>
                  )}
                </div>
              ) : (
                /* Document Card when no image file is attached */
                <div className="glass-card" style={{ width: '540px', padding: '24px', background: '#ffffff', color: '#111827', boxShadow: '0 8px 25px rgba(0,0,0,0.2)' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid #e5e7eb', paddingBottom: '12px', marginBottom: '16px' }}>
                    <div>
                      <div style={{ fontWeight: 800, fontSize: '1.1rem', color: '#0f172a' }}>{inv.supplierRaw || 'Supplier Document'}</div>
                      <div style={{ fontSize: '0.8rem', color: '#64748b', marginTop: '2px' }}>
                        {inv.gstin ? `GSTIN: ${inv.gstin}` : 'No GSTIN Detected'}
                      </div>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <div style={{ fontWeight: 700, fontSize: '0.85rem' }}>{inv.invoiceNo ? `Invoice #${inv.invoiceNo}` : 'Receipt / Bill'}</div>
                      <div style={{ fontSize: '0.78rem', color: '#64748b' }}>{inv.invoiceDate || 'Date: —'}</div>
                    </div>
                  </div>

                  <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.82rem', marginBottom: '16px' }}>
                    <thead>
                      <tr style={{ background: '#f8fafc', borderBottom: '1px solid #e2e8f0', textAlign: 'left' }}>
                        <th style={{ padding: '8px' }}>Item</th>
                        <th style={{ padding: '8px', textAlign: 'right' }}>Qty</th>
                        <th style={{ padding: '8px', textAlign: 'right' }}>Rate (₹)</th>
                        <th style={{ padding: '8px', textAlign: 'right' }}>Total (₹)</th>
                      </tr>
                    </thead>
                    <tbody>
                      {(inv.lines || []).map((l, i) => (
                        <tr key={i} style={{ borderBottom: '1px solid #f1f5f9' }}>
                          <td style={{ padding: '8px' }}>{l.descRaw}</td>
                          <td style={{ padding: '8px', textAlign: 'right' }}>{l.qty} {l.unit}</td>
                          <td style={{ padding: '8px', textAlign: 'right' }}>{Number(l.rate || 0).toFixed(2)}</td>
                          <td style={{ padding: '8px', textAlign: 'right', fontWeight: 600 }}>{Number(l.total || 0).toFixed(2)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>

                  <div style={{ borderTop: '2px solid #e2e8f0', paddingTop: '12px', textAlign: 'right' }}>
                    <div style={{ fontSize: '0.82rem', color: '#64748b' }}>
                      Subtotal: ₹ {Number(inv.subtotal || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                    </div>
                    <div style={{ fontSize: '0.82rem', color: '#64748b', marginTop: '2px' }}>
                      Taxes (CGST+SGST): ₹ {Number((inv.cgst || 0) + (inv.sgst || 0)).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                    </div>
                    <div style={{ fontSize: '1.1rem', fontWeight: 800, color: '#0f172a', marginTop: '4px' }}>
                      Grand Total: ₹ {Number(inv.grandTotal || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* PaddleOCR Detected Text Inspection Drawer */}
            {(inv.ocrLines || []).length > 0 && (
              <div style={{ width: '100%', maxWidth: '640px', marginTop: '20px', background: '#1e293b', border: '1px solid #334155', borderRadius: '8px', overflow: 'hidden' }}>
                <div style={{ background: '#0f172a', padding: '10px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #334155' }}>
                  <span style={{ fontSize: '0.78rem', fontWeight: 700, color: '#38bdf8' }}>
                    <i className="fa-solid fa-list-ol"></i> PADDLEOCR EXTRACTED TEXT ({inv.ocrLines.length} lines)
                  </span>
                  <span style={{ fontSize: '0.72rem', color: '#94a3b8' }}>
                    Confidence: {inv.confidence}
                  </span>
                </div>
                <div style={{ maxHeight: '180px', overflowY: 'auto', padding: '10px 16px', fontSize: '0.78rem', color: '#cbd5e1', lineHeight: '1.6' }}>
                  {inv.ocrLines.map((line, idx) => (
                    <div key={idx} style={{ display: 'flex', justifyContent: 'space-between', padding: '3px 0', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                      <span className="mono" style={{ color: '#e2e8f0' }}>{line.text}</span>
                      <span className="mono" style={{ color: line.confidence > 0.85 ? '#34d399' : '#f59e0b', fontSize: '0.72rem' }}>
                        {Math.round((line.confidence || 0) * 100)}%
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Right Pane: Editable Fields & Line Items */}
        <div className="doc-edit-pane">
          
          {/* AI Extraction Engine Status Banner */}
          {isFallbackUsed ? (
            <div style={{
              background: 'rgba(245, 158, 11, 0.1)',
              border: '1px solid rgba(245, 158, 11, 0.35)',
              borderRadius: '8px',
              padding: '12px 16px',
              marginBottom: '16px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              gap: '12px'
            }}>
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: '10px' }}>
                <i className="fa-solid fa-triangle-exclamation" style={{ color: '#f59e0b', fontSize: '1.2rem', marginTop: '2px' }}></i>
                <div>
                  <div style={{ fontSize: '0.85rem', fontWeight: 700, color: '#fbbf24' }}>
                    {geminiWarning ? 'Gemini AI Inactive: GEMINI_API_KEY Not Set in backend/.env' : 'Gemini Fallback Notice'}
                  </div>
                  <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)', marginTop: '2px' }}>
                    {geminiWarning?.message || rateLimitWarning?.message || apiErrorWarning?.message || 'Extracted using local heuristic fallback parser.'}
                  </div>
                </div>
              </div>
              <button 
                type="button" 
                className="btn btn-secondary btn-sm"
                style={{ whiteSpace: 'nowrap', borderColor: '#f59e0b', color: '#fbbf24' }}
                disabled={isReExtracting}
                onClick={handleReExtract}
              >
                <i className={`fa-solid ${isReExtracting ? 'fa-spinner fa-spin' : 'fa-wand-magic-sparkles'}`}></i> {isReExtracting ? 'Extracting...' : 'Re-Extract with Gemini'}
              </button>
            </div>
          ) : (
            <div style={{
              background: 'rgba(16, 185, 129, 0.08)',
              border: '1px solid rgba(16, 185, 129, 0.25)',
              borderRadius: '8px',
              padding: '8px 14px',
              marginBottom: '16px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between'
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.82rem', color: '#34d399', fontWeight: 600 }}>
                <i className="fa-solid fa-wand-magic-sparkles"></i> AI Extraction: Gemini 2.5 Flash reasoning active
              </div>
              <button 
                type="button" 
                className="btn btn-secondary btn-sm"
                disabled={isReExtracting}
                onClick={handleReExtract}
                style={{ fontSize: '0.75rem', padding: '2px 8px' }}
              >
                <i className={`fa-solid ${isReExtracting ? 'fa-spinner fa-spin' : 'fa-rotate'}`}></i> Re-Run
              </button>
            </div>
          )}

          {/* Header Metadata Section */}
          <div className="glass-card" style={{ padding: '20px', marginBottom: '20px' }}>
            <div className="card-header-compact">
              <span className="card-title"><i className="fa-solid fa-file-lines"></i> Invoice Header Information</span>
              <span className="confidence-pill"><i className="fa-solid fa-shield-check"></i> Overall OCR Confidence: {inv.confidence}</span>
            </div>

            <div className="form-grid-3">
              <div className="form-group">
                <label className="form-label">Raw Supplier Name (OCR)</label>
                <input 
                  type="text" 
                  className="form-control" 
                  value={inv.supplierRaw || ''}
                  onChange={(e) => onUpdateInvoice({ ...inv, supplierRaw: e.target.value })}
                />
              </div>

              <div className="form-group">
                <label className="form-label">Mapped Tally Supplier Ledger</label>
                <input 
                  type="text" 
                  className="form-control"
                  placeholder="e.g. Sundry Creditors ledger in Tally"
                  value={inv.supplierMapped || ''}
                  onChange={(e) => onUpdateInvoice({ ...inv, supplierMapped: e.target.value })}
                />
              </div>

              <div className="form-group">
                <label className="form-label">Invoice Number</label>
                <input 
                  type="text" 
                  className="form-control mono" 
                  value={inv.invoiceNo || ''}
                  onChange={(e) => onUpdateInvoice({ ...inv, invoiceNo: e.target.value })}
                />
              </div>

              <div className="form-group">
                <label className="form-label">Invoice Date</label>
                <input 
                  type="date" 
                  className="form-control mono" 
                  value={inv.invoiceDate || ''}
                  onChange={(e) => onUpdateInvoice({ ...inv, invoiceDate: e.target.value, tallyDate: e.target.value.replace(/-/g, '') })}
                />
              </div>

              <div className="form-group">
                <label className="form-label">Supplier GSTIN</label>
                <input 
                  type="text" 
                  className="form-control mono" 
                  value={inv.gstin || ''}
                  onChange={(e) => onUpdateInvoice({ ...inv, gstin: e.target.value })}
                />
              </div>

              <div className="form-group">
                <label className="form-label">Voucher Mode</label>
                <select 
                  className="form-control"
                  value={inv.type || 'Inventory Purchase'}
                  onChange={(e) => onUpdateInvoice({ ...inv, type: e.target.value })}
                >
                  <option value="Inventory Purchase">Inventory Purchase (With Stock)</option>
                  <option value="Accounting Purchase">Accounting Purchase (Expense Ledger)</option>
                </select>
              </div>
            </div>
          </div>

          {/* Line Items Grid */}
          <div className="glass-card" style={{ padding: '20px', marginBottom: '20px' }}>
            <div className="card-header-compact">
              <span className="card-title"><i className="fa-solid fa-list-check"></i> Line Items Grid & Tax Allocations</span>
              <span className="badge" style={{ background: 'var(--bg-surface)', padding: '4px 10px', borderRadius: '12px', fontSize: '0.74rem' }}>
                {(inv.lines || []).length} items
              </span>
            </div>

            <div style={{ overflowX: 'auto' }}>
              <table className="data-table" style={{ fontSize: '0.8rem' }}>
                <thead>
                  <tr>
                    <th style={{ width: '32px' }}>#</th>
                    <th>Extracted Item Description</th>
                    <th>Tally Stock Item / Ledger</th>
                    <th style={{ width: '70px', textAlign: 'right' }}>Qty</th>
                    <th style={{ width: '60px', textAlign: 'center' }}>Unit</th>
                    <th style={{ width: '90px', textAlign: 'right' }}>Rate (₹)</th>
                    <th style={{ width: '95px', textAlign: 'right' }}>Taxable (₹)</th>
                    <th style={{ width: '75px' }}>Tax %</th>
                    <th style={{ width: '95px', textAlign: 'right' }}>Total (₹)</th>
                    <th style={{ width: '36px' }}></th>
                  </tr>
                </thead>
                <tbody>
                  {(inv.lines || []).map((l, index) => (
                    <tr key={index}>
                      <td className="mono" style={{ fontWeight: 700, color: 'var(--text-muted)' }}>{index + 1}</td>
                      <td>
                        <input 
                          type="text" 
                          className="form-control" 
                          value={l.descRaw || ''}
                          onChange={(e) => handleLineChange(index, 'descRaw', e.target.value)}
                        />
                      </td>
                      <td>
                        <input 
                          type="text" 
                          className="form-control"
                          placeholder="Tally Item / Ledger"
                          value={l.stockItem || ''}
                          onChange={(e) => handleLineChange(index, 'stockItem', e.target.value)}
                        />
                      </td>
                      <td>
                        <input 
                          type="number" 
                          className="form-control mono" 
                          style={{ textAlign: 'right' }}
                          value={l.qty || 1}
                          onChange={(e) => handleLineChange(index, 'qty', e.target.value)}
                        />
                      </td>
                      <td>
                        <input 
                          type="text" 
                          className="form-control mono" 
                          style={{ textAlign: 'center' }}
                          value={l.unit || 'NOS'}
                          onChange={(e) => handleLineChange(index, 'unit', e.target.value)}
                        />
                      </td>
                      <td>
                        <input 
                          type="number" 
                          className="form-control mono" 
                          style={{ textAlign: 'right' }}
                          value={l.rate || 0}
                          onChange={(e) => handleLineChange(index, 'rate', e.target.value)}
                        />
                      </td>
                      <td>
                        <input 
                          type="text" 
                          className="form-control mono" 
                          style={{ textAlign: 'right', background: 'var(--bg-surface)' }}
                          value={Number(l.taxable || 0).toFixed(2)}
                          readOnly
                        />
                      </td>
                      <td>
                        <select 
                          className="form-control mono"
                          value={l.taxRate || 18}
                          onChange={(e) => handleLineChange(index, 'taxRate', Number(e.target.value))}
                        >
                          <option value="18">18%</option>
                          <option value="12">12%</option>
                          <option value="5">5%</option>
                          <option value="0">0%</option>
                        </select>
                      </td>
                      <td>
                        <strong className="mono" style={{ color: '#059669' }}>
                          ₹ {Number(l.total || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                        </strong>
                      </td>
                      <td style={{ textAlign: 'center' }}>
                        <button 
                          type="button" 
                          className="btn btn-secondary btn-icon" 
                          style={{ width: '24px', height: '24px', color: '#ef4444' }}
                          onClick={() => handleDeleteLine(index)}
                          title="Remove item"
                        >
                          <i className="fa-solid fa-trash-can" style={{ fontSize: '0.7rem' }}></i>
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="review-lines-footer">
              <button type="button" className="btn btn-secondary btn-sm" onClick={handleAddLine}>
                <i className="fa-solid fa-plus"></i> Add Line Item
              </button>
              
              <div className="review-totals-summary">
                <div>Taxable: <strong className="mono">₹ {Number(inv.subtotal || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</strong></div>
                <div>GST: <strong className="mono">₹ {Number((inv.cgst || 0) + (inv.sgst || 0)).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</strong></div>
                <div>Grand Total: <strong className="mono" style={{ color: 'var(--color-success-green)', fontSize: '0.95rem' }}>₹ {Number(inv.grandTotal || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</strong></div>
              </div>
            </div>
          </div>

          {/* Validation Warnings Panel */}
          <div className="glass-card" style={{ padding: '20px', marginBottom: '20px' }}>
            <span className="card-title" style={{ marginBottom: '14px', display: 'block' }}>
              <i className="fa-solid fa-shield-halved"></i> Pre-Posting Integrity & Rule Validation
            </span>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '0.82rem' }}>
                <i className={`fa-solid ${hasRequired ? 'fa-circle-check' : 'fa-circle-exclamation'}`} style={{ color: hasRequired ? '#10b981' : '#ef4444' }}></i>
                <span>Required Header Fields (Supplier, Invoice No, Valid Date, Non-zero Total): <strong>{hasRequired ? 'PASS' : 'FAIL'}</strong></span>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '0.82rem' }}>
                <i className={`fa-solid ${mathMatches ? 'fa-circle-check' : 'fa-circle-exclamation'}`} style={{ color: mathMatches ? '#10b981' : '#ef4444' }}></i>
                <span>Arithmetic Reconciliation (Sum of line items matches grand total): <strong>{mathMatches ? 'PASS' : 'FAIL'}</strong></span>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '0.82rem' }}>
                <i className={`fa-solid ${!isDuplicate ? 'fa-circle-check' : 'fa-circle-exclamation'}`} style={{ color: !isDuplicate ? '#10b981' : '#ef4444' }}></i>
                <span>Duplicate Guard (Supplier + Invoice No uniqueness): <strong>{!isDuplicate ? 'PASS (Unique)' : 'FAIL (Duplicate Detected)'}</strong></span>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '0.82rem' }}>
                <i className={`fa-solid ${supplierMapped && itemsMapped ? 'fa-circle-check' : 'fa-triangle-exclamation'}`} style={{ color: supplierMapped && itemsMapped ? '#10b981' : '#f59e0b' }}></i>
                <span>Tally Masters Mapping (Supplier & Items linked to TallyPrime): <strong>{supplierMapped && itemsMapped ? 'VERIFIED' : 'PENDING MAPPING'}</strong></span>
              </div>
            </div>
          </div>

          {/* Action Footer */}
          <div className="review-action-footer">
            <div className="action-footer-left">
              <button 
                type="button" 
                className="btn btn-secondary btn-sm"
                onClick={() => {
                  onUpdateInvoice({ ...inv, status: 'NEEDS_CORRECTION' });
                  onShowToast('Invoice marked as NEEDS_CORRECTION.', 'warning');
                }}
              >
                <i className="fa-solid fa-arrow-rotate-left"></i> Send for Correction
              </button>
            </div>

            <div className="action-footer-right">
              <button 
                type="button" 
                className="btn btn-secondary" 
                onClick={() => onPreviewXml(inv)}
              >
                <i className="fa-solid fa-code"></i> Preview Tally XML
              </button>
              
              <button 
                type="button" 
                className="btn btn-primary btn-approve" 
                disabled={!canApprove}
                title={!canApprove ? 'Provide supplier name and valid total before approving' : 'Approve invoice and store in Tally Connector Excel Sheet'}
                onClick={() => onApprove(inv)}
              >
                <i className="fa-solid fa-check"></i> Approve
              </button>
            </div>
          </div>

        </div>
      </div>
    </section>
  );
}
