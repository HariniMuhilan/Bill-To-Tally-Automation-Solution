import React from 'react';

export default function BottomNavBar({ 
  activeTab, 
  onSelectTab, 
  invoiceCounts, 
  tallyConnected 
}) {
  return (
    <nav className="bottom-nav-bar" aria-label="Bottom Navigation">
      {/* 1. Invoice Inbox */}
        <button 
          type="button"
          className={`bottom-nav-btn ${activeTab === 'inbox' ? 'active' : ''}`}
          onClick={() => onSelectTab('inbox')}
        >
          <div className="bottom-nav-icon-wrap">
            <i className="fa-solid fa-inbox"></i>
            {invoiceCounts.total > 0 && (
              <span className="bottom-nav-badge">{invoiceCounts.total}</span>
            )}
          </div>
          <span className="bottom-nav-label">Invoice Inbox</span>
        </button>

        {/* 2. Review & Validate (Center Action) */}
        <button 
          type="button"
          className={`bottom-nav-btn center-action ${activeTab === 'review' ? 'active' : ''}`}
          onClick={() => onSelectTab('review')}
        >
          <div className="bottom-center-icon">
            <i className="fa-solid fa-magnifying-glass-chart"></i>
            {invoiceCounts.needsReview > 0 && (
              <span className="bottom-center-badge">{invoiceCounts.needsReview}</span>
            )}
          </div>
          <span className="bottom-nav-label">Review & Validate</span>
        </button>

        {/* 3. Tally Connector */}
        <button 
          type="button"
          className={`bottom-nav-btn ${activeTab === 'tally' ? 'active' : ''}`}
          onClick={() => onSelectTab('tally')}
        >
          <div className="bottom-nav-icon-wrap">
            <i className="fa-solid fa-server"></i>
            <span className={`bottom-status-dot ${tallyConnected ? 'online' : ''}`}></span>
          </div>
          <span className="bottom-nav-label">Tally Connector</span>
        </button>
      </nav>
  );
}
