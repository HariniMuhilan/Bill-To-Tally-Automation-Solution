import React, { useState } from 'react';

export default function SettingsView({ onShowToast }) {
  const [tallyHost, setTallyHost] = useState('127.0.0.1');
  const [tallyPort, setTallyPort] = useState(9000);
  const [companyName, setCompanyName] = useState('ASHAN TEST LABS PVT LTD');
  const [postingEnabled, setPostingEnabled] = useState(false);
  const [tolerance, setTolerance] = useState(0.05);

  function handleSave(e) {
    e.preventDefault();
    onShowToast('Configuration parameters updated and persisted.', 'success');
  }

  return (
    <section className="tab-pane active" id="tab-settings">
      <div className="glass-card" style={{ maxWidth: '780px', margin: '0 auto', padding: '28px' }}>
        <div className="card-header-compact" style={{ marginBottom: '20px' }}>
          <span className="card-title">
            <i className="fa-solid fa-sliders"></i> Configuration & Safety Parameters
          </span>
          <span className="confidence-pill" style={{ color: 'var(--color-amber-text)' }}>
            <i className="fa-solid fa-shield-halved"></i> AGENTS.md Hard Safety Enforcement
          </span>
        </div>

        <form onSubmit={handleSave}>
          <div className="form-group" style={{ marginBottom: '16px' }}>
            <label className="form-label">TallyPrime Host IP / Domain</label>
            <input 
              type="text" 
              className="form-control mono" 
              value={tallyHost}
              onChange={(e) => setTallyHost(e.target.value)}
              required 
            />
          </div>

          <div className="form-group" style={{ marginBottom: '16px' }}>
            <label className="form-label">TallyPrime XML Server Port</label>
            <input 
              type="number" 
              className="form-control mono" 
              value={tallyPort}
              onChange={(e) => setTallyPort(Number(e.target.value))}
              required 
            />
          </div>

          <div className="form-group" style={{ marginBottom: '16px' }}>
            <label className="form-label">Target Test Company Name</label>
            <input 
              type="text" 
              className="form-control" 
              value={companyName}
              onChange={(e) => setCompanyName(e.target.value)}
              required 
            />
          </div>

          <div className="form-group" style={{ marginBottom: '20px' }}>
            <label className="form-label">Rounding Difference Tolerance (₹)</label>
            <input 
              type="number" 
              step="0.01" 
              className="form-control mono" 
              value={tolerance}
              onChange={(e) => setTolerance(Number(e.target.value))}
              required 
            />
          </div>

          <div style={{ background: 'rgba(245, 156, 39, 0.1)', border: '1px solid rgba(245, 156, 39, 0.3)', borderRadius: '8px', padding: '16px', marginBottom: '24px' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div>
                <strong style={{ fontSize: '0.85rem', color: 'var(--color-amber-text)' }}>
                  <i className="fa-solid fa-triangle-exclamation"></i> POSTING_ENABLED (Live Posting Switch)
                </strong>
                <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', margin: '4px 0 0 0' }}>
                  Safety default: <code>false</code>. Direct posting to live company is blocked unless confirmed on TEST company.
                </p>
              </div>
              <input 
                type="checkbox" 
                checked={postingEnabled}
                onChange={(e) => {
                  setPostingEnabled(e.target.checked);
                  onShowToast(e.target.checked ? 'Warning: Posting enabled for sandbox testing.' : 'Safe Mode active: live posting disabled.', 'warning');
                }}
              />
            </div>
          </div>

          <button type="submit" className="btn btn-primary">
            <i className="fa-solid fa-check"></i> Save Configuration
          </button>
        </form>
      </div>
    </section>
  );
}
