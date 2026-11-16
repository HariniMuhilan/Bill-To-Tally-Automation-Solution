import React, { useState } from 'react';

export default function BlockModal({ isOpen, onClose, user, onConfirmBlockToggle }) {
  const [reason, setReason] = useState('Suspicious activity / Policy breach');
  const [notes, setNotes] = useState('');

  if (!isOpen || !user) return null;

  const isBlocked = user.accountStatus === 'BLOCKED';

  function handleSubmit(e) {
    e.preventDefault();
    onConfirmBlockToggle({
      userId: user.id,
      blockAction: isBlocked ? 'UNBLOCK' : 'BLOCK',
      reason: isBlocked ? 'Account unblocked by administrator' : reason,
      notes: notes.trim()
    });
    onClose();
  }

  return (
    <div className="modal-backdrop">
      <div className="modal-container admin-modal-card" style={{ maxWidth: '480px' }}>
        <div className="modal-header" style={{ borderBottom: '1px solid #E8E0E5' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div 
              className="modal-icon-badge" 
              style={{ background: isBlocked ? '#E6F4EA' : '#2D1B28', color: isBlocked ? '#16794B' : '#FFFFFF' }}
            >
              <i className={`fa-solid ${isBlocked ? 'fa-lock-open' : 'fa-ban'}`}></i>
            </div>
            <div>
              <h3 style={{ margin: 0, fontSize: '1.15rem', color: '#111522' }}>
                {isBlocked ? 'Unblock User Account' : 'Block User Account'}
              </h3>
              <p style={{ margin: 0, fontSize: '0.82rem', color: '#80536F' }}>
                {user.shopName}
              </p>
            </div>
          </div>
          <button type="button" className="btn-modal-close" onClick={onClose}>
            <i className="fa-solid fa-xmark"></i>
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal-body" style={{ padding: '20px 24px' }}>
            {isBlocked ? (
              <div style={{ background: '#F0FFF4', padding: '14px', borderRadius: '8px', border: '1px solid #C6F6D5', marginBottom: '16px' }}>
                <div style={{ fontWeight: 600, color: '#22543D', fontSize: '0.9rem' }}>
                  Restore Access for {user.shopName}
                </div>
                <div style={{ fontSize: '0.82rem', color: '#276749', marginTop: '4px' }}>
                  This will lift the block and reactivate the user account, permitting sign-in if their payment is valid.
                </div>
              </div>
            ) : (
              <>
                <div style={{ background: '#FFF5F5', padding: '14px', borderRadius: '8px', border: '1px solid #FED7D7', marginBottom: '16px' }}>
                  <div style={{ fontWeight: 600, color: '#9B2C2C', fontSize: '0.9rem' }}>
                    <i className="fa-solid fa-triangle-exclamation" style={{ marginRight: '6px' }}></i>
                    High Priority Admin Action
                  </div>
                  <div style={{ fontSize: '0.82rem', color: '#742A2A', marginTop: '4px' }}>
                    Blocking this account will immediately revoke all access, terminate active sessions, and lock API usage for <strong>{user.shopName}</strong>.
                  </div>
                </div>

                <div className="form-group" style={{ marginBottom: '16px' }}>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, color: '#111522', marginBottom: '6px' }}>
                    Reason for Blocking *
                  </label>
                  <select
                    className="auth-input"
                    value={reason}
                    onChange={(e) => setReason(e.target.value)}
                    required
                  >
                    <option value="Suspicious activity / Policy breach">Suspicious activity / Policy breach</option>
                    <option value="Payment fraud / Repeated bounced payments">Payment fraud / Repeated bounced payments</option>
                    <option value="Abusive requests or data tampering">Abusive requests or data tampering</option>
                    <option value="Client requested temporary freeze">Client requested temporary freeze</option>
                    <option value="Legal or administrative dispute">Legal or administrative dispute</option>
                  </select>
                </div>
              </>
            )}

            <div className="form-group">
              <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, color: '#111522', marginBottom: '6px' }}>
                Administrator Notes
              </label>
              <textarea
                className="auth-input"
                rows="2"
                placeholder="Optional record for audit trail..."
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
              />
            </div>
          </div>

          <div className="modal-footer" style={{ borderTop: '1px solid #E8E0E5', padding: '16px 24px', display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
            <button type="button" className="btn btn-secondary" onClick={onClose}>
              Cancel
            </button>
            <button
              type="submit"
              className="btn btn-primary"
              style={{
                background: isBlocked ? '#16794B' : '#111522',
                borderColor: isBlocked ? '#16794B' : '#111522',
                color: '#fff',
                fontWeight: 600
              }}
            >
              <i className={`fa-solid ${isBlocked ? 'fa-lock-open' : 'fa-ban'}`} style={{ marginRight: '6px' }}></i>
              {isBlocked ? 'Confirm Unblock' : 'Confirm Block User'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

