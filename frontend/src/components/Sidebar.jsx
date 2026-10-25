import React, { useState, useRef, useEffect } from 'react';

export default function Sidebar({ 
  activeTab, 
  onSelectTab, 
  invoiceCounts, 
  tallyConnected, 
  tallyCompany,
  user,
  onLogout,
  onSwitchAccount
}) {
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const dropdownRef = useRef(null);

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
        {/* Only 3 components: Invoice Inbox, Review & Validate, Tally Connector (No section headers) */}
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

        <a 
          className={`nav-item ${activeTab === 'tally' ? 'active' : ''}`}
          onClick={() => onSelectTab('tally')}
        >
          <span className="nav-icon"><i className="fa-solid fa-server"></i></span>
          <span>Tally Connector</span>
        </a>
      </nav>

      <div className="sidebar-footer">
        {/* User Profile in Bottom Left Corner (Screenshot 3 relocated here) */}
        <div className={`user-profile-container upward ${dropdownOpen ? 'open' : ''}`} ref={dropdownRef}>
          <div 
            className="user-profile-badge sidebar-user-badge" 
            id="user-profile-badge" 
            title="Click for profile options & session management"
            onClick={() => setDropdownOpen(!dropdownOpen)}
          >
            <div className="avatar-circle" id="sidebar-user-avatar">
              {user?.initials || 'AU'}
            </div>
            <div className="user-info">
              <span className="user-name" id="sidebar-user-name">{user?.username || 'accounts_user_01'}</span>
              <span className="user-role" id="sidebar-user-role">{user?.role || 'Reviewer & Approver'}</span>
            </div>
            <i className="fa-solid fa-chevron-up profile-chevron"></i>
          </div>

          {dropdownOpen && (
            <div className="user-dropdown upward-dropdown" id="user-dropdown-menu" style={{ display: 'flex' }}>
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

        {/* Tally Status Card */}
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
