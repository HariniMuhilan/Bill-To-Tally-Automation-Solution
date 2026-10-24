import React, { useState, useRef, useEffect } from 'react';

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
  mappings: {
    title: 'Master Mappings Registry',
    desc: 'Map raw OCR descriptions & supplier names to corresponding TallyPrime master ledgers',
    icon: 'fa-solid fa-diagram-project'
  },
  tally: {
    title: 'TallyPrime Connector & Gateway Logs',
    desc: 'Inspect XML HTTP transport, endpoint health, and immutable posting attempt history',
    icon: 'fa-solid fa-server'
  },
  audit: {
    title: 'Audit Trail & Compliance Log',
    desc: 'Full forensic lifecycle tracking of user edits, approvals, and system state changes',
    icon: 'fa-solid fa-clock-rotate-left'
  },
  settings: {
    title: 'Configuration & Safety Parameters',
    desc: 'Tally connection settings, idempotency rules, rounding tolerance, and role boundaries',
    icon: 'fa-solid fa-sliders'
  }
};

export default function Header({ 
  activeTab, 
  user, 
  onLogout, 
  onSwitchAccount, 
  onTriggerUpload, 
  postingEnabled 
}) {
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const dropdownRef = useRef(null);

  const meta = TAB_TITLES[activeTab] || TAB_TITLES.inbox;

  useEffect(() => {
    function handleClickOutside(e) {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target)) {
        setDropdownOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <header className="top-header">
      <div className="header-left">
        <div className="page-title-group">
          <h2 id="current-page-title">
            <i className={meta.icon} style={{ color: 'var(--palette-azure)', fontSize: '1.1rem' }}></i>
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
          <span>{postingEnabled ? 'POSTING_ENABLED: true' : 'POSTING_ENABLED: false (Test Mode)'}</span>
        </div>

        <button className="btn btn-primary btn-sm" id="btn-quick-upload" onClick={onTriggerUpload}>
          <i className="fa-solid fa-cloud-arrow-up"></i>
          <span>Upload Invoice</span>
        </button>

        {/* User Profile & Session Dropdown */}
        <div className={`user-profile-container ${dropdownOpen ? 'open' : ''}`} ref={dropdownRef}>
          <div 
            className="user-profile-badge" 
            id="user-profile-badge" 
            title="Click for profile options & session management"
            onClick={() => setDropdownOpen(!dropdownOpen)}
          >
            <div className="avatar-circle" id="header-user-avatar">
              {user?.initials || 'AU'}
            </div>
            <div className="user-info">
              <span className="user-name" id="header-user-name">{user?.username || 'accounts_user_01'}</span>
              <span className="user-role" id="header-user-role">{user?.role || 'Reviewer & Approver'}</span>
            </div>
            <i className="fa-solid fa-chevron-down profile-chevron"></i>
          </div>

          {dropdownOpen && (
            <div className="user-dropdown" id="user-dropdown-menu" style={{ display: 'flex' }}>
              <div className="dropdown-header">
                <div className="dropdown-avatar" id="dropdown-user-avatar">
                  {user?.initials || 'AU'}
                </div>
                <div>
                  <div className="dropdown-name" id="dropdown-user-name">{user?.fullName || user?.username}</div>
                  <div className="dropdown-role" id="dropdown-user-role">{user?.role || 'Reviewer & Approver'}</div>
                </div>
              </div>
              <div className="dropdown-divider"></div>
              <button 
                type="button" 
                className="dropdown-item" 
                onClick={() => { setDropdownOpen(false); onSwitchAccount(); }}
              >
                <i className="fa-solid fa-users" style={{ color: 'var(--color-azure-text)' }}></i>
                <span>Switch / Re-login</span>
              </button>
              <button 
                type="button" 
                className="dropdown-item text-danger" 
                onClick={() => { setDropdownOpen(false); onLogout(); }}
              >
                <i className="fa-solid fa-arrow-right-from-bracket"></i>
                <span>Log Out</span>
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
