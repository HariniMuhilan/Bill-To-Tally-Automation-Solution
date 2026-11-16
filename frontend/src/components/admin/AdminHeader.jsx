import React from 'react';
import billbooksLogo from '../../assets/billbooks_logo.svg';

export default function AdminHeader({ admin, onLogout, pendingCount, overdueCount }) {
  return (
    <header className="admin-header">
      <div className="admin-header-left">
        <div className="admin-header-brand">
          <img src={billbooksLogo} alt="BillBooks" className="admin-header-logo" />
          <div className="admin-header-title-wrap">
            <div className="admin-header-title">
              <span>BillBooks</span>
              <span className="admin-header-badge">ADMIN CONSOLE</span>
            </div>
            <div className="admin-header-subtitle">
              Client Onboarding &bull; Payment Tracking &bull; Monthly Deadlines &bull; Credentials
            </div>
          </div>
        </div>
      </div>

      <div className="admin-header-right">
        {/* Urgent Alerts Pill */}
        {(pendingCount > 0 || overdueCount > 0) && (
          <div className="admin-alerts-pill">
            {pendingCount > 0 && (
              <span className="admin-alert-chip chip-pending" title="Clients awaiting credential approval">
                <i className="fa-solid fa-user-clock"></i> {pendingCount} Pending
              </span>
            )}
            {overdueCount > 0 && (
              <span className="admin-alert-chip chip-overdue" title="Clients with overdue monthly payment">
                <i className="fa-solid fa-triangle-exclamation"></i> {overdueCount} Overdue
              </span>
            )}
          </div>
        )}

        {/* Live System Indicator */}
        <div className="admin-system-status">
          <span className="admin-status-dot online"></span>
          <span className="admin-status-text">Production Active</span>
        </div>

        {/* Admin Profile & Logout */}
        <div className="admin-profile-pill">
          <div className="admin-avatar">
            <i className="fa-solid fa-user-shield"></i>
          </div>
          <div className="admin-meta">
            <span className="admin-name">{admin?.fullName || 'System Administrator'}</span>
            <span className="admin-role">{admin?.role || 'Administrator'}</span>
          </div>
          <button
            type="button"
            className="btn-admin-logout"
            onClick={onLogout}
            title="Sign out of Administrator Portal"
          >
            <i className="fa-solid fa-arrow-right-from-bracket"></i>
            <span>Logout</span>
          </button>
        </div>
      </div>
    </header>
  );
}

