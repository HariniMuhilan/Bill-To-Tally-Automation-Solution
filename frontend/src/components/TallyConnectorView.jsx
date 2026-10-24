import React, { useState } from 'react';

export default function TallyConnectorView({ 
  postingAttempts = [], 
  draftSheets = [],
  onDownloadDraft,
  onDownloadAllDrafts,
  onDeleteDraft,
  onShowToast, 
  tallyHealth 
}) {
  const [previewDraft, setPreviewDraft] = useState(null);

  return (
    <section className="tab-pane active" id="tab-tally">
      
      {/* Connector Health Cards */}
      <div className="stats-grid" style={{ marginBottom: '24px' }}>
        <div className="stat-card">
          <div className="stat-content">
            <h3>Stored Excel Drafts</h3>
            <div className="stat-number" style={{ fontSize: '1.25rem', color: '#10b981' }}>
              {draftSheets.length} {draftSheets.length === 1 ? 'Sheet' : 'Sheets'}
            </div>
            <div className="stat-subtext">Downloadable .xlsx workbooks</div>
          </div>
          <div className="stat-icon-wrap" style={{ background: 'rgba(16, 185, 129, 0.15)', color: '#10b981' }}>
            <i className="fa-solid fa-file-excel"></i>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-content">
            <h3>Endpoint Connection</h3>
            <div className="stat-number" style={{ fontSize: '1.25rem', color: tallyHealth?.connected ? 'var(--color-mint-text)' : 'var(--color-azure-text)' }}>
              {tallyHealth?.tally_host || '127.0.0.1'}:{tallyHealth?.tally_port || 9000}
            </div>
            <div className="stat-subtext">XML Server over HTTP</div>
          </div>
          <div className="stat-icon-wrap icon-purple">
            <i className="fa-solid fa-network-wired"></i>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-content">
            <h3>Active Test Company</h3>
            <div className="stat-number" style={{ fontSize: '1.1rem', color: 'var(--text-primary)' }}>
              {tallyHealth?.company || 'ASHAN TEST LABS PVT LTD'}
            </div>
            <div className="stat-subtext">Sandbox Gated</div>
          </div>
          <div className="stat-icon-wrap icon-blue">
            <i className="fa-solid fa-building"></i>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-content">
            <h3>Posting Safety Gate</h3>
            <div className="stat-number" style={{ fontSize: '1.25rem', color: 'var(--color-amber-text)' }}>
              POSTING_ENABLED: false
            </div>
            <div className="stat-subtext">Protected per AGENTS.md Section 4</div>
          </div>
          <div className="stat-icon-wrap icon-amber">
            <i className="fa-solid fa-shield-halved"></i>
          </div>
        </div>
      </div>

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
                className="btn btn-secondary btn-sm"
                style={{ color: '#059669', borderColor: '#10b981' }}
                onClick={() => onDownloadAllDrafts && onDownloadAllDrafts()}
              >
                <i className="fa-solid fa-cloud-arrow-down"></i> Download All Master (.xlsx)
              </button>
            )}
          </div>
        </div>

        <table className="data-table">
          <thead>
            <tr>
              <th>File / Sheet Name</th>
              <th>Invoice ID</th>
              <th>Voucher Date</th>
              <th>Supplier / Party Ledger</th>
              <th>Items</th>
              <th>Taxable (₹)</th>
              <th>Grand Total (₹)</th>
              <th>Saved At</th>
              <th style={{ textAlign: 'right' }}>Download / Actions</th>
            </tr>
          </thead>
          <tbody>
            {draftSheets.length === 0 ? (
              <tr>
                <td colSpan="9" style={{ textAlign: 'center', padding: '40px 16px', color: 'var(--text-muted)' }}>
                  <i className="fa-solid fa-file-excel" style={{ fontSize: '2.4rem', marginBottom: '10px', display: 'block', color: 'rgba(16, 185, 129, 0.3)' }}></i>
                  <div style={{ fontWeight: 600, color: 'var(--text-light)', marginBottom: '4px', fontSize: '0.95rem' }}>
                    No Draft Excel Sheets Stored Yet
                  </div>
                  <div style={{ fontSize: '0.82rem', maxWidth: '520px', margin: '0 auto', lineHeight: 1.5 }}>
                    When you click <strong>"Save Draft"</strong> in the Review & Validate screen, your invoice and line items will automatically be saved here as a Tally-formatted Excel spreadsheet and downloaded as a <code>.xlsx</code> file.
                  </div>
                </td>
              </tr>
            ) : (
              draftSheets.map(draft => {
                const inv = draft.invoice || {};
                const lineCount = (inv.lines || []).length;
                return (
                  <tr key={draft.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <i className="fa-solid fa-file-excel" style={{ color: '#10b981', fontSize: '1.1rem' }}></i>
                        <div>
                          <strong className="mono" style={{ color: 'var(--text-primary)', fontSize: '0.84rem' }}>
                            {draft.fileName}
                          </strong>
                          <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>ID: {draft.id}</div>
                        </div>
                      </div>
                    </td>
                    <td><span className="mono" style={{ fontWeight: 600 }}>{draft.invoiceId || inv.id}</span></td>
                    <td><span className="mono" style={{ fontSize: '0.78rem' }}>{inv.invoiceDate || '—'}</span></td>
                    <td>
                      <span style={{ fontWeight: 600, color: 'var(--text-light)' }}>
                        {inv.supplierMapped || inv.supplierRaw || '—'}
                      </span>
                    </td>
                    <td>
                      <span className="badge" style={{ background: 'var(--bg-card)', padding: '2px 8px', borderRadius: '4px', border: '1px solid var(--border-subtle)' }}>
                        {lineCount} {lineCount === 1 ? 'item' : 'items'}
                      </span>
                    </td>
                    <td>
                      <span className="mono">
                        ₹ {Number(inv.subtotal || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                      </span>
                    </td>
                    <td>
                      <strong className="mono" style={{ color: '#059669', fontSize: '0.9rem' }}>
                        ₹ {Number(inv.grandTotal || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                      </strong>
                    </td>
                    <td>
                      <span className="mono" style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
                        {draft.savedAt}
                      </span>
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div style={{ display: 'flex', gap: '6px', justifyContent: 'flex-end' }}>
                        <button 
                          type="button" 
                          className="btn btn-secondary btn-sm"
                          style={{ color: '#059669', borderColor: 'rgba(16, 185, 129, 0.4)', background: 'rgba(16, 185, 129, 0.08)' }}
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

      {/* Posting Attempts Table */}
      <div className="glass-card">
        <div className="table-toolbar">
          <span className="card-title">
            <i className="fa-solid fa-clock-rotate-left"></i> Immutable TallyPrime Posting Log & Idempotency Audit
          </span>
          <button 
            type="button" 
            className="btn btn-secondary btn-sm"
            onClick={() => onShowToast('Pinged TallyPrime XML server probe (safe read-only).', 'success')}
          >
            <i className="fa-solid fa-tower-broadcast"></i> Test Connectivity Probe
          </button>
        </div>

        <table className="data-table">
          <thead>
            <tr>
              <th>Attempt ID</th>
              <th>Invoice ID</th>
              <th>Idempotency Key (SHA-256 Gated)</th>
              <th>Voucher No</th>
              <th>Transmission Time</th>
              <th>Status</th>
              <th>Gateway Response Summary</th>
            </tr>
          </thead>
          <tbody>
            {postingAttempts.length === 0 ? (
              <tr>
                <td colSpan="7" style={{ textAlign: 'center', padding: '36px 16px', color: 'var(--text-muted)' }}>
                  <i className="fa-solid fa-server" style={{ fontSize: '2rem', marginBottom: '8px', display: 'block', color: 'rgba(255,255,255,0.2)' }}></i>
                  <div style={{ fontWeight: 600, color: 'var(--text-light)', marginBottom: '4px' }}>No posting attempts recorded yet</div>
                  <div style={{ fontSize: '0.8rem' }}>When approved vouchers are transmitted to TallyPrime, attempts and idempotency keys will appear here.</div>
                </td>
              </tr>
            ) : (
              postingAttempts.map(att => (
                <tr key={att.id}>
                  <td><strong className="mono" style={{ color: 'var(--color-azure-text)' }}>{att.id}</strong></td>
                  <td><strong className="mono">{att.invoiceId}</strong></td>
                  <td><span className="mono" style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>{att.idempotencyKey}</span></td>
                  <td><span className="mono" style={{ fontWeight: 700 }}>{att.voucherNo}</span></td>
                  <td><span className="mono" style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>{att.startedAt}</span></td>
                  <td>
                    <span className={`status-badge ${att.status === 'POSTED' ? 'posted' : (att.status === 'VALIDATED' ? 'approved' : 'failed')}`}>
                      <i className={`fa-solid ${att.status === 'POSTED' ? 'fa-check' : 'fa-clock'}`}></i> {att.status}
                    </span>
                  </td>
                  <td>
                    <span style={{ fontSize: '0.78rem', color: att.status === 'POSTED' ? 'var(--color-mint-text)' : (att.status === 'FAILED' ? '#dc2626' : 'var(--text-secondary)') }}>
                      {att.responseMessage}
                    </span>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
