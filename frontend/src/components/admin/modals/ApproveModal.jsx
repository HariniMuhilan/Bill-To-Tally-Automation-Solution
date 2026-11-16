import React, { useState, useEffect } from 'react';
import { generateCleanUsername, generateRandomPassword } from '../../../data/adminMockData';

export default function ApproveModal({ isOpen, onClose, user, onConfirmApprove }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [paymentVerified, setPaymentVerified] = useState(true);
  const [paymentMethod, setPaymentMethod] = useState('UPI (GPay)');
  const [transactionRef, setTransactionRef] = useState('');
  const [deadlineDate, setDeadlineDate] = useState('');
  const [notes, setNotes] = useState('');

  useEffect(() => {
    if (user) {
      const existingUser = user.credentials?.username || generateCleanUsername(user.shopName);
      const existingPass = user.credentials?.password || generateRandomPassword('Shop');
      setUsername(existingUser);
      setPassword(existingPass);
      setPaymentVerified(user.paymentStatus === 'PAID');
      setPaymentMethod(user.lastPaymentMethod && user.lastPaymentMethod !== 'Awaiting Payment' ? user.lastPaymentMethod : 'UPI (GPay)');
      setTransactionRef(user.transactionRef || `UPI-${Math.floor(100000000000 + Math.random() * 900000000000)}`);
      
      // Calculate default next monthly deadline (30 days from now or current)
      if (user.paymentDeadline) {
        setDeadlineDate(user.paymentDeadline);
      } else {
        const nextMonth = new Date();
        nextMonth.setDate(nextMonth.getDate() + 30);
        setDeadlineDate(nextMonth.toISOString().split('T')[0]);
      }
      setNotes(`Approved & verified by administrator on ${new Date().toLocaleDateString('en-IN')}`);
    }
  }, [user]);

  if (!isOpen || !user) return null;

  function handleSubmit(e) {
    e.preventDefault();
    if (!username.trim() || !password.trim()) {
      alert('Username and password are required to issue client credentials.');
      return;
    }

    onConfirmApprove({
      userId: user.id,
      username: username.trim(),
      password: password.trim(),
      paymentVerified,
      paymentMethod,
      transactionRef: transactionRef.trim(),
      deadlineDate,
      notes
    });
    onClose();
  }

  function handleRegeneratePassword() {
    setPassword(generateRandomPassword('Shop'));
  }

  return (
    <div className="modal-backdrop">
      <div className="modal-container admin-modal-card" style={{ maxWidth: '580px' }}>
        <div className="modal-header" style={{ borderBottom: '1px solid #E8E0E5' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div className="modal-icon-badge" style={{ background: '#E6F4EA', color: '#16794B' }}>
              <i className="fa-solid fa-user-check"></i>
            </div>
            <div>
              <h3 style={{ margin: 0, fontSize: '1.15rem', color: '#111522' }}>
                Approve User & Issue Login Credentials
              </h3>
              <p style={{ margin: 0, fontSize: '0.82rem', color: '#80536F' }}>
                {user.shopName} ({user.ownerName})
              </p>
            </div>
          </div>
          <button type="button" className="btn-modal-close" onClick={onClose}>
            <i className="fa-solid fa-xmark"></i>
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal-body" style={{ padding: '20px 24px', maxHeight: '72vh', overflowY: 'auto' }}>
            
            {/* Shop Summary Card */}
            <div style={{ background: '#F7F2F4', padding: '14px 16px', borderRadius: '10px', marginBottom: '18px', border: '1px solid #E8E0E5' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                <span style={{ fontSize: '0.78rem', fontWeight: 700, color: '#493044', letterSpacing: '0.5px' }}>CLIENT DETAILS</span>
                <span className="admin-pill pill-plan">{user.plan} (₹{user.monthlyFee}/mo)</span>
              </div>
              <div style={{ fontSize: '0.92rem', fontWeight: 600, color: '#111522' }}>{user.shopName}</div>
              <div style={{ fontSize: '0.82rem', color: '#80536F', marginTop: '2px' }}>
                <i className="fa-solid fa-phone" style={{ marginRight: '6px' }}></i>{user.phone} &bull; <i className="fa-solid fa-envelope" style={{ margin: '0 6px' }}></i>{user.email}
              </div>
            </div>

            {/* Step 1: Assign Login Credentials */}
            <div style={{ marginBottom: '20px' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '10px' }}>
                <h4 style={{ margin: 0, fontSize: '0.92rem', color: '#111522', fontWeight: 700 }}>
                  <i className="fa-solid fa-key" style={{ marginRight: '8px', color: '#FF9900' }}></i>
                  Client Login Credentials to Issue
                </h4>
                <button
                  type="button"
                  onClick={handleRegeneratePassword}
                  className="btn btn-sm btn-subtle"
                  style={{ fontSize: '0.75rem', padding: '4px 8px' }}
                >
                  <i className="fa-solid fa-arrows-rotate" style={{ marginRight: '4px' }}></i> Generate Strong Password
                </button>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div className="form-group">
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                    Login Username *
                  </label>
                  <input
                    type="text"
                    className="auth-input"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    required
                  />
                </div>

                <div className="form-group">
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                    Login Password *
                  </label>
                  <div className="input-icon-wrap">
                    <input
                      type={showPassword ? 'text' : 'password'}
                      className="auth-input"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      required
                    />
                    <button
                      type="button"
                      className="btn-toggle-password"
                      onClick={() => setShowPassword(!showPassword)}
                    >
                      <i className={showPassword ? 'fa-regular fa-eye-slash' : 'fa-regular fa-eye'}></i>
                    </button>
                  </div>
                </div>
              </div>
              <div style={{ fontSize: '0.76rem', color: '#80536F', marginTop: '6px' }}>
                <i className="fa-solid fa-circle-info"></i> The client will use these credentials to log in to their BillBooks purchase bill scanner app.
              </div>
            </div>

            {/* Step 2: Payment Confirmation */}
            <div style={{ borderTop: '1px solid #E8E0E5', paddingTop: '16px', marginBottom: '18px' }}>
              <h4 style={{ margin: '0 0 12px 0', fontSize: '0.92rem', color: '#111522', fontWeight: 700 }}>
                <i className="fa-solid fa-money-bill-wave" style={{ marginRight: '8px', color: '#16794B' }}></i>
                Payment Verification (Manual Confirmation)
              </h4>

              <div style={{ marginBottom: '12px' }}>
                <label className="admin-checkbox-label" style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
                  <input
                    type="checkbox"
                    checked={paymentVerified}
                    onChange={(e) => setPaymentVerified(e.target.checked)}
                  />
                  <span style={{ fontSize: '0.86rem', fontWeight: 600, color: '#111522' }}>
                    Monthly subscription payment of ₹{user.monthlyFee} has been received & verified
                  </span>
                </label>
              </div>

              {paymentVerified && (
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', background: '#FAFAFB', padding: '12px', borderRadius: '8px', border: '1px solid #E8E0E5' }}>
                  <div className="form-group">
                    <label style={{ display: 'block', fontSize: '0.78rem', fontWeight: 600, color: '#493044', marginBottom: '4px' }}>
                      Payment Method
                    </label>
                    <select
                      className="auth-input"
                      value={paymentMethod}
                      onChange={(e) => setPaymentMethod(e.target.value)}
                    >
                      <option value="UPI (GPay)">UPI (GPay / PhonePe / Paytm)</option>
                      <option value="Bank Transfer (NEFT/IMPS)">Bank Transfer (NEFT/IMPS)</option>
                      <option value="Cash Payment">Cash Payment</option>
                      <option value="Credit / Debit Card">Credit / Debit Card</option>
                      <option value="Cheque">Cheque</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label style={{ display: 'block', fontSize: '0.78rem', fontWeight: 600, color: '#493044', marginBottom: '4px' }}>
                      Transaction / UTR Reference
                    </label>
                    <input
                      type="text"
                      className="auth-input"
                      placeholder="e.g. UPI-98124981"
                      value={transactionRef}
                      onChange={(e) => setTransactionRef(e.target.value)}
                    />
                  </div>
                </div>
              )}
            </div>

            {/* Step 3: Monthly Payment Deadline */}
            <div style={{ borderTop: '1px solid #E8E0E5', paddingTop: '16px', marginBottom: '16px' }}>
              <div className="form-group">
                <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                  <i className="fa-regular fa-calendar-check" style={{ marginRight: '6px', color: '#493044' }}></i>
                  Monthly Payment Deadline Date *
                </label>
                <input
                  type="date"
                  className="auth-input"
                  value={deadlineDate}
                  onChange={(e) => setDeadlineDate(e.target.value)}
                  required
                />
                <div style={{ fontSize: '0.76rem', color: '#80536F', marginTop: '4px' }}>
                  The client must renew their monthly subscription before this deadline to maintain access.
                </div>
              </div>
            </div>

          </div>

          <div className="modal-footer" style={{ borderTop: '1px solid #E8E0E5', padding: '16px 24px', display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
            <button type="button" className="btn btn-secondary" onClick={onClose}>
              Cancel
            </button>
            <button
              type="submit"
              className="btn btn-primary"
              style={{ background: '#16794B', borderColor: '#16794B', color: '#fff', fontWeight: 600 }}
            >
              <i className="fa-solid fa-check" style={{ marginRight: '6px' }}></i>
              Confirm Approval & Issue Credentials
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

