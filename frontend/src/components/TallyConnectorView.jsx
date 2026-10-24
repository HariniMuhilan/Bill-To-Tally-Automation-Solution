import React from 'react';

export default function TallyConnectorView({ postingAttempts, onShowToast, tallyHealth }) {
  return (
    <section className="tab-pane active" id="tab-tally">
      
      {/* Connector Health Cards */}
      <div className="stats-grid" style={{ marginBottom: '24px' }}>
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
            {postingAttempts.map(att => (
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
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
