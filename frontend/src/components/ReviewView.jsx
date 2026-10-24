import React, { useState } from 'react';

export default function ReviewView({
  invoices,
  currentInvoiceId,
  onSelectInvoice,
  onUpdateInvoice,
  onPreviewXml,
  onConfirmPost,
  onShowToast
}) {
  const inv = invoices.find(i => i.id === currentInvoiceId) || invoices[0] || {};

  const [zoom, setZoom] = useState(100);
  const [rotation, setRotation] = useState(0);
  const [showBBoxes, setShowBBoxes] = useState(true);

  if (!inv.id) {
    return <div style={{ padding: '32px' }}>No invoice selected.</div>;
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

  // Pre-posting validation checks
  const hasRequired = Boolean(inv.invoiceNo && inv.invoiceDate && inv.supplierRaw && inv.grandTotal > 0);
  const mathMatches = Math.abs(
    (inv.lines || []).reduce((acc, l) => acc + (l.total || 0), 0) - (inv.grandTotal || 0)
  ) < 0.05;
  const supplierMapped = Boolean(inv.supplierMapped);
  const itemsMapped = (inv.lines || []).every(l => Boolean(l.stockItem));
  const isDuplicate = invoices.some(other => other.id !== inv.id && other.invoiceNo === inv.invoiceNo && other.supplierRaw === inv.supplierRaw);
  
  const canApprove = hasRequired && mathMatches && supplierMapped && itemsMapped && !isDuplicate;

  return (
    <section className="tab-pane active" id="tab-review">
      {/* Sample Invoice Selector & Context Bar */}
      <div className="review-selector-bar">
        <div className="sample-picker-group">
          <label className="form-label" style={{ margin: 0, fontWeight: 700 }}>Active Invoice:</label>
          <select 
            className="form-control" 
            style={{ width: '340px' }}
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
            onClick={() => onShowToast('PaddleOCR pipeline re-triggered for active bill.', 'success')}
          >
            <i className="fa-solid fa-rotate"></i> Re-Run OCR
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

          <div className="doc-viewport">
            <div 
              className="bill-paper"
              style={{ 
                transform: `scale(${zoom / 100}) rotate(${rotation}deg)`, 
                transition: 'transform 0.15s ease' 
              }}
            >
              {/* Optional Original Image Preview from Backend or Upload */}
              {(inv.imageUrl || inv.previewUrl) && (
                <div style={{ marginBottom: '16px', border: '2px solid var(--palette-azure)', borderRadius: '8px', overflow: 'hidden', background: '#0f172a', textAlign: 'center' }}>
                  <div style={{ background: 'rgba(39, 163, 245, 0.15)', color: '#0284c7', padding: '6px 12px', fontSize: '0.72rem', fontWeight: 800, display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid rgba(39, 163, 245, 0.25)' }}>
                    <span><i className="fa-solid fa-file-image"></i> ORIGINAL SCANNED BILL DOCUMENT</span>
                    <span className="mono" style={{ fontSize: '0.68rem', color: 'var(--text-muted)' }}>{inv.sourceFilename}</span>
                  </div>
                  <img 
                    src={inv.imageUrl || inv.previewUrl} 
                    style={{ maxWidth: '100%', maxHeight: '320px', display: 'block', margin: '0 auto', objectFit: 'contain', padding: '8px' }} 
                    alt="Original Bill Scan" 
                  />
                </div>
              )}

              {/* OCR Bounding Boxes */}
              {showBBoxes && (
                <>
                  <div className="ocr-bbox" style={{ top: '24px', left: '26px', width: '260px', height: '38px' }}>
                    <span className="ocr-tag">Supplier: 99.4%</span>
                  </div>
                  <div className="ocr-bbox" style={{ top: '24px', right: '26px', width: '140px', height: '38px' }}>
                    <span className="ocr-tag">Invoice #: 98.8%</span>
                  </div>
                  <div className="ocr-bbox" style={{ top: '154px', left: '26px', width: '486px', height: '110px' }}>
                    <span className="ocr-tag">Items Table: 97.2%</span>
                  </div>
                  <div className="ocr-bbox" style={{ bottom: '24px', right: '26px', width: '220px', height: '75px' }}>
                    <span className="ocr-tag">Taxes & Total: 99.1%</span>
                  </div>
                </>
              )}

              {/* Document Header */}
              <div className="bill-header">
                <div>
                  <div className="bill-company-name">{inv.supplierRaw}</div>
                  <div style={{ color: '#6b7280', fontSize: '9.5px', marginTop: '2px' }}>
                    <strong>GSTIN:</strong> {inv.gstin || '33AAAAA1234A1Z5'} | <strong>State:</strong> Tamil Nadu (33)
                  </div>
                </div>
                <div className="bill-title-stamp">
                  <div style={{ fontSize: '13px', color: '#111827' }}>TAX INVOICE</div>
                  <div style={{ color: '#4b5563', fontSize: '10px', marginTop: '4px' }}>
                    <strong>Inv No:</strong> <span>{inv.invoiceNo}</span><br />
                    <strong>Date:</strong> <span>{inv.invoiceDate}</span>
                  </div>
                </div>
              </div>

              {/* Billed To Section */}
              <div className="bill-parties-grid">
                <div>
                  <strong style={{ color: '#374151' }}>BILLED TO (BUYER):</strong>
                  <div style={{ fontWeight: 700, marginTop: '2px' }}>ASHAN TECH LABS PRIVATE LIMITED</div>
                  <div style={{ color: '#6b7280' }}>
                    No. 12, Tech Corridor, OMR, Chennai - 600096<br />
                    GSTIN: 33BBBBB5678B1Z2
                  </div>
                </div>
                <div>
                  <strong style={{ color: '#374151' }}>DISPATCH DETAILS:</strong>
                  <div style={{ color: '#6b7280', marginTop: '2px' }}>
                    Place of Supply: Tamil Nadu (33)<br />
                    PO Ref: PO-ATL-9921
                  </div>
                </div>
              </div>

              {/* Items Table */}
              <table className="bill-table">
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Item Description</th>
                    <th>HSN</th>
                    <th style={{ textAlign: 'right' }}>Qty</th>
                    <th style={{ textAlign: 'right' }}>Rate</th>
                    <th style={{ textAlign: 'right' }}>Taxable (₹)</th>
                  </tr>
                </thead>
                <tbody>
                  {(inv.lines || []).map((l, i) => (
                    <tr key={i}>
                      <td>{i + 1}</td>
                      <td>{l.descRaw}</td>
                      <td>{l.hsn || '84719000'}</td>
                      <td style={{ textAlign: 'right' }}>{l.qty} {l.unit}</td>
                      <td style={{ textAlign: 'right' }}>{Number(l.rate || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</td>
                      <td style={{ textAlign: 'right' }}>{Number(l.taxable || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {/* Totals Breakdown */}
              <div className="bill-totals-area">
                <table className="bill-totals-table">
                  <tbody>
                    <tr>
                      <td>Subtotal Taxable:</td>
                      <td className="amount-col">₹ {Number(inv.subtotal || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</td>
                    </tr>
                    <tr>
                      <td>CGST (9%):</td>
                      <td className="amount-col">₹ {Number(inv.cgst || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</td>
                    </tr>
                    <tr>
                      <td>SGST (9%):</td>
                      <td className="amount-col">₹ {Number(inv.sgst || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</td>
                    </tr>
                    <tr className="grand-total-row">
                      <td>Grand Total:</td>
                      <td className="amount-col">₹ {Number(inv.grandTotal || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>

        {/* Right Pane: Editable Fields & Line Items */}
        <div className="doc-edit-pane">
          
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
                <select 
                  className="form-control"
                  value={inv.supplierMapped || ''}
                  onChange={(e) => onUpdateInvoice({ ...inv, supplierMapped: e.target.value })}
                >
                  <option value="">— Unmapped / Select Ledger —</option>
                  <option value="Delta Tech Electronics Pvt Ltd">Delta Tech Electronics Pvt Ltd</option>
                  <option value="Apex Tools & Spares">Apex Tools & Spares</option>
                  <option value="Precision Hardware Fasteners">Precision Hardware Fasteners</option>
                  <option value="Demo Stationers">Demo Stationers</option>
                  <option value="Sri Vari Packing & Cartons">Sri Vari Packing & Cartons</option>
                </select>
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
                        <select 
                          className="form-control"
                          value={l.stockItem || ''}
                          onChange={(e) => handleLineChange(index, 'stockItem', e.target.value)}
                        >
                          <option value="">— Select Tally Item / Ledger —</option>
                          <option value="Sensor Module XYZ-400">Sensor Module XYZ-400</option>
                          <option value="ARM Controller Board v3.2">ARM Controller Board v3.2</option>
                          <option value="Shielded Interface Cable 1.5m">Shielded Interface Cable 1.5m</option>
                          <option value="Precision Torque Screwdriver">Precision Torque Screwdriver</option>
                          <option value="Printing & Stationery Exp">Printing & Stationery Exp</option>
                        </select>
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

            <div style={{ marginTop: '12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <button type="button" className="btn btn-secondary btn-sm" onClick={handleAddLine}>
                <i className="fa-solid fa-plus"></i> Add Line Item
              </button>
              
              <div style={{ display: 'flex', gap: '20px', fontSize: '0.82rem' }}>
                <div>Taxable: <strong className="mono">₹ {Number(inv.subtotal || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</strong></div>
                <div>GST: <strong className="mono">₹ {Number((inv.cgst || 0) + (inv.sgst || 0)).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</strong></div>
                <div>Grand Total: <strong className="mono" style={{ color: '#059669', fontSize: '0.95rem' }}>₹ {Number(inv.grandTotal || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</strong></div>
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
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: '#ffffff', padding: '16px 20px', borderRadius: 'var(--radius-lg)', border: '1px solid var(--border-card)', boxShadow: 'var(--shadow-sm)' }}>
            <div style={{ display: 'flex', gap: '8px' }}>
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
              <button 
                type="button" 
                className="btn btn-secondary btn-sm"
                onClick={() => onShowToast('Draft edits saved locally.', 'success')}
              >
                <i className="fa-solid fa-floppy-disk"></i> Save Draft
              </button>
            </div>

            <div style={{ display: 'flex', gap: '10px' }}>
              <button 
                type="button" 
                className="btn btn-secondary" 
                onClick={() => onPreviewXml(inv)}
              >
                <i className="fa-solid fa-code"></i> Preview Tally XML
              </button>
              
              <button 
                type="button" 
                className="btn btn-primary" 
                disabled={!canApprove}
                title={!canApprove ? 'Resolve validation issues and map masters before approving' : 'Approve and prepare voucher for posting'}
                onClick={() => onConfirmPost(inv)}
              >
                <i className="fa-solid fa-check-double"></i> Approve & Transmit Voucher
              </button>
            </div>
          </div>

        </div>
      </div>
    </section>
  );
}
