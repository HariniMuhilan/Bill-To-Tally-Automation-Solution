import React, { useState, useEffect } from 'react';
import {
  fetchAccessRequests,
  rejectAccessRequest,
  fetchSubscribers,
  provisionSubscriber,
  cancelSubscriber,
  unblockSubscriber,
  resetDeviceSession,
  deleteSubscriber,
  clearAdminToken,
} from '../services/adminApi';
import billbooksLogo from '../assets/billbooks_logo.svg';

export default function AdminDashboardView({ admin, onLogout, onShowToast }) {
  const [activeTab, setActiveTab] = useState('subscribers'); // 'subscribers' | 'requests'
  const [subscribers, setSubscribers] = useState([]);
  const [accessRequests, setAccessRequests] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');

  // Modals state
  const [provisionModalOpen, setProvisionModalOpen] = useState(false);
  const [selectedRequest, setSelectedRequest] = useState(null);
  const [renewModalUser, setRenewModalUser] = useState(null);
  const [credentialsModalData, setCredentialsModalData] = useState(null);

  // Form states for Provision Modal
  const [provEmail, setProvEmail] = useState('');
  const [provPassword, setProvPassword] = useState('');
  const [provFullName, setProvFullName] = useState('');
  const [provBusinessName, setProvBusinessName] = useState('');
  const [provPhone, setProvPhone] = useState('');
  const [provAmount, setProvAmount] = useState(1499);
  const [provNotes, setProvNotes] = useState('First month B2B onboarding via UPI');
  const [provStart, setProvStart] = useState('');
  const [provEnd, setProvEnd] = useState('');

  // Form states for Renew/Unblock Modal
  const [renewAmount, setRenewAmount] = useState(1499);
  const [renewNotes, setRenewNotes] = useState('Monthly subscription renewal');
  const [renewStart, setRenewStart] = useState('');
  const [renewEnd, setRenewEnd] = useState('');

  useEffect(() => {
    loadData();
    const today = new Date().toISOString().split('T')[0];
    const nextMonth = new Date(Date.now() + 86400000 * 30).toISOString().split('T')[0];
    setProvStart(today);
    setProvEnd(nextMonth);
    setRenewStart(today);
    setRenewEnd(nextMonth);
  }, []);

  async function loadData() {
    setLoading(true);
    try {
      const [subs, reqs] = await Promise.all([
        fetchSubscribers(),
        fetchAccessRequests(),
      ]);
      setSubscribers(subs || []);
      setAccessRequests(reqs || []);
    } catch (e) {
      if (onShowToast) onShowToast('Failed to load latest records from server.', 'danger');
    } finally {
      setLoading(false);
    }
  }

  function handleOpenProvision(req) {
    setSelectedRequest(req);
    setProvEmail(req.email || '');
    setProvFullName(req.full_name || '');
    setProvBusinessName(req.business_name || '');
    setProvPhone(req.phone || '');
    // Auto-generate strong default password
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$';
    let rand = '';
    for (let i = 0; i < 4; i++) rand += chars.charAt(Math.floor(Math.random() * chars.length));
    setProvPassword(`BillBooks@${new Date().getFullYear()}${rand}`);
    setProvisionModalOpen(true);
  }

  async function handleExecuteProvision(e) {
    e.preventDefault();
    try {
      const res = await provisionSubscriber({
        request_id: selectedRequest?.id,
        email: provEmail.trim(),
        password: provPassword.trim(),
        full_name: provFullName.trim(),
        business_name: provBusinessName.trim(),
        phone: provPhone.trim(),
        amount_paid_inr: Number(provAmount) || 0,
        payment_notes: provNotes.trim(),
        subscription_start: provStart,
        subscription_end: provEnd,
      });

      if (onShowToast) onShowToast(`Provisioned account for ${provBusinessName}!`, 'success');
      setProvisionModalOpen(false);

      // Show temporary credentials modal for 1-click sharing
      setCredentialsModalData({
        business_name: provBusinessName,
        email: provEmail,
        password: provPassword,
        start: provStart,
        end: provEnd,
      });

      loadData();
    } catch (err) {
      if (onShowToast) onShowToast(err.message, 'danger');
    }
  }

  async function handleRejectRequest(requestId, businessName) {
    if (!window.confirm(`Reject onboarding access request for "${businessName}"?`)) return;
    try {
      await rejectAccessRequest(requestId);
      if (onShowToast) onShowToast(`Access request for ${businessName} marked rejected.`, 'info');
      loadData();
    } catch (err) {
      if (onShowToast) onShowToast(err.message, 'danger');
    }
  }

  async function handleCancelSubscription(user) {
    if (!window.confirm(`Cancel/block subscription for "${user.business_name}"?\n(Scanning will be disabled; existing data remains viewable.)`)) return;
    try {
      await cancelSubscriber(user.user_id);
      if (onShowToast) onShowToast(`Subscription cancelled for ${user.business_name}.`, 'warning');
      loadData();
    } catch (err) {
      if (onShowToast) onShowToast(err.message, 'danger');
    }
  }

  function handleOpenRenew(user) {
    setRenewModalUser(user);
    setRenewAmount(user.amount_paid_inr || 1499);
    const today = new Date().toISOString().split('T')[0];
    const nextMonth = new Date(Date.now() + 86400000 * 30).toISOString().split('T')[0];
    setRenewStart(today);
    setRenewEnd(nextMonth);
  }

  async function handleExecuteRenew(e) {
    e.preventDefault();
    if (!renewModalUser) return;
    try {
      await unblockSubscriber(renewModalUser.user_id, {
        amount_paid_inr: Number(renewAmount) || 0,
        payment_notes: renewNotes.trim(),
        subscription_start: renewStart,
        subscription_end: renewEnd,
      });
      if (onShowToast) onShowToast(`Subscription renewed for ${renewModalUser.business_name}!`, 'success');
      setRenewModalUser(null);
      loadData();
    } catch (err) {
      if (onShowToast) onShowToast(err.message, 'danger');
    }
  }

  async function handleResetDevice(user) {
    if (!window.confirm(`Reset active device lock for "${user.business_name}"?\nThis allows them to log in on a new device.`)) return;
    try {
      await resetDeviceSession(user.user_id);
      if (onShowToast) onShowToast(`Device lock reset for ${user.business_name}.`, 'info');
      loadData();
    } catch (err) {
      if (onShowToast) onShowToast(err.message, 'danger');
    }
  }

  async function handleDeleteSubscriber(user) {
    const confirmation = window.prompt(`Type DELETE to permanently wipe "${user.business_name}" and all uploaded bill photos:`);
    if (confirmation !== 'DELETE') return;
    try {
      await deleteSubscriber(user.user_id);
      if (onShowToast) onShowToast(`User ${user.business_name} permanently deleted.`, 'danger');
      loadData();
    } catch (err) {
      if (onShowToast) onShowToast(err.message, 'danger');
    }
  }

  // Derived filter logic
  const filteredSubscribers = subscribers.filter(s => {
    const q = searchTerm.toLowerCase().trim();
    const matchesSearch = !q ||
      (s.business_name || '').toLowerCase().includes(q) ||
      (s.full_name || '').toLowerCase().includes(q) ||
      (s.email || '').toLowerCase().includes(q) ||
      (s.phone || '').toLowerCase().includes(q);

    const today = new Date().toISOString().split('T')[0];
    const isExpired = s.subscription_end && s.subscription_end < today;
    const computedStatus = s.status === 'cancelled' ? 'cancelled' : (isExpired ? 'expired' : 'active');

    const matchesStatus = statusFilter === 'ALL' || computedStatus === statusFilter.toLowerCase();
    return matchesSearch && matchesStatus;
  });

  const pendingRequests = accessRequests.filter(r => r.status === 'pending');

  // KPI calculations
  const totalRevenue = subscribers
    .filter(s => s.status === 'active')
    .reduce((sum, s) => sum + (Number(s.amount_paid_inr) || 0), 0);

  return (
    <div className="admin-portal-layout">
      {/* Header */}
      <header className="admin-header">
        <div className="admin-header-brand">
          <img src={billbooksLogo} alt="BillBooks" className="admin-header-logo" />
          <div className="admin-header-title-wrap">
            <div className="admin-header-title">
              <span>BillBooks</span>
              <span className="admin-header-badge">PROVISIONED ADMIN</span>
            </div>
            <div className="admin-header-subtitle">
              Single-Device B2B Provisioning &bull; Expiry Gating &bull; Cloud Excel Sync
            </div>
          </div>
        </div>

        <div className="admin-header-right">
          {pendingRequests.length > 0 && (
            <span className="admin-alert-chip chip-pending" onClick={() => setActiveTab('requests')} style={{ cursor: 'pointer' }}>
              <i className="fa-solid fa-user-clock"></i> {pendingRequests.length} New Requests
            </span>
          )}

          <div className="admin-profile-pill">
            <div className="admin-avatar">
              <i className="fa-solid fa-user-shield"></i>
            </div>
            <div className="admin-meta">
              <span className="admin-name">{admin?.fullName || 'Master Administrator'}</span>
              <span className="admin-role">{admin?.email || 'admin@billbooks.app'}</span>
            </div>
            <button type="button" className="btn-admin-logout" onClick={onLogout} title="Sign Out">
              <i className="fa-solid fa-arrow-right-from-bracket"></i>
              <span>Logout</span>
            </button>
          </div>
        </div>
      </header>

      {/* Main Container */}
      <main className="admin-main-content">
        <div className="admin-container">

          {/* Top KPI Cards */}
          <div className="admin-stats-grid">
            <div className="admin-stat-card">
              <div className="stat-card-top">
                <span className="stat-card-label">ACTIVE SUBSCRIBERS</span>
                <div className="stat-card-icon" style={{ background: '#E6F4EA', color: '#16794B' }}>
                  <i className="fa-solid fa-users"></i>
                </div>
              </div>
              <div className="stat-card-value" style={{ color: '#16794B' }}>
                {subscribers.filter(s => s.status === 'active').length}
              </div>
              <div className="stat-card-subtext">Provisioned & scanning active</div>
            </div>

            <div className="admin-stat-card">
              <div className="stat-card-top">
                <span className="stat-card-label">PENDING REQUESTS</span>
                <div className="stat-card-icon" style={{ background: '#FEF3C7', color: '#B86E00' }}>
                  <i className="fa-solid fa-user-clock"></i>
                </div>
              </div>
              <div className="stat-card-value" style={{ color: '#B86E00' }}>
                {pendingRequests.length}
              </div>
              <div className="stat-card-subtext">Awaiting admin provisioning</div>
            </div>

            <div className="admin-stat-card">
              <div className="stat-card-top">
                <span className="stat-card-label">ACTIVE MRR</span>
                <div className="stat-card-icon" style={{ background: '#FFF3E0', color: '#FF9900' }}>
                  <i className="fa-solid fa-indian-rupee-sign"></i>
                </div>
              </div>
              <div className="stat-card-value" style={{ color: '#FF9900' }}>
                ₹{totalRevenue.toLocaleString('en-IN')}
              </div>
              <div className="stat-card-subtext">Monthly recurring collection</div>
            </div>

            <div className="admin-stat-card">
              <div className="stat-card-top">
                <span className="stat-card-label">EXPIRED / VIEW-ONLY</span>
                <div className="stat-card-icon" style={{ background: '#FEE2E2', color: '#B91C1C' }}>
                  <i className="fa-solid fa-calendar-xmark"></i>
                </div>
              </div>
              <div className="stat-card-value" style={{ color: '#B91C1C' }}>
                {subscribers.filter(s => s.status === 'cancelled' || (s.subscription_end && s.subscription_end < new Date().toISOString().split('T')[0])).length}
              </div>
              <div className="stat-card-subtext">Grace mode (reads enabled)</div>
            </div>
          </div>

          {/* Navigation Tabs Bar */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '18px', borderBottom: '1px solid #E8E0E5', paddingBottom: '12px' }}>
            <div style={{ display: 'flex', gap: '10px' }}>
              <button
                type="button"
                className={`btn ${activeTab === 'subscribers' ? 'btn-primary' : 'btn-secondary'}`}
                style={{
                  background: activeTab === 'subscribers' ? '#493044' : '#FFFFFF',
                  color: activeTab === 'subscribers' ? '#FFFFFF' : '#493044',
                  borderColor: '#E8E0E5',
                  fontWeight: 700,
                  fontSize: '0.88rem',
                  padding: '9px 18px',
                  borderRadius: '8px',
                }}
                onClick={() => setActiveTab('subscribers')}
              >
                <i className="fa-solid fa-store" style={{ marginRight: '6px' }}></i>
                Active Subscribers ({subscribers.length})
              </button>

              <button
                type="button"
                className={`btn ${activeTab === 'requests' ? 'btn-primary' : 'btn-secondary'}`}
                style={{
                  background: activeTab === 'requests' ? '#493044' : '#FFFFFF',
                  color: activeTab === 'requests' ? '#FFFFFF' : '#493044',
                  borderColor: '#E8E0E5',
                  fontWeight: 700,
                  fontSize: '0.88rem',
                  padding: '9px 18px',
                  borderRadius: '8px',
                  position: 'relative',
                }}
                onClick={() => setActiveTab('requests')}
              >
                <i className="fa-solid fa-inbox" style={{ marginRight: '6px' }}></i>
                Access Requests ({accessRequests.length})
                {pendingRequests.length > 0 && (
                  <span style={{ marginLeft: '6px', background: '#B86E00', color: '#FFF', borderRadius: '10px', padding: '1px 6px', fontSize: '0.72rem' }}>
                    {pendingRequests.length}
                  </span>
                )}
              </button>
            </div>

            <button
              type="button"
              className="btn btn-secondary"
              onClick={loadData}
              disabled={loading}
              style={{ fontSize: '0.82rem', padding: '8px 14px' }}
            >
              <i className={`fa-solid fa-arrows-rotate ${loading ? 'fa-spin' : ''}`} style={{ marginRight: '6px' }}></i>
              Refresh
            </button>
          </div>

          {/* TAB 1: SUBSCRIBERS */}
          {activeTab === 'subscribers' && (
            <div className="admin-table-container">
              <div className="admin-table-toolbar">
                <div className="toolbar-left">
                  <div className="admin-search-wrap">
                    <i className="fa-solid fa-magnifying-glass search-icon"></i>
                    <input
                      type="text"
                      placeholder="Search subscriber by shop, owner, email, or phone..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="admin-search-input"
                    />
                  </div>

                  <div className="admin-filter-group">
                    <label>Status:</label>
                    <select
                      value={statusFilter}
                      onChange={(e) => setStatusFilter(e.target.value)}
                      className="admin-filter-select"
                    >
                      <option value="ALL">All Statuses</option>
                      <option value="ACTIVE">Active (Valid)</option>
                      <option value="EXPIRED">Expired (View-Only)</option>
                      <option value="CANCELLED">Cancelled</option>
                    </select>
                  </div>
                </div>

                <div className="toolbar-right">
                  <span style={{ fontSize: '0.8rem', color: '#80536F' }}>
                    Showing <strong>{filteredSubscribers.length}</strong> subscribers
                  </span>
                </div>
              </div>

              <div className="admin-table-scroll-wrapper">
                <table className="admin-data-table">
                  <thead>
                    <tr>
                      <th style={{ width: '22%' }}>Shop / Owner</th>
                      <th style={{ width: '18%' }}>Contact</th>
                      <th style={{ width: '14%' }}>Amount Paid</th>
                      <th style={{ width: '18%' }}>Subscription Validity</th>
                      <th style={{ width: '14%' }}>Active Device Lock</th>
                      <th style={{ width: '14%', textAlign: 'center' }}>Admin Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredSubscribers.length === 0 ? (
                      <tr>
                        <td colSpan="6" style={{ textAlign: 'center', padding: '48px 16px', color: '#80536F' }}>
                          <i className="fa-solid fa-store-slash" style={{ fontSize: '2rem', marginBottom: '8px', display: 'block', color: '#CBD5E1' }}></i>
                          No subscriber records found.
                        </td>
                      </tr>
                    ) : (
                      filteredSubscribers.map(sub => {
                        const today = new Date().toISOString().split('T')[0];
                        const isExpired = sub.subscription_end && sub.subscription_end < today;
                        const isCancelled = sub.status === 'cancelled';

                        return (
                          <tr key={sub.user_id}>
                            <td>
                              <div style={{ fontWeight: 700, color: '#111522', fontSize: '0.92rem' }}>
                                {sub.business_name || 'B2B Client'}
                              </div>
                              <div style={{ fontSize: '0.8rem', color: '#493044', marginTop: '2px' }}>
                                <i className="fa-regular fa-user" style={{ marginRight: '4px' }}></i>
                                {sub.full_name || '—'}
                              </div>
                            </td>

                            <td>
                              <div style={{ fontSize: '0.82rem', color: '#111522' }}>{sub.email}</div>
                              <div style={{ fontSize: '0.76rem', color: '#80536F', marginTop: '2px' }}>
                                <i className="fa-solid fa-phone" style={{ marginRight: '4px' }}></i>{sub.phone || '—'}
                              </div>
                            </td>

                            <td>
                              <div style={{ fontWeight: 700, color: '#16794B', fontSize: '0.9rem' }}>
                                ₹{(Number(sub.amount_paid_inr) || 0).toLocaleString('en-IN')}
                              </div>
                              {sub.payment_notes && (
                                <div style={{ fontSize: '0.72rem', color: '#80536F', maxWidth: '160px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={sub.payment_notes}>
                                  {sub.payment_notes}
                                </div>
                              )}
                            </td>

                            <td>
                              <div style={{ fontSize: '0.82rem', fontWeight: 600, color: '#111522' }}>
                                {sub.subscription_start} &rarr; {sub.subscription_end}
                              </div>
                              <div style={{ marginTop: '4px' }}>
                                {isCancelled ? (
                                  <span className="admin-pill" style={{ background: '#FEE2E2', color: '#B91C1C' }}>
                                    <i className="fa-solid fa-ban"></i> Cancelled
                                  </span>
                                ) : isExpired ? (
                                  <span className="admin-pill" style={{ background: '#FEF3C7', color: '#B86E00' }}>
                                    <i className="fa-solid fa-clock"></i> Expired (View-Only)
                                  </span>
                                ) : (
                                  <span className="admin-pill" style={{ background: '#E6F4EA', color: '#16794B' }}>
                                    <i className="fa-solid fa-circle-check"></i> Active
                                  </span>
                                )}
                              </div>
                            </td>

                            <td>
                              {sub.active_device_label ? (
                                <div>
                                  <div style={{ fontSize: '0.78rem', fontWeight: 600, color: '#111522' }}>
                                    <i className="fa-solid fa-mobile-screen" style={{ marginRight: '4px', color: '#16794B' }}></i>
                                    {sub.active_device_label}
                                  </div>
                                  <button
                                    type="button"
                                    onClick={() => handleResetDevice(sub)}
                                    className="btn btn-sm btn-subtle"
                                    style={{ marginTop: '4px', fontSize: '0.72rem', padding: '2px 6px' }}
                                    title="Clear single-device lock"
                                  >
                                    <i className="fa-solid fa-arrow-rotate-left"></i> Reset Device
                                  </button>
                                </div>
                              ) : (
                                <span style={{ fontSize: '0.75rem', color: '#9CA3AF' }}>No device locked</span>
                              )}
                            </td>

                            <td>
                              <div style={{ display: 'flex', gap: '6px', justifyContent: 'center', flexWrap: 'wrap' }}>
                                {isCancelled || isExpired ? (
                                  <button
                                    type="button"
                                    onClick={() => handleOpenRenew(sub)}
                                    className="btn-action-pill btn-action-approve"
                                    title="Unblock and renew subscription"
                                  >
                                    <i className="fa-solid fa-play"></i> Renew / Unblock
                                  </button>
                                ) : (
                                  <button
                                    type="button"
                                    onClick={() => handleCancelSubscription(sub)}
                                    className="btn-action-pill btn-action-disapprove"
                                    title="Cancel subscription (blocks scan, keeps view-only)"
                                  >
                                    <i className="fa-solid fa-ban"></i> Cancel
                                  </button>
                                )}

                                <button
                                  type="button"
                                  onClick={() => handleDeleteSubscriber(sub)}
                                  className="btn-action-icon-delete"
                                  title="Permanently delete user and photos"
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
          )}

          {/* TAB 2: ACCESS REQUESTS */}
          {activeTab === 'requests' && (
            <div className="admin-table-container">
              <div className="admin-table-toolbar">
                <span style={{ fontSize: '0.88rem', fontWeight: 700, color: '#111522' }}>
                  Client Onboarding Inquiries (Mobile App / Web)
                </span>
                <span style={{ fontSize: '0.8rem', color: '#80536F' }}>
                  {pendingRequests.length} pending review
                </span>
              </div>

              <div className="admin-table-scroll-wrapper">
                <table className="admin-data-table">
                  <thead>
                    <tr>
                      <th style={{ width: '35%' }}>Business & Contact Name</th>
                      <th style={{ width: '30%' }}>Email & Phone</th>
                      <th style={{ width: '15%' }}>Status</th>
                      <th style={{ width: '20%', textAlign: 'center' }}>Provision</th>
                    </tr>
                  </thead>
                  <tbody>
                    {accessRequests.length === 0 ? (
                      <tr>
                        <td colSpan="4" style={{ textAlign: 'center', padding: '48px 16px', color: '#80536F' }}>
                          No onboarding requests recorded.
                        </td>
                      </tr>
                    ) : (
                      accessRequests.map(req => (
                        <tr key={req.id}>
                          <td>
                            <div style={{ fontWeight: 700, color: '#111522', fontSize: '0.92rem' }}>
                              {req.business_name}
                            </div>
                            <div style={{ fontSize: '0.8rem', color: '#493044', marginTop: '2px' }}>
                              {req.full_name}
                            </div>
                            <div style={{ fontSize: '0.72rem', color: '#80536F', marginTop: '2px' }}>
                              Received: {new Date(req.created_at).toLocaleString('en-IN')}
                            </div>
                          </td>

                          <td>
                            <div style={{ fontSize: '0.82rem', color: '#111522' }}>{req.email}</div>
                            <div style={{ fontSize: '0.78rem', color: '#80536F', marginTop: '2px' }}>
                              <i className="fa-solid fa-phone" style={{ marginRight: '4px' }}></i>{req.phone}
                            </div>
                          </td>

                          <td>
                            <span className={`admin-pill ${req.status === 'approved' ? 'pill-status-approved' : req.status === 'rejected' ? 'pill-status-disapproved' : 'pill-status-pending_approval'}`}>
                              {req.status.toUpperCase()}
                            </span>
                          </td>

                          <td>
                            <div style={{ display: 'flex', gap: '6px', justifyContent: 'center' }}>
                              {req.status !== 'approved' && (
                                <button
                                  type="button"
                                  onClick={() => handleOpenProvision(req)}
                                  className="btn-action-pill btn-action-approve"
                                  style={{ padding: '6px 12px' }}
                                  title="Approve and provision account"
                                >
                                  <i className="fa-solid fa-user-check"></i> Provision
                                </button>
                              )}

                              {req.status === 'pending' && (
                                <button
                                  type="button"
                                  onClick={() => handleRejectRequest(req.id, req.business_name)}
                                  className="btn-action-pill btn-action-disapprove"
                                  title="Reject request"
                                >
                                  <i className="fa-solid fa-xmark"></i>
                                </button>
                              )}
                            </div>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}

        </div>
      </main>

      {/* MODAL 1: PROVISION SUBSCRIBER */}
      {provisionModalOpen && (
        <div className="modal-backdrop">
          <div className="modal-container admin-modal-card" style={{ maxWidth: '580px' }}>
            <div className="modal-header">
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div className="modal-icon-badge" style={{ background: '#E6F4EA', color: '#16794B' }}>
                  <i className="fa-solid fa-user-plus"></i>
                </div>
                <div>
                  <h3 style={{ margin: 0, fontSize: '1.15rem' }}>Approve & Provision Account</h3>
                  <p style={{ margin: 0, fontSize: '0.82rem', color: '#80536F' }}>
                    Creates confirmed Supabase Auth credentials + active subscription
                  </p>
                </div>
              </div>
              <button type="button" className="btn-modal-close" onClick={() => setProvisionModalOpen(false)}>
                <i className="fa-solid fa-xmark"></i>
              </button>
            </div>

            <form onSubmit={handleExecuteProvision}>
              <div className="modal-body" style={{ padding: '20px 24px', maxHeight: '72vh', overflowY: 'auto' }}>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '14px' }}>
                  <div className="form-group">
                    <label style={{ fontSize: '0.8rem', fontWeight: 600 }}>Business / Shop Name *</label>
                    <input type="text" className="auth-input" value={provBusinessName} onChange={(e) => setProvBusinessName(e.target.value)} required />
                  </div>
                  <div className="form-group">
                    <label style={{ fontSize: '0.8rem', fontWeight: 600 }}>Owner / Contact Name *</label>
                    <input type="text" className="auth-input" value={provFullName} onChange={(e) => setProvFullName(e.target.value)} required />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '14px' }}>
                  <div className="form-group">
                    <label style={{ fontSize: '0.8rem', fontWeight: 600 }}>Email Address *</label>
                    <input type="email" className="auth-input" value={provEmail} onChange={(e) => setProvEmail(e.target.value)} required />
                  </div>
                  <div className="form-group">
                    <label style={{ fontSize: '0.8rem', fontWeight: 600 }}>Phone Number *</label>
                    <input type="text" className="auth-input" value={provPhone} onChange={(e) => setProvPhone(e.target.value)} required />
                  </div>
                </div>

                <div className="form-group" style={{ marginBottom: '14px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
                    <label style={{ fontSize: '0.8rem', fontWeight: 600 }}>Initial Temporary Password *</label>
                    <button
                      type="button"
                      onClick={() => {
                        const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$';
                        let rand = '';
                        for (let i = 0; i < 4; i++) rand += chars.charAt(Math.floor(Math.random() * chars.length));
                        setProvPassword(`BillBooks@${new Date().getFullYear()}${rand}`);
                      }}
                      className="btn btn-sm btn-subtle"
                      style={{ fontSize: '0.72rem', padding: '2px 6px' }}
                    >
                      <i className="fa-solid fa-arrows-rotate"></i> Regenerate
                    </button>
                  </div>
                  <input type="text" className="auth-input" value={provPassword} onChange={(e) => setProvPassword(e.target.value)} required />
                  <div style={{ fontSize: '0.72rem', color: '#80536F', marginTop: '3px' }}>
                    User will be confirmed immediately and can reset their password via Forgot Password in the app.
                  </div>
                </div>

                <div style={{ background: '#F7F2F4', padding: '14px', borderRadius: '10px', border: '1px solid #E8E0E5', marginBottom: '14px' }}>
                  <div style={{ fontSize: '0.78rem', fontWeight: 700, color: '#493044', marginBottom: '8px' }}>
                    SUBSCRIPTION DATES & PAYMENT
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '10px' }}>
                    <div className="form-group">
                      <label style={{ fontSize: '0.76rem', fontWeight: 600 }}>Subscription Start Date *</label>
                      <input type="date" className="auth-input" value={provStart} onChange={(e) => setProvStart(e.target.value)} required />
                    </div>
                    <div className="form-group">
                      <label style={{ fontSize: '0.76rem', fontWeight: 600 }}>Subscription End Date *</label>
                      <input type="date" className="auth-input" value={provEnd} onChange={(e) => setProvEnd(e.target.value)} required />
                    </div>
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                    <div className="form-group">
                      <label style={{ fontSize: '0.76rem', fontWeight: 600 }}>Amount Paid (₹) *</label>
                      <input type="number" className="auth-input" value={provAmount} onChange={(e) => setProvAmount(e.target.value)} required />
                    </div>
                    <div className="form-group">
                      <label style={{ fontSize: '0.76rem', fontWeight: 600 }}>Payment Reference / Notes</label>
                      <input type="text" className="auth-input" value={provNotes} onChange={(e) => setProvNotes(e.target.value)} />
                    </div>
                  </div>
                </div>
              </div>

              <div className="modal-footer" style={{ borderTop: '1px solid #E8E0E5', padding: '16px 24px', display: 'flex', justifyContent: 'center', gap: '12px' }}>
                <button type="button" className="btn btn-secondary" onClick={() => setProvisionModalOpen(false)}>Cancel</button>
                <button type="submit" className="btn btn-primary" style={{ background: '#16794B', borderColor: '#16794B', color: '#fff', fontWeight: 700 }}>
                  <i className="fa-solid fa-check" style={{ marginRight: '6px' }}></i> Create & Provision Account
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL 2: RENEW / UNBLOCK */}
      {renewModalUser && (
        <div className="modal-backdrop">
          <div className="modal-container admin-modal-card" style={{ maxWidth: '480px' }}>
            <div className="modal-header">
              <h3 style={{ margin: 0, fontSize: '1.15rem' }}>Renew / Unblock Subscription</h3>
              <button type="button" className="btn-modal-close" onClick={() => setRenewModalUser(null)}>
                <i className="fa-solid fa-xmark"></i>
              </button>
            </div>
            <form onSubmit={handleExecuteRenew}>
              <div className="modal-body" style={{ padding: '20px 24px' }}>
                <p style={{ fontSize: '0.85rem', color: '#493044', marginBottom: '14px' }}>
                  Renewing <strong>{renewModalUser.business_name}</strong> will reactivate bill scanning.
                </p>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
                  <div className="form-group">
                    <label style={{ fontSize: '0.78rem', fontWeight: 600 }}>New Start Date</label>
                    <input type="date" className="auth-input" value={renewStart} onChange={(e) => setRenewStart(e.target.value)} required />
                  </div>
                  <div className="form-group">
                    <label style={{ fontSize: '0.78rem', fontWeight: 600 }}>New End Date</label>
                    <input type="date" className="auth-input" value={renewEnd} onChange={(e) => setRenewEnd(e.target.value)} required />
                  </div>
                </div>
                <div className="form-group" style={{ marginBottom: '12px' }}>
                  <label style={{ fontSize: '0.78rem', fontWeight: 600 }}>Renewal Amount (₹)</label>
                  <input type="number" className="auth-input" value={renewAmount} onChange={(e) => setRenewAmount(e.target.value)} required />
                </div>
                <div className="form-group">
                  <label style={{ fontSize: '0.78rem', fontWeight: 600 }}>Payment Reference / Notes</label>
                  <input type="text" className="auth-input" value={renewNotes} onChange={(e) => setRenewNotes(e.target.value)} />
                </div>
              </div>
              <div className="modal-footer" style={{ borderTop: '1px solid #E8E0E5', padding: '16px 24px', display: 'flex', justifyContent: 'center', gap: '12px' }}>
                <button type="button" className="btn btn-secondary" onClick={() => setRenewModalUser(null)}>Cancel</button>
                <button type="submit" className="btn btn-primary" style={{ background: '#16794B', borderColor: '#16794B', color: '#fff' }}>
                  Confirm Renewal
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL 3: CREDENTIALS SHARE */}
      {credentialsModalData && (
        <div className="modal-backdrop">
          <div className="modal-container admin-modal-card" style={{ maxWidth: '480px' }}>
            <div className="modal-header">
              <h3 style={{ margin: 0, fontSize: '1.15rem' }}>Login Credentials Ready</h3>
              <button type="button" className="btn-modal-close" onClick={() => setCredentialsModalData(null)}>
                <i className="fa-solid fa-xmark"></i>
              </button>
            </div>
            <div className="modal-body" style={{ padding: '20px 24px' }}>
              <div style={{ background: '#F0FFF4', border: '1px solid #C6F6D5', padding: '16px', borderRadius: '8px', marginBottom: '16px' }}>
                <div style={{ fontSize: '0.85rem', fontWeight: 700, color: '#16794B', marginBottom: '6px' }}>
                  ACCOUNT PROVISIONED SUCCESSFULLY
                </div>
                <div style={{ fontSize: '0.82rem', color: '#276749' }}>
                  Send these credentials to <strong>{credentialsModalData.business_name}</strong> to begin using the mobile app:
                </div>
              </div>

              <div style={{ background: '#F7F2F4', padding: '12px', borderRadius: '8px', fontFamily: 'monospace', fontSize: '0.8rem', whiteSpace: 'pre-wrap', marginBottom: '16px' }}>
{`*BillBooks Account Activated*
Shop: ${credentialsModalData.business_name}
Email: ${credentialsModalData.email}
Password: ${credentialsModalData.password}
Subscription: ${credentialsModalData.start} to ${credentialsModalData.end}

Download & Login:
Open BillBooks mobile app on your Android device.`}
              </div>

              <button
                type="button"
                className="btn btn-primary"
                style={{ width: '100%', background: '#16794B', borderColor: '#16794B', color: '#fff', fontWeight: 700 }}
                onClick={() => {
                  const text = `*BillBooks Account Activated*\nShop: ${credentialsModalData.business_name}\nEmail: ${credentialsModalData.email}\nPassword: ${credentialsModalData.password}\nSubscription: ${credentialsModalData.start} to ${credentialsModalData.end}\n\nDownload & Login on your Android device.`;
                  navigator.clipboard.writeText(text);
                  if (onShowToast) onShowToast('Credentials copied to clipboard for WhatsApp/SMS!', 'success');
                }}
              >
                <i className="fa-solid fa-share-nodes" style={{ marginRight: '6px' }}></i> Copy WhatsApp Message
              </button>
            </div>
            <div className="modal-footer" style={{ borderTop: '1px solid #E8E0E5', padding: '14px 24px', display: 'flex', justifyContent: 'flex-end' }}>
              <button type="button" className="btn btn-secondary" onClick={() => setCredentialsModalData(null)}>Close</button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
