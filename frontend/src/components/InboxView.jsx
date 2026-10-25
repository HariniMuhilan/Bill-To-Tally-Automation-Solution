import React, { useState, useRef } from 'react';
import { uploadInvoiceFile } from '../services/api';

export default function InboxView({ 
  invoices, 
  onReviewInvoice, 
  onAddInvoice, 
  onShowToast 
}) {
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');
  const [isDragOver, setIsDragOver] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const fileInputRef = useRef(null);

  // Compute KPI Counts
  const totalCount = invoices.length;
  const needsReviewCount = invoices.filter(i => i.status === 'NEEDS_REVIEW' || i.status === 'NEEDS_CORRECTION').length;
  const approvedCount = invoices.filter(i => i.status === 'APPROVED').length;
  const postedCount = invoices.filter(i => i.status === 'POSTED').length;
  const failedCount = invoices.filter(i => i.status === 'POST_FAILED' || i.status === 'RECONCILIATION_REQUIRED').length;

  // Filter and search invoices
  const filteredInvoices = invoices.filter(inv => {
    const q = search.toLowerCase().trim();
    const matchesSearch = !q || 
      inv.supplierRaw.toLowerCase().includes(q) ||
      inv.invoiceNo.toLowerCase().includes(q) ||
      inv.id.toLowerCase().includes(q) ||
      inv.sourceFilename.toLowerCase().includes(q);

    if (!matchesSearch) return false;

    if (filter === 'all') return true;
    if (filter === 'needs-review') return inv.status === 'NEEDS_REVIEW' || inv.status === 'NEEDS_CORRECTION';
    if (filter === 'approved') return inv.status === 'APPROVED';
    if (filter === 'posted') return inv.status === 'POSTED';
    if (filter === 'failed') return inv.status === 'POST_FAILED';
    return true;
  });

  async function handleFiles(fileList) {
    if (!fileList || fileList.length === 0) return;
    const files = Array.from(fileList);

    setIsUploading(true);
    onShowToast(`Uploading ${files.length} document(s)... Connecting to FastAPI OCR backend...`, 'warning');

    for (const file of files) {
      // Attempt upload to FastAPI backend
      const res = await uploadInvoiceFile(file);

      if (res.success && res.data) {
        // Backend OCR extraction succeeded
        const ocrData = res.data;
        const ext = ocrData.extracted_data || {};
        
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

        const newInvoice = {
          id: ocrData.id || `INV-${String(invoices.length + 1).padStart(2, '0')}`,
          sourceFilename: ocrData.filename || file.name,
          imageUrl: ocrData.image_url,
          sha256: ocrData.file_hash_sha256,
          supplierRaw: ext.supplier_name || 'Unidentified Supplier',
          supplierMapped: '',
          invoiceNo: ext.invoice_number || '—',
          invoiceDate: ext.invoice_date || '',
          tallyDate: ext.invoice_date ? ext.invoice_date.replace(/-/g, '') : '',
          gstin: ext.supplier_gstin || '',
          type: ext.invoice_mode === 'inventory' ? 'Inventory Purchase' : 'Accounting Purchase',
          subtotal,
          cgst,
          sgst,
          igst,
          grandTotal,
          status: 'NEEDS_REVIEW',
          tallyRef: '—',
          confidence: ext.overall_confidence ? `${Math.round(ext.overall_confidence * 1000) / 10}%` : '—',
          ocrLines: ocrData.ocr_result?.lines || [],
          rawOcrText: ocrData.ocr_result?.raw_text || ext.raw_ocr_text || '',
          warnings: ext.warnings || [],
          lines: lineItems
        };

        onAddInvoice(newInvoice);
        onShowToast(`Scan complete: ${newInvoice.sourceFilename} extracted as ${newInvoice.id}`, 'success');
      } else {
        const errorMsg = res.error || 'Backend OCR scan failed. Ensure backend server is running.';
        onShowToast(`Failed to process ${file.name}: ${errorMsg}`, 'danger');
      }
    }

    setIsUploading(false);
  }

  function getStatusBadge(status) {
    if (status === 'APPROVED') return { cls: 'approved', icon: 'fa-check' };
    if (status === 'POSTED') return { cls: 'posted', icon: 'fa-circle-check' };
    if (status === 'POST_FAILED') return { cls: 'failed', icon: 'fa-triangle-exclamation' };
    if (status === 'NEEDS_CORRECTION') return { cls: 'needs-review', icon: 'fa-pen' };
    return { cls: 'needs-review', icon: 'fa-clock' };
  }

  return (
    <section className="tab-pane active" id="tab-inbox">
      
      {/* KPI Metrics Row */}
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-content">
            <h3>Total Invoices</h3>
            <div className="stat-number">{totalCount}</div>
            <div className="stat-subtext">Registered in workspace</div>
          </div>
          <div className="stat-icon-wrap icon-purple">
            <i className="fa-solid fa-folder-open"></i>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-content">
            <h3>Needs Review</h3>
            <div className="stat-number" style={{ color: 'var(--color-amber-text)' }}>{needsReviewCount}</div>
            <div className="stat-subtext">Requires human verification</div>
          </div>
          <div className="stat-icon-wrap icon-amber">
            <i className="fa-solid fa-user-pen"></i>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-content">
            <h3>Approved (Ready)</h3>
            <div className="stat-number" style={{ color: 'var(--color-azure-text)' }}>{approvedCount}</div>
            <div className="stat-subtext">Awaiting posting trigger</div>
          </div>
          <div className="stat-icon-wrap icon-blue">
            <i className="fa-solid fa-clipboard-check"></i>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-content">
            <h3>Posted to Tally</h3>
            <div className="stat-number" style={{ color: '#059669' }}>{postedCount}</div>
            <div className="stat-subtext">Reconciled in Day Book</div>
          </div>
          <div className="stat-icon-wrap icon-emerald">
            <i className="fa-solid fa-circle-check"></i>
          </div>
        </div>
      </div>

      {/* Drag & Drop Upload Zone */}
      <div 
        className={`upload-dropzone ${isDragOver ? 'dragover' : ''}`}
        id="upload-dropzone-box"
        onClick={() => fileInputRef.current && fileInputRef.current.click()}
        onDragOver={(e) => { e.preventDefault(); setIsDragOver(true); }}
        onDragLeave={() => setIsDragOver(false)}
        onDrop={(e) => {
          e.preventDefault();
          setIsDragOver(false);
          handleFiles(e.dataTransfer.files);
        }}
      >
        <div className="upload-icon">
          {isUploading ? (
            <i className="fa-solid fa-circle-notch fa-spin"></i>
          ) : (
            <i className="fa-solid fa-file-arrow-up"></i>
          )}
        </div>
        <div className="upload-title">
          {isUploading ? 'Connecting to OCR & Processing Invoice...' : 'Drop supplier bills or click to browse'}
        </div>
        <div className="upload-subtitle">
          Supports JPG, PNG, WEBP, PDF &bull; Connected to FastAPI PaddleOCR & Gemini backend
        </div>
        
        <input 
          type="file" 
          ref={fileInputRef} 
          style={{ display: 'none' }} 
          accept=".pdf,.png,.jpg,.jpeg,.webp" 
          multiple
          onChange={(e) => {
            handleFiles(e.target.files);
            e.target.value = '';
          }} 
        />
        
        <button 
          type="button" 
          className="btn btn-secondary btn-sm" 
          style={{ marginTop: '6px' }}
          onClick={(e) => {
            e.stopPropagation();
            fileInputRef.current && fileInputRef.current.click();
          }}
        >
          <i className="fa-solid fa-plus"></i> Select Files
        </button>
      </div>

      {/* Invoices Data Table Card */}
      <div className="glass-card">
        <div className="table-toolbar">
          <div className="filter-pills">
            <button 
              className={`filter-pill ${filter === 'all' ? 'active' : ''}`} 
              onClick={() => setFilter('all')}
            >
              All Invoices ({totalCount})
            </button>
            <button 
              className={`filter-pill ${filter === 'needs-review' ? 'active' : ''}`} 
              onClick={() => setFilter('needs-review')}
            >
              Needs Review ({needsReviewCount})
            </button>
            <button 
              className={`filter-pill ${filter === 'approved' ? 'active' : ''}`} 
              onClick={() => setFilter('approved')}
            >
              Approved ({approvedCount})
            </button>
            <button 
              className={`filter-pill ${filter === 'posted' ? 'active' : ''}`} 
              onClick={() => setFilter('posted')}
            >
              Posted ({postedCount})
            </button>
            <button 
              className={`filter-pill ${filter === 'failed' ? 'active' : ''}`} 
              onClick={() => setFilter('failed')}
            >
              Failed / Alert ({failedCount})
            </button>
          </div>

          <div className="search-input-wrap">
            <i className="fa-solid fa-magnifying-glass search-icon"></i>
            <input 
              type="text" 
              className="form-control" 
              placeholder="Search supplier, invoice #..." 
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </div>

        <div className="table-responsive">
          <table className="data-table">
          <thead>
            <tr>
              <th>Invoice ID</th>
              <th>Source File</th>
              <th>Supplier (Raw / Mapped)</th>
              <th>Invoice No & Date</th>
              <th>Total Amount</th>
              <th>Status</th>
              <th>Tally Ref</th>
              <th style={{ textAlign: 'right' }}>Action</th>
            </tr>
          </thead>
          <tbody>
            {filteredInvoices.length === 0 ? (
              <tr>
                <td colSpan="8" style={{ textAlign: 'center', padding: '48px 16px', color: 'var(--text-muted)' }}>
                  <i className="fa-solid fa-cloud-arrow-up" style={{ fontSize: '2.5rem', marginBottom: '12px', display: 'block', color: 'rgba(255,255,255,0.2)' }}></i>
                  <div style={{ fontWeight: 700, fontSize: '1rem', color: 'var(--text-light)', marginBottom: '6px' }}>
                    {invoices.length === 0 ? 'No Invoices Uploaded Yet' : 'No matching invoices found in this view.'}
                  </div>
                  <div style={{ fontSize: '0.85rem' }}>
                    {invoices.length === 0 
                      ? 'Drop or select a supplier invoice or receipt image above to scan with PaddleOCR and Gemini.'
                      : 'Try clearing the search query or selecting a different status filter.'}
                  </div>
                </td>
              </tr>
            ) : (
              filteredInvoices.map(inv => {
                const badge = getStatusBadge(inv.status);
                return (
                  <tr key={inv.id}>
                    <td><strong className="mono" style={{ color: 'var(--color-azure-text)' }}>{inv.id}</strong></td>
                    <td>
                      <div className="file-name-cell">
                        {/* Bill Image / Document Thumbnail */}
                        <div style={{
                          position: 'relative',
                          width: '42px',
                          height: '42px',
                          borderRadius: '6px',
                          overflow: 'hidden',
                          flexShrink: 0,
                          background: '#1e293b',
                          border: '1px solid var(--border-subtle)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center'
                        }}>
                          {(inv.imageUrl || inv.previewUrl) ? (
                            <img 
                              src={inv.imageUrl || inv.previewUrl} 
                              alt={inv.sourceFilename} 
                              style={{ width: '100%', height: '100%', objectFit: 'cover' }} 
                            />
                          ) : (
                            <i className={`fa-solid ${inv.sourceFilename?.endsWith('.pdf') ? 'fa-file-pdf' : 'fa-file-invoice'}`} style={{ color: 'var(--text-muted)', fontSize: '1.2rem' }}></i>
                          )}
                        </div>

                        <div>
                          <div style={{ fontWeight: 700, color: 'var(--text-primary)' }}>{inv.sourceFilename}</div>
                          <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)', fontFamily: 'var(--font-mono)' }}>
                            Confidence: {inv.confidence}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div style={{ fontWeight: 700, color: 'var(--text-primary)' }}>{inv.supplierRaw}</div>
                      <div style={{ fontSize: '0.74rem', color: inv.supplierMapped ? 'var(--color-azure-text)' : 'var(--color-amber-text)' }}>
                        {inv.supplierMapped ? (
                          <><i className="fa-solid fa-link"></i> {inv.supplierMapped}</>
                        ) : (
                          <><i className="fa-solid fa-triangle-exclamation"></i> Unmapped Supplier</>
                        )}
                      </div>
                    </td>
                    <td>
                      <div className="mono" style={{ fontWeight: 700 }}>{inv.invoiceNo}</div>
                      <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)', fontFamily: 'var(--font-mono)' }}>
                        {inv.invoiceDate}
                      </div>
                    </td>
                    <td>
                      <strong className="mono" style={{ color: 'var(--text-primary)' }}>
                        ₹ {Number(inv.grandTotal || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                      </strong>
                    </td>
                    <td>
                      <span className={`status-badge ${badge.cls}`}>
                        <i className={`fa-solid ${badge.icon}`}></i> {inv.status}
                      </span>
                    </td>
                    <td>
                      <span className="mono" style={{ fontSize: '0.75rem', color: inv.tallyRef?.startsWith('PUR') ? 'var(--color-mint-text)' : 'var(--text-muted)', fontWeight: 600 }}>
                        {inv.tallyRef || '—'}
                      </span>
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <button 
                        className="btn btn-secondary btn-sm" 
                        onClick={() => onReviewInvoice(inv.id)}
                      >
                        <i className="fa-solid fa-eye"></i> Review
                      </button>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
        </div>
      </div>
    </section>
  );
}
