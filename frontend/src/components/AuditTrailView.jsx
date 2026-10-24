import React from 'react';

export default function AuditTrailView({ auditLogs, onShowToast }) {
  return (
    <section className="tab-pane active" id="tab-audit">
      <div className="glass-card" style={{ padding: '24px' }}>
        <div className="card-header-compact" style={{ marginBottom: '20px' }}>
          <span className="card-title">
            <i className="fa-solid fa-timeline"></i> Forensic Audit Trail & Lifecycle History
          </span>
          <button 
            type="button" 
            className="btn btn-secondary btn-sm"
            onClick={() => onShowToast('Audit trail exported as JSON.', 'success')}
          >
            <i className="fa-solid fa-download"></i> Export Audit Log
          </button>
        </div>

        <div className="timeline-container">
          {auditLogs.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '48px 16px', color: 'var(--text-muted)' }}>
              <i className="fa-solid fa-clock-rotate-left" style={{ fontSize: '2.5rem', marginBottom: '12px', display: 'block', color: 'rgba(255,255,255,0.2)' }}></i>
              <div style={{ fontWeight: 700, fontSize: '1rem', color: 'var(--text-light)', marginBottom: '4px' }}>No Audit Events Yet</div>
              <div style={{ fontSize: '0.85rem' }}>Actions such as document uploads, mappings, and voucher postings will be logged here.</div>
            </div>
          ) : (
            auditLogs.map((entry, index) => (
              <div className="timeline-item" key={index} style={{ display: 'flex', gap: '16px', marginBottom: '20px', borderLeft: '2px solid var(--border-subtle)', paddingLeft: '16px', position: 'relative' }}>
                <div style={{ position: 'absolute', left: '-7px', top: '2px', width: '12px', height: '12px', borderRadius: '50%', background: 'var(--palette-azure)' }}></div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
                    <strong style={{ fontSize: '0.85rem', color: 'var(--text-primary)' }}>{entry.action}</strong>
                    <span className="mono" style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>{entry.time}</span>
                  </div>
                  <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginBottom: '6px' }}>{entry.summary}</div>
                  <div style={{ fontSize: '0.72rem', color: 'var(--color-azure-text)', fontWeight: 600 }}>
                    Actor: <span className="mono">{entry.actor}</span>
                  </div>
                  {entry.diff && (
                    <pre style={{ background: 'var(--bg-surface)', padding: '8px 12px', borderRadius: '6px', fontSize: '0.72rem', marginTop: '6px', fontFamily: 'var(--font-mono)' }}>
                      {JSON.stringify(entry.diff, null, 2)}
                    </pre>
                  )}
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </section>
  );
}
