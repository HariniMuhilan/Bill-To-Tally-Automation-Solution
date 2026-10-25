import React, { useState, useRef, useEffect } from 'react';

export default function UserProfileBottomLeft({ user, onLogout, onSwitchAccount }) {
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
    <div className="bottom-left-profile-anchor" ref={dropdownRef}>
      <div 
        className="user-profile-badge bottom-avatar-pill" 
        id="user-profile-badge-bottom" 
        title="Click for profile options & session management"
        onClick={() => setDropdownOpen(!dropdownOpen)}
      >
        <div className="avatar-circle" id="bottom-user-avatar">
          {user?.initials || 'SA'}
        </div>
        <div className="user-info bottom-avatar-info">
          <span className="user-name bottom-avatar-name" id="bottom-user-name">
            {user?.username || 'admin'}
          </span>
          <span className="user-role bottom-avatar-role" id="bottom-user-role">
            {user?.role || 'Administrator'}
          </span>
        </div>
        <i className={`fa-solid ${dropdownOpen ? 'fa-chevron-down' : 'fa-chevron-up'} profile-chevron`}></i>
      </div>

      {dropdownOpen && (
        <div className="user-dropdown bottom-profile-dropdown" id="user-dropdown-menu-bottom" style={{ display: 'flex' }}>
          <div className="dropdown-header">
            <div className="dropdown-avatar" id="dropdown-user-avatar">
              {user?.initials || 'SA'}
            </div>
            <div>
              <div className="dropdown-name" id="dropdown-user-name">
                {user?.fullName || user?.username || 'admin'}
              </div>
              <div className="dropdown-role" id="dropdown-user-role">
                {user?.role || 'Administrator'}
              </div>
            </div>
          </div>
          <div className="dropdown-divider"></div>
          <button 
            type="button" 
            className="dropdown-item" 
            onClick={() => { setDropdownOpen(false); onSwitchAccount(); }}
          >
            <i className="fa-solid fa-users" style={{ color: 'var(--color-amazon-orange)' }}></i>
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
  );
}
