import React from 'react';

export default function TallyConnectorView({ 
  draftSheets = [],
  onDownloadDraft,
  onDownloadAllDrafts,
  onDeleteDraft
}) {
  return (
    <section className="tab-pane active" id="tab-tally">
      {/* Draft Excel Sheets Registry */}
      <div className="glass-card" style={{ marginBottom: '24px' }}>
        <div className="table-toolbar" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <span className="card-title" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <i className="fa-solid fa-file-excel" style={{ color: '#10b981' }}></i>
              <span>Tally Excel Draft Sheets & Workbooks</span>
              <span className="badge" style={{ background: 'rgba(16, 185, 129, 0.15)', color: '#059669', fontSize: '0.72rem', padding: '2px 8px', borderRadius: '12px' }}>
                {draftSheets.length} Saved
              </span>
            </span>
            <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)', marginTop: '4px' }}>
              Draft purchase vouchers saved from the review dashboard. Formatted for direct TallyPrime Excel ledger import.
            </div>
          </div>

          <div style={{ display: 'flex', gap: '8px' }}>
            {draftSheets.length > 0 && (
              <button 
                type="button" 
                className="btn btn-orange btn-sm"
                onClick={() => onDownloadAllDrafts && onDownloadAllDrafts()}
              >
                <i className="fa-solid fa-cloud-arrow-down"></i> Download All Master (.xlsx)
              </button>
            )}
          </div>
        </div>

        <div className="table-responsive">
          <table className="data-table">
          <thead>
            <tr>
              <th>Excel Sheet / File Name</th>
              <th>Vouchers Contained</th>
              <th>Party / Supplier Ledgers</th>
              <th>Total Items</th>
              <th>Consolidated Total (₹)</th>
              <th>Last Saved / Updated</th>
              <th style={{ textAlign: 'right' }}>Download / Actions</th>
            </tr>
          </thead>
          <tbody>
            {draftSheets.length === 0 ? (
              <tr>
                <td colSpan="7" style={{ textAlign: 'center', padding: '40px 16px', color: 'var(--text-muted)' }}>
                  <i className="fa-solid fa-file-excel" style={{ fontSize: '2.4rem', marginBottom: '10px', display: 'block', color: 'rgba(16, 185, 129, 0.3)' }}></i>
                  <div style={{ fontWeight: 600, color: 'var(--text-light)', marginBottom: '4px', fontSize: '0.95rem' }}>
                    No Draft Excel Sheets Stored Yet
                  </div>
                  <div style={{ fontSize: '0.82rem', maxWidth: '520px', margin: '0 auto', lineHeight: 1.5 }}>
                    When you click <strong>"Save Draft"</strong> in Review & Validate, you can choose to store into a new or existing Excel sheet. Stored sheets can be downloaded here anytime as <code>.xlsx</code> files.
                  </div>
                </td>
              </tr>
            ) : (
              draftSheets.map(draft => {
                const invs = draft.invoices && draft.invoices.length > 0 
                  ? draft.invoices 
                  : (draft.invoice ? [draft.invoice] : []);
                const voucherCount = invs.length;
                const totalLineCount = invs.reduce((acc, i) => acc + (i.lines || []).length, 0);
                const totalAmt = invs.reduce((acc, i) => acc + Number(i.grandTotal || 0), 0);
                const suppliers = Array.from(new Set(invs.map(i => i.supplierMapped || i.supplierRaw || 'Supplier'))).join(', ');
                const invoiceNos = invs.map(i => i.invoiceNo || i.id).join(', ');

                return (
                  <tr key={draft.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <i className="fa-solid fa-file-excel" style={{ color: '#10b981', fontSize: '1.2rem' }}></i>
                        <div>
                          <strong className="mono" style={{ color: 'var(--text-primary)', fontSize: '0.85rem' }}>
                            {draft.fileName}
                          </strong>
                          <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Sheet ID: {draft.id}</div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '2px' }}>
                        <span className="badge" style={{ background: 'rgba(16, 185, 129, 0.12)', color: '#059669', padding: '2px 8px', borderRadius: '4px', fontWeight: 700, width: 'fit-content' }}>
                          {voucherCount} {voucherCount === 1 ? 'Voucher' : 'Vouchers'}
                        </span>
                        <span className="mono" style={{ fontSize: '0.73rem', color: 'var(--text-muted)' }} title={invoiceNos}>
                          {invoiceNos.length > 25 ? invoiceNos.substring(0, 25) + '...' : invoiceNos}
                        </span>
                      </div>
                    </td>
                    <td>
                      <span style={{ fontWeight: 600, color: 'var(--text-light)', fontSize: '0.82rem' }} title={suppliers}>
                        {suppliers.length > 30 ? suppliers.substring(0, 30) + '...' : suppliers}
                      </span>
                    </td>
                    <td>
                      <span className="badge" style={{ background: 'var(--bg-card)', padding: '2px 8px', borderRadius: '4px', border: '1px solid var(--border-subtle)' }}>
                        {totalLineCount} {totalLineCount === 1 ? 'item' : 'items'}
                      </span>
                    </td>
                    <td>
                      <strong className="mono" style={{ color: '#059669', fontSize: '0.92rem' }}>
                        ₹ {Number(totalAmt || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                      </strong>
                    </td>
                    <td>
                      <span className="mono" style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
                        {draft.updatedAt || draft.savedAt}
                      </span>
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div style={{ display: 'flex', gap: '6px', justifyContent: 'flex-end' }}>
                        <button 
                          type="button" 
                          className="btn btn-secondary btn-sm"
                          style={{ color: 'var(--color-success-green)', borderColor: 'var(--color-success-green)', background: 'rgba(22, 121, 75, 0.08)' }}
                          title="Download Excel (.xlsx) file"
                          onClick={() => onDownloadDraft && onDownloadDraft(draft)}
                        >
                          <i className="fa-solid fa-download"></i> Download .xlsx
                        </button>
                        <button 
                          type="button" 
                          className="btn btn-secondary btn-icon"
                          style={{ width: '28px', height: '28px', color: '#ef4444' }}
                          title="Delete draft sheet"
                          onClick={() => onDeleteDraft && onDeleteDraft(draft.id)}
                        >
                          <i className="fa-solid fa-trash-can" style={{ fontSize: '0.75rem' }}></i>
                        </button>
                      </div>
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
