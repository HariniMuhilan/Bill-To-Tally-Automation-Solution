import React from 'react';

export function XmlModal({ isOpen, onClose, xmlContent, onShowToast }) {
  if (!isOpen) return null;

  function copyXml() {
    navigator.clipboard.writeText(xmlContent);
    onShowToast('Tally XML copied to clipboard!', 'success');
  }

  return (
    <div className="modal-overlay open">
      <div className="modal-card">
        <div className="modal-header">
          <span className="card-title">
            <i className="fa-solid fa-code"></i>
            <span>Generated TallyPrime XML Voucher Payload</span>
          </span>
          <button type="button" className="btn btn-secondary btn-icon" onClick={onClose}>
            <i className="fa-solid fa-xmark"></i>
          </button>
        </div>
        <div className="modal-body">
          <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)', marginBottom: '12px' }}>
            The exact XML payload generated for transmission to <code>http://127.0.0.1:9000</code>. Validated against the TallyPrime Purchase Voucher DTD.
          </p>
          <pre className="xml-code-view">{xmlContent}</pre>
        </div>
        <div className="modal-footer">
          <button type="button" className="btn btn-secondary btn-sm" onClick={copyXml}>
            <i className="fa-solid fa-copy"></i> Copy XML
          </button>
          <button type="button" className="btn btn-primary btn-sm" onClick={onClose}>
            Close
          </button>
        </div>
      </div>
    </div>
  );
}

export function ConfirmPostModal({ isOpen, onClose, invoice, onConfirm }) {
  if (!isOpen || !invoice) return null;

  const supplier = invoice.supplierMapped || invoice.supplierRaw;
  const dateStr = invoice.tallyDate || (invoice.invoiceDate ? invoice.invoiceDate.replace(/-/g, '') : '20261018');
  const idempotencyKey = `ATL_TEST:${(supplier || 'SUPPLIER').replace(/[^a-zA-Z0-9]/g, '_').toUpperCase()}:${invoice.invoiceNo}:${dateStr}`;

  return (
    <div className="modal-overlay open">
      <div className="modal-card" style={{ maxWidth: '520px' }}>
        <div className="modal-header">
          <span className="card-title" style={{ color: 'var(--color-amber-text)' }}>
            <i className="fa-solid fa-triangle-exclamation"></i>
            <span>Confirm TallyPrime Voucher Posting</span>
          </span>
          <button type="button" className="btn btn-secondary btn-icon" onClick={onClose}>
            <i className="fa-solid fa-xmark"></i>
          </button>
        </div>
        <div className="modal-body">
          <p style={{ marginBottom: '14px' }}>
            You are about to post an approved purchase voucher to <strong>ASHAN TEST LABS PVT LTD</strong> in TallyPrime:
          </p>
          <div style={{ background: 'var(--bg-surface)', padding: '14px', borderRadius: 'var(--radius-sm)', fontSize: '0.8rem', display: 'flex', flexDirection: 'column', gap: '8px', border: '1px solid var(--border-subtle)' }}>
            <div><strong>Supplier:</strong> <span>{supplier}</span></div>
            <div><strong>Invoice No:</strong> <span className="mono">{invoice.invoiceNo}</span></div>
            <div><strong>Voucher Date:</strong> <span className="mono">{dateStr}</span></div>
            <div><strong>Grand Total:</strong> <span className="mono" style={{ color: '#059669', fontWeight: 700 }}>₹ {Number(invoice.grandTotal || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</span></div>
            <div><strong>Idempotency Key:</strong> <span className="mono" style={{ fontSize: '0.72rem', color: 'var(--color-azure-text)' }}>{idempotencyKey}</span></div>
          </div>
          <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '12px' }}>
            <i className="fa-solid fa-shield-halved" style={{ color: '#10b981' }}></i> Idempotency protection is active. Duplicate entries will be rejected automatically.
          </p>
        </div>
        <div className="modal-footer">
          <button type="button" className="btn btn-secondary" onClick={onClose}>Cancel</button>
          <button 
            type="button" 
            className="btn btn-success" 
            onClick={() => onConfirm(invoice, idempotencyKey)}
          >
            <i className="fa-solid fa-check"></i> Confirm & Transmit to Tally
          </button>
        </div>
      </div>
    </div>
  );
}
