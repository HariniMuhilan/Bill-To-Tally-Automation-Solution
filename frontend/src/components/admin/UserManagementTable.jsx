import React, { useState } from 'react';
import * as XLSX from 'xlsx';
import { calculateDaysRemaining } from '../../data/adminMockData';

export default function UserManagementTable({
  users,
  onApproveUser,
  onDisapproveUser,
  onBlockUserToggle,
  onUpdatePayment,
  onChangeDeadline,
  onViewCredentials,
  onAddNewUser,
  onDeleteUser,
  onShowToast
}) {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [paymentFilter, setPaymentFilter] = useState('ALL');
  const [revealedPasswords, setRevealedPasswords] = useState({});

  function toggleRevealPassword(userId) {
    setRevealedPasswords(prev => ({
      ...prev,
      [userId]: !prev[userId]
    }));
  }

  // Filtering
  const filteredUsers = users.filter(u => {
    // Search query
    const q = searchTerm.toLowerCase().trim();
    const matchesSearch = !q ||
      u.shopName.toLowerCase().includes(q) ||
      u.ownerName.toLowerCase().includes(q) ||
      u.phone.toLowerCase().includes(q) ||
      u.email.toLowerCase().includes(q) ||
      (u.credentials?.username && u.credentials.username.toLowerCase().includes(q));

    // Status filter
    const matchesStatus = statusFilter === 'ALL' ||
      (statusFilter === 'BLOCKED' ? (u.accountStatus === 'BLOCKED' || u.accountStatus === 'DISAPPROVED') : u.accountStatus === statusFilter);

    // Payment filter
    const matchesPayment = paymentFilter === 'ALL' || u.paymentStatus === paymentFilter;

    return matchesSearch && matchesStatus && matchesPayment;
  });

  // Export to Excel
  function handleExportExcel() {
    try {
      const exportData = filteredUsers.map((u, idx) => ({
        'S.No': idx + 1,
        'Shop Name': u.shopName,
        'Owner Name': u.ownerName,
        'Phone': u.phone,
        'Email': u.email,
        'Location': u.location,
        'Plan': u.plan,
        'Monthly Fee (INR)': u.monthlyFee,
        'Account Status': u.accountStatus,
        'Payment Status': u.paymentStatus,
        'Payment Deadline': u.paymentDeadline || 'N/A',
        'Last Payment Date': u.lastPaymentDate || 'N/A',
        'Payment Method': u.lastPaymentMethod || 'N/A',
        'Transaction Ref': u.transactionRef || 'N/A',
        'Login Username': u.credentials?.username || 'Not Issued',
        'Credentials Active': u.credentials?.active ? 'YES' : 'NO',
        'Registration Date': u.registrationDate
      }));

      const ws = XLSX.utils.json_to_sheet(exportData);
      const wb = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(wb, ws, 'Client Subscriptions');
      XLSX.writeFile(wb, `BillBooks_Client_Subscriptions_${new Date().toISOString().split('T')[0]}.xlsx`);

      if (onShowToast) {
        onShowToast(`Exported ${filteredUsers.length} client records to Excel!`, 'success');
      }
    } catch (e) {
      if (onShowToast) {
        onShowToast('Failed to export Excel file.', 'danger');
      }
    }
  }

  return (
    <div className="admin-table-container">
      {/* Table Toolbar */}
      <div className="admin-table-toolbar">
        <div className="toolbar-left">
          {/* Search Box */}
          <div className="admin-search-wrap">
            <i className="fa-solid fa-magnifying-glass search-icon"></i>
            <input
              type="text"
              placeholder="Search by shop name, owner, username, or phone..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="admin-search-input"
            />
            {searchTerm && (
              <button
                type="button"
                className="btn-clear-search"
                onClick={() => setSearchTerm('')}
              >
                <i className="fa-solid fa-xmark"></i>
              </button>
            )}
          </div>

          {/* Status Filter */}
          <div className="admin-filter-group">
            <label>Status:</label>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="admin-filter-select"
            >
              <option value="ALL">All Account Statuses</option>
              <option value="APPROVED">Approved & Active</option>
              <option value="PENDING_APPROVAL">Pending Approval</option>
              <option value="BLOCKED">Blocked</option>
            </select>
          </div>

          {/* Payment Status Filter */}
          <div className="admin-filter-group">
            <label>Payment:</label>
            <select
              value={paymentFilter}
              onChange={(e) => setPaymentFilter(e.target.value)}
              className="admin-filter-select"
            >
              <option value="ALL">All Payments</option>
              <option value="PAID">Paid</option>
              <option value="PENDING">Pending</option>
              <option value="OVERDUE">Overdue</option>
              <option value="FAILED">Failed</option>
            </select>
          </div>
        </div>

        <div className="toolbar-right">
          <button
            type="button"
            className="btn btn-secondary btn-toolbar-action"
            onClick={handleExportExcel}
            title="Export filtered records to Microsoft Excel workbook"
          >
            <i className="fa-solid fa-file-excel" style={{ color: '#16794B', marginRight: '6px' }}></i>
            Export Excel
          </button>

          <button
            type="button"
            className="btn btn-primary btn-toolbar-action"
            onClick={onAddNewUser}
            style={{ background: '#493044', borderColor: '#493044', color: '#fff' }}
          >
            <i className="fa-solid fa-plus" style={{ marginRight: '6px' }}></i>
            Onboard New Shop
          </button>
        </div>
      </div>

      {/* Table Records Count & Summary */}
      <div className="admin-table-meta-bar">
        <span className="table-count-label">
          Showing <strong>{filteredUsers.length}</strong> of <strong>{users.length}</strong> registered businesses
        </span>
        {(searchTerm || statusFilter !== 'ALL' || paymentFilter !== 'ALL') && (
          <button
            type="button"
            className="btn-link-reset"
            onClick={() => { setSearchTerm(''); setStatusFilter('ALL'); setPaymentFilter('ALL'); }}
          >
            <i className="fa-solid fa-rotate-left"></i> Reset Filters
          </button>
        )}
      </div>

      {/* Users Table */}
      <div className="admin-table-scroll-wrapper">
        <table className="admin-data-table">
          <thead>
            <tr>
              <th style={{ width: '22%' }}>Shop / Client Info</th>
              <th style={{ width: '20%' }}>Login Credentials</th>
              <th style={{ width: '18%' }}>Payment Status</th>
              <th style={{ width: '16%' }}>Monthly Deadline</th>
              <th style={{ width: '11%' }}>Account Status</th>
              <th style={{ width: '13%', textAlign: 'center' }}>Admin Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredUsers.length === 0 ? (
              <tr>
                <td colSpan="6" style={{ textAlign: 'center', padding: '48px 16px', color: '#80536F' }}>
                  <i className="fa-solid fa-user-slash" style={{ fontSize: '2rem', marginBottom: '10px', display: 'block', color: '#CBD5E1' }}></i>
                  <div style={{ fontSize: '1rem', fontWeight: 600, color: '#111522' }}>No client accounts found</div>
                  <div style={{ fontSize: '0.82rem', marginTop: '4px' }}>Try adjusting your search query or filters.</div>
                </td>
              </tr>
            ) : (
              filteredUsers.map(user => {
                const deadlineInfo = calculateDaysRemaining(user.paymentDeadline);
                const hasCredentials = Boolean(user.credentials?.username);
                const isPasswordRevealed = Boolean(revealedPasswords[user.id]);

                return (
                  <tr key={user.id} className={`table-row-${user.accountStatus.toLowerCase()}`}>
                    
                    {/* 1. Shop / Client Info */}
                    <td>
                      <div className="client-cell-wrap">
                        <div className="client-shop-name">{user.shopName}</div>
                        <div className="client-owner-name">
                          <i className="fa-regular fa-user" style={{ marginRight: '5px' }}></i>
                          {user.ownerName}
                        </div>
                        <div className="client-contact-row">
                          <span title="Phone">
                            <i className="fa-solid fa-phone"></i> {user.phone}
                          </span>
                          <span className="client-location" title={user.location}>
                            <i className="fa-solid fa-location-dot"></i> {user.location.split(',')[0]}
                          </span>
                        </div>
                        <div style={{ marginTop: '5px' }}>
                          <span className="admin-pill pill-plan" title="Subscribed Tier">
                            {user.plan} &bull; ₹{user.monthlyFee}/mo
                          </span>
                        </div>
                      </div>
                    </td>

                    {/* 2. Login Credentials */}
                    <td>
                      {hasCredentials ? (
                        <div className="credentials-cell-wrap">
                          <div className="cred-row">
                            <span className="cred-label">User:</span>
                            <code className="cred-code">{user.credentials.username}</code>
                          </div>
                          <div className="cred-row" style={{ marginTop: '4px' }}>
                            <span className="cred-label">Pass:</span>
                            <code className="cred-code">
                              {isPasswordRevealed ? user.credentials.password : '••••••••'}
                            </code>
                            <button
                              type="button"
                              className="btn-icon-subtle"
                              onClick={() => toggleRevealPassword(user.id)}
                              title={isPasswordRevealed ? 'Hide Password' : 'Show Password'}
                            >
                              <i className={isPasswordRevealed ? 'fa-regular fa-eye-slash' : 'fa-regular fa-eye'}></i>
                            </button>
                          </div>
                          <div className="cred-actions" style={{ marginTop: '6px' }}>
                            <button
                              type="button"
                              className="btn-share-creds"
                              onClick={() => onViewCredentials(user)}
                              title="View & copy WhatsApp formatted credentials"
                            >
                              <i className="fa-solid fa-share-nodes"></i> Share / Copy
                            </button>
                            {!user.credentials.active && (
                              <span className="badge-creds-suspended" title="Access suspended">
                                Suspended
                              </span>
                            )}
                          </div>
                        </div>
                      ) : (
                        <div className="credentials-empty-wrap">
                          <div className="creds-not-issued">
                            <i className="fa-solid fa-lock" style={{ marginRight: '5px' }}></i>
                            Not Issued
                          </div>
                          <div className="creds-hint">Awaiting admin approval</div>
                          <button
                            type="button"
                            className="btn-quick-issue"
                            onClick={() => onApproveUser(user)}
                          >
                            <i className="fa-solid fa-key"></i> Issue Credentials
                          </button>
                        </div>
                      )}
                    </td>

                    {/* 3. Payment Status */}
                    <td>
                      <div className="payment-cell-wrap">
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                          <span className={`admin-pill pill-payment-${user.paymentStatus.toLowerCase()}`}>
                            {user.paymentStatus === 'PAID' && <i className="fa-solid fa-circle-check"></i>}
                            {user.paymentStatus === 'PENDING' && <i className="fa-solid fa-clock"></i>}
                            {user.paymentStatus === 'OVERDUE' && <i className="fa-solid fa-circle-exclamation"></i>}
                            {user.paymentStatus === 'FAILED' && <i className="fa-solid fa-circle-xmark"></i>}
                            {' '}{user.paymentStatus}
                          </span>
                        </div>

                        <div className="payment-amount-text">
                          ₹{user.monthlyFee} / month
                        </div>

                        {user.lastPaymentDate && (
                          <div className="payment-method-text" title={`Txn: ${user.transactionRef || 'N/A'}`}>
                            Paid {user.lastPaymentDate} via {user.lastPaymentMethod}
                          </div>
                        )}

                        <button
                          type="button"
                          className="btn-update-payment"
                          onClick={() => onUpdatePayment(user)}
                          title="Manually update payment status, amount, and payment mode"
                        >
                          <i className="fa-solid fa-pen-to-square"></i> Update Payment
                        </button>
                      </div>
                    </td>

                    {/* 4. Monthly Payment Deadline */}
                    <td>
                      <div className="deadline-cell-wrap">
                        <div className="deadline-date">
                          <i className="fa-regular fa-calendar-check" style={{ marginRight: '5px', color: '#493044' }}></i>
                          {user.paymentDeadline ? new Date(user.paymentDeadline).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) : 'Not Configured'}
                        </div>

                        {/* Deadline Status Badge */}
                        <div style={{ marginTop: '4px' }}>
                          {deadlineInfo.status === 'SAFE' && (
                            <span className="deadline-badge badge-safe">
                              Due in {deadlineInfo.days} days
                            </span>
                          )}
                          {deadlineInfo.status === 'DUE_SOON' && (
                            <span className="deadline-badge badge-soon">
                              <i className="fa-solid fa-clock"></i> Due in {deadlineInfo.days} days
                            </span>
                          )}
                          {deadlineInfo.status === 'DUE_TODAY' && (
                            <span className="deadline-badge badge-today">
                              <i className="fa-solid fa-triangle-exclamation"></i> Due Today!
                            </span>
                          )}
                          {deadlineInfo.status === 'OVERDUE' && (
                            <span className="deadline-badge badge-overdue">
                              <i className="fa-solid fa-triangle-exclamation"></i> Overdue {deadlineInfo.days}d
                            </span>
                          )}
                        </div>

                        <button
                          type="button"
                          className="btn-change-deadline"
                          onClick={() => onChangeDeadline(user)}
                          title="Change deadline date or grant grace period"
                        >
                          <i className="fa-regular fa-clock"></i> Adjust Deadline
                        </button>
                      </div>
                    </td>

                    {/* 5. Account Status */}
                    <td>
                      <div className="status-cell-wrap">
                        <span className={`admin-pill ${
                          user.accountStatus === 'APPROVED' ? 'pill-status-approved' :
                          user.accountStatus === 'PENDING_APPROVAL' ? 'pill-status-pending_approval' :
                          'pill-status-blocked'
                        }`}>
                          {user.accountStatus === 'APPROVED' && 'APPROVED'}
                          {user.accountStatus === 'PENDING_APPROVAL' && 'PENDING'}
                          {(user.accountStatus === 'DISAPPROVED' || user.accountStatus === 'BLOCKED') && 'BLOCKED'}
                        </span>
                      </div>
                    </td>

                    {/* 6. Admin Actions */}
                    <td>
                      <div className="actions-cell-wrap">
                        {/* APPROVE BUTTON (if payment done or needs approval) */}
                        {user.accountStatus !== 'APPROVED' && (
                          <button
                            type="button"
                            className="btn-action-pill btn-action-approve"
                            onClick={() => onApproveUser(user)}
                            title="Approve user and issue login credentials"
                          >
                            <i className="fa-solid fa-check"></i> Approve
                          </button>
                        )}

                        {/* BLOCK BUTTON (if payment not done) */}
                        {user.accountStatus !== 'BLOCKED' && user.accountStatus !== 'DISAPPROVED' && (
                          <button
                            type="button"
                            className="btn-action-pill btn-action-disapprove"
                            onClick={() => onDisapproveUser(user)}
                            title="Block user if payment is not done"
                          >
                            <i className="fa-solid fa-ban"></i> Block
                          </button>
                        )}

                        {/* DELETE / REMOVE BUTTON */}
                        <button
                          type="button"
                          className="btn-action-icon-delete"
                          onClick={() => {
                            if (window.confirm(`Are you sure you want to delete ${user.shopName}?`)) {
                              onDeleteUser(user.id);
                            }
                          }}
                          title="Delete client record"
                        >
                          <i className="fa-regular fa-trash-can"></i>
                        </button>
                      </div>
                    </td>

                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

