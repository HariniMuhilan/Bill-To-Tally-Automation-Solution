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

export function SaveDraftModal({ isOpen, onClose, invoice, existingSheets = [], onConfirm }) {
  if (!isOpen || !invoice) return null;

  const [mode, setMode] = React.useState(existingSheets.length > 0 ? 'existing' : 'new');
  const [selectedSheetId, setSelectedSheetId] = React.useState(existingSheets[0]?.id || '');
  const [newSheetName, setNewSheetName] = React.useState(() => {
    const rawNo = invoice.invoiceNo && invoice.invoiceNo !== '—' ? invoice.invoiceNo : invoice.id;
    const rawSupp = invoice.supplierMapped || invoice.supplierRaw || 'Supplier';
    return `Tally_Purchase_${rawNo}_${rawSupp}`.replace(/[^a-zA-Z0-9_-]/g, '_') + '.xlsx';
  });

  const selectedSheet = existingSheets.find(s => s.id === selectedSheetId);

  function handleSave(e) {
    if (e) e.preventDefault();
    if (mode === 'new') {
      const trimmed = newSheetName.trim();
      const finalName = trimmed.endsWith('.xlsx') ? trimmed : `${trimmed}.xlsx`;
      onConfirm({
        mode: 'new',
        sheetName: finalName,
        invoice
      });
    } else {
      if (!selectedSheetId) return;
      onConfirm({
        mode: 'existing',
        targetSheetId: selectedSheetId,
        invoice
      });
    }
  }

  return (
    <div className="modal-overlay open">
      <div className="modal-card" style={{ maxWidth: '540px' }}>
        <div className="modal-header">
          <span className="card-title" style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#10b981' }}>
            <i className="fa-solid fa-file-excel"></i>
            <span>Save Draft to Tally Connector Excel Sheet</span>
          </span>
          <button type="button" className="btn btn-secondary btn-icon" onClick={onClose}>
            <i className="fa-solid fa-xmark"></i>
          </button>
        </div>

        <form onSubmit={handleSave}>
          <div className="modal-body">
            <p style={{ fontSize: '0.82rem', color: 'var(--text-secondary)', marginBottom: '16px', lineHeight: 1.5 }}>
              Choose whether to store this draft voucher in a <strong>new Excel sheet</strong> or append it into an <strong>existing Excel sheet</strong> in the Tally Connector registry.
            </p>

            {/* Invoice Quick Summary Card */}
            <div style={{ background: 'var(--bg-surface)', padding: '12px 14px', borderRadius: 'var(--radius-sm)', fontSize: '0.8rem', marginBottom: '18px', border: '1px solid var(--border-subtle)', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
              <div><strong style={{ color: 'var(--text-muted)' }}>Invoice ID:</strong> <span className="mono">{invoice.id}</span></div>
              <div><strong style={{ color: 'var(--text-muted)' }}>Voucher No:</strong> <span className="mono">{invoice.invoiceNo || '—'}</span></div>
              <div style={{ gridColumn: 'span 2' }}><strong style={{ color: 'var(--text-muted)' }}>Supplier:</strong> <span>{invoice.supplierMapped || invoice.supplierRaw || '—'}</span></div>
              <div><strong style={{ color: 'var(--text-muted)' }}>Line Items:</strong> <span>{(invoice.lines || []).length} items</span></div>
              <div><strong style={{ color: 'var(--text-muted)' }}>Grand Total:</strong> <strong className="mono" style={{ color: '#059669' }}>₹ {Number(invoice.grandTotal || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</strong></div>
            </div>

            {/* Destination Options */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginBottom: '14px' }}>
              
              {/* Option 1: New Sheet */}
              <label style={{ 
                display: 'block', 
                padding: '14px', 
                borderRadius: 'var(--radius-sm)', 
                border: mode === 'new' ? '2px solid #10b981' : '1px solid var(--border-card)', 
                background: mode === 'new' ? 'rgba(16, 185, 129, 0.05)' : 'var(--bg-surface)',
                cursor: 'pointer',
                transition: 'all 0.15s ease'
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: mode === 'new' ? '10px' : '0' }}>
                  <input 
                    type="radio" 
                    name="draftSheetMode" 
                    value="new" 
                    checked={mode === 'new'} 
                    onChange={() => setMode('new')} 
                    style={{ accentColor: '#10b981' }}
                  />
                  <div style={{ fontWeight: 700, fontSize: '0.88rem', color: mode === 'new' ? '#059669' : 'var(--text-primary)' }}>
                    <i className="fa-solid fa-file-circle-plus" style={{ marginRight: '6px' }}></i> Store in a New Excel Sheet
                  </div>
                </div>

                {mode === 'new' && (
                  <div style={{ marginTop: '8px', paddingLeft: '24px' }}>
                    <label className="form-label" style={{ fontSize: '0.74rem', marginBottom: '4px' }}>Excel Sheet File Name:</label>
                    <input 
                      type="text" 
                      className="form-control" 
                      style={{ fontSize: '0.82rem' }}
                      value={newSheetName} 
                      onChange={(e) => setNewSheetName(e.target.value)} 
                      placeholder="e.g. Tally_Purchase_March_2025.xlsx"
                      required
                    />
                  </div>
                )}
              </label>

              {/* Option 2: Append to Existing Sheet */}
              <label style={{ 
                display: 'block', 
                padding: '14px', 
                borderRadius: 'var(--radius-sm)', 
                border: mode === 'existing' ? '2px solid #10b981' : '1px solid var(--border-card)', 
                background: mode === 'existing' ? 'rgba(16, 185, 129, 0.05)' : 'var(--bg-surface)',
                opacity: existingSheets.length === 0 ? 0.6 : 1,
                cursor: existingSheets.length === 0 ? 'not-allowed' : 'pointer',
                transition: 'all 0.15s ease'
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: (mode === 'existing' && existingSheets.length > 0) ? '10px' : '0' }}>
                  <input 
                    type="radio" 
                    name="draftSheetMode" 
                    value="existing" 
                    disabled={existingSheets.length === 0}
                    checked={mode === 'existing'} 
                    onChange={() => setMode('existing')} 
                    style={{ accentColor: '#10b981' }}
                  />
                  <div>
                    <div style={{ fontWeight: 700, fontSize: '0.88rem', color: (mode === 'existing' && existingSheets.length > 0) ? '#059669' : 'var(--text-primary)' }}>
                      <i className="fa-solid fa-folder-plus" style={{ marginRight: '6px' }}></i> Store in an Existing Excel Sheet
                    </div>
                    {existingSheets.length === 0 && (
                      <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)', marginTop: '2px' }}>
                        (No existing Excel sheets in Tally Connector yet. Create a new sheet first.)
                      </div>
                    )}
                  </div>
                </div>

                {mode === 'existing' && existingSheets.length > 0 && (
                  <div style={{ marginTop: '8px', paddingLeft: '24px' }}>
                    <label className="form-label" style={{ fontSize: '0.74rem', marginBottom: '4px' }}>Select Target Excel Sheet:</label>
                    <select 
                      className="form-control"
                      value={selectedSheetId}
                      onChange={(e) => setSelectedSheetId(e.target.value)}
                      style={{ fontSize: '0.82rem' }}
                    >
                      {existingSheets.map(s => {
                        const invCount = (s.invoices?.length) || (s.invoice ? 1 : 0);
                        return (
                          <option key={s.id} value={s.id}>
                            {s.fileName} ({invCount} {invCount === 1 ? 'voucher' : 'vouchers'}, ₹{Number(s.totalAmount || 0).toLocaleString('en-IN')})
                          </option>
                        );
                      })}
                    </select>

                    {selectedSheet && (
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '6px' }}>
                        This invoice will be appended as a new voucher inside <strong>{selectedSheet.fileName}</strong>.
                      </div>
                    )}
                  </div>
                )}
              </label>

            </div>

            <div style={{ background: 'rgba(2, 132, 199, 0.08)', border: '1px solid rgba(2, 132, 199, 0.25)', borderRadius: '6px', padding: '10px 12px', fontSize: '0.76rem', color: 'var(--text-muted)', display: 'flex', gap: '8px', alignItems: 'center' }}>
              <i className="fa-solid fa-circle-info" style={{ color: 'var(--palette-azure)', fontSize: '1rem' }}></i>
              <span>The draft will be stored inside Tally Connector. You can download the <code>.xlsx</code> file anytime from the <strong>Tally Connector</strong> tab.</span>
            </div>
          </div>

          <div className="modal-footer">
            <button type="button" className="btn btn-secondary" onClick={onClose}>Cancel</button>
            <button 
              type="submit" 
              className="btn btn-primary"
              style={{ background: '#10b981', borderColor: '#059669' }}
            >
              <i className="fa-solid fa-file-excel"></i> Save to Tally Connector
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

