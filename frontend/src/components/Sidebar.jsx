import React from 'react';

export default function Sidebar({ activeTab, onSelectTab, invoiceCounts, tallyConnected, tallyCompany }) {
  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <div className="brand-logo">
          <i className="fa-solid fa-receipt"></i>
        </div>
        <div className="brand-text">
          <h1>BILL TO TALLY</h1>
          <span>Ashan Tech Labs</span>
        </div>
      </div>

      <nav className="sidebar-nav">
        <div className="nav-section-title">Invoices & Processing</div>
        
        <a 
          className={`nav-item ${activeTab === 'inbox' ? 'active' : ''}`}
          onClick={() => onSelectTab('inbox')}
        >
          <span className="nav-icon"><i className="fa-solid fa-inbox"></i></span>
          <span>Invoice Inbox</span>
          <span className="nav-badge" id="badge-inbox">{invoiceCounts.total}</span>
        </a>

        <a 
          className={`nav-item ${activeTab === 'review' ? 'active' : ''}`}
          onClick={() => onSelectTab('review')}
        >
          <span className="nav-icon"><i className="fa-solid fa-magnifying-glass-chart"></i></span>
          <span>Review & Validate</span>
          {invoiceCounts.needsReview > 0 && (
            <span className="nav-badge warning" id="badge-review">{invoiceCounts.needsReview}</span>
          )}
        </a>

        <div className="nav-section-title">Accounting & Masters</div>
        
        <a 
          className={`nav-item ${activeTab === 'mappings' ? 'active' : ''}`}
          onClick={() => onSelectTab('mappings')}
        >
          <span className="nav-icon"><i className="fa-solid fa-diagram-project"></i></span>
          <span>Master Mappings</span>
        </a>

        <a 
          className={`nav-item ${activeTab === 'tally' ? 'active' : ''}`}
          onClick={() => onSelectTab('tally')}
        >
          <span className="nav-icon"><i className="fa-solid fa-server"></i></span>
          <span>Tally Connector</span>
        </a>

        <div className="nav-section-title">Governance & Config</div>
        
        <a 
          className={`nav-item ${activeTab === 'audit' ? 'active' : ''}`}
          onClick={() => onSelectTab('audit')}
        >
          <span className="nav-icon"><i className="fa-solid fa-clock-rotate-left"></i></span>
          <span>Audit Trail</span>
        </a>

        <a 
          className={`nav-item ${activeTab === 'settings' ? 'active' : ''}`}
          onClick={() => onSelectTab('settings')}
        >
          <span className="nav-icon"><i className="fa-solid fa-sliders"></i></span>
          <span>Settings & Safety</span>
        </a>
      </nav>

      <div className="sidebar-footer">
        <div className="tally-status-card">
          <div className="tally-header-row">
            <span className="tally-title">TallyPrime Link</span>
            <div className="tally-indicator">
              <span className={`status-dot ${tallyConnected ? 'online' : ''}`}></span>
              <span style={{ color: tallyConnected ? 'var(--color-mint-text)' : 'var(--color-amber-text)', fontWeight: 800 }}>
                {tallyConnected ? 'ONLINE' : 'SANDBOX'}
              </span>
            </div>
          </div>
          <div className="tally-company-badge" title={tallyCompany || 'ASHAN TEST LABS PVT LTD'}>
            <i className="fa-solid fa-building" style={{ fontSize: '0.7rem', color: 'var(--color-azure-text)', marginRight: '4px' }}></i>
            <span>{tallyCompany || 'ASHAN TEST LABS PVT LTD'}</span>
          </div>
          <div className="tally-meta">
            <span>Port: 9000 &bull; XML HTTP</span>
          </div>
        </div>
      </div>
    </aside>
  );
}
