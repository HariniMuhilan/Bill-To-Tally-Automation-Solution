import React from 'react';

const TAB_TITLES = {
  inbox: {
    title: 'Invoice Inbox',
    desc: 'Review incoming supplier invoices, OCR status, and posting progress',
    icon: 'fa-solid fa-inbox'
  },
  review: {
    title: 'Review & Validate Invoice',
    desc: 'Side-by-side verification: original document preview against extracted accounting fields',
    icon: 'fa-solid fa-magnifying-glass-chart'
  },
  tally: {
    title: 'TallyPrime Connector & Gateway Logs',
    desc: 'Inspect XML HTTP transport, endpoint health, and immutable posting attempt history',
    icon: 'fa-solid fa-server'
  }
};

export default function Header({ 
  activeTab, 
  onTriggerUpload, 
  postingEnabled 
}) {
  const meta = TAB_TITLES[activeTab] || TAB_TITLES.inbox;

  return (
    <header className="top-header">
      <div className="header-left">
        <div className="brand-header-inline" style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div className="brand-logo" style={{ width: '36px', height: '36px', fontSize: '1rem', minWidth: '36px' }}>
            <i className="fa-solid fa-receipt"></i>
          </div>
          <div className="brand-text">
            <h1 style={{ fontSize: '0.92rem', lineHeight: 1.1 }}>BILL TO TALLY</h1>
            <span style={{ fontSize: '0.68rem', letterSpacing: '0.3px' }}>Ashan Tech Labs</span>
          </div>
        </div>

        <div className="header-v-divider" style={{ width: '1px', height: '28px', background: 'var(--border-subtle)', margin: '0 8px' }}></div>

        <div className="page-title-group">
          <h2 id="current-page-title">
            <i className={meta.icon} style={{ color: 'var(--color-amazon-orange)', fontSize: '1.05rem' }}></i>
            <span>{meta.title}</span>
          </h2>
          <span className="page-subtitle" id="current-page-desc">{meta.desc}</span>
        </div>
      </div>

      <div className="header-actions">
        <div 
          className="safety-toggle-pill" 
          id="posting-safety-indicator" 
          title="Safe Mode: Posting to live accounts is restricted per AGENTS.md rules"
        >
          <i className="fa-solid fa-shield-halved"></i>
          <span>{postingEnabled ? 'POSTING: TRUE' : 'POSTING: OFF (Test Mode)'}</span>
        </div>

        <button className="btn btn-orange btn-sm" id="btn-quick-upload" onClick={onTriggerUpload}>
          <i className="fa-solid fa-cloud-arrow-up"></i>
          <span>Upload Invoice</span>
        </button>
      </div>
    </header>
  );
}
