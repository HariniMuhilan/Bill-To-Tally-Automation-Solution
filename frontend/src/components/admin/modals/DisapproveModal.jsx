import React, { useState } from 'react';

export default function DisapproveModal({ isOpen, onClose, user, onConfirmDisapprove }) {
  const [reason, setReason] = useState('Payment not received for monthly cycle');
  const [suspendCredentials, setSuspendCredentials] = useState(true);
  const [notes, setNotes] = useState('');

  if (!isOpen || !user) return null;

  function handleSubmit(e) {
    e.preventDefault();
    onConfirmDisapprove({
      userId: user.id,
      reason,
      suspendCredentials,
      notes: notes.trim()
    });
    onClose();
  }

  return (
    <div className="modal-backdrop">
      <div className="modal-container admin-modal-card" style={{ maxWidth: '500px' }}>
        <div className="modal-header" style={{ borderBottom: '1px solid #E8E0E5' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div className="modal-icon-badge" style={{ background: '#FEE2E2', color: '#B91C1C' }}>
              <i className="fa-solid fa-user-xmark"></i>
            </div>
            <div>
              <h3 style={{ margin: 0, fontSize: '1.15rem', color: '#111522' }}>Disapprove User Account</h3>
              <p style={{ margin: 0, fontSize: '0.82rem', color: '#80536F' }}>
                Payment verification failed or pending
              </p>
            </div>
          </div>
          <button type="button" className="btn-modal-close" onClick={onClose}>
            <i className="fa-solid fa-xmark"></i>
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal-body" style={{ padding: '20px 24px' }}>
            <div style={{ background: '#FFF5F5', padding: '12px 14px', borderRadius: '8px', border: '1px solid #FED7D7', marginBottom: '16px' }}>
              <div style={{ fontWeight: 600, color: '#9B2C2C', fontSize: '0.88rem' }}>
                Disapproving {user.shopName}
              </div>
              <div style={{ fontSize: '0.8rem', color: '#742A2A', marginTop: '4px' }}>
                Owner: {user.ownerName} &bull; Monthly Fee: ₹{user.monthlyFee}
              </div>
            </div>

            <div className="form-group" style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, color: '#111522', marginBottom: '6px' }}>
                Reason for Disapproval *
              </label>
              <select
                className="auth-input"
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                required
              >
                <option value="Payment not received for monthly cycle">Payment not received for monthly cycle</option>
                <option value="Invalid / Fake transaction UTR reference">Invalid / Fake transaction UTR reference</option>
                <option value="Cheque dishonoured / Bounced">Cheque dishonoured / Bounced</option>
                <option value="Incorrect shop documentation or identity">Incorrect shop documentation or identity</option>
                <option value="Subscription expired without renewal">Subscription expired without renewal</option>
                <option value="Other administrative grounds">Other administrative grounds</option>
              </select>
            </div>

            <div className="form-group" style={{ marginBottom: '16px' }}>
              <label className="admin-checkbox-label" style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
                <input
                  type="checkbox"
                  checked={suspendCredentials}
                  onChange={(e) => setSuspendCredentials(e.target.checked)}
                />
                <span style={{ fontSize: '0.85rem', fontWeight: 600, color: '#111522' }}>
                  Deactivate / Suspend client login access immediately
                </span>
              </label>
              <div style={{ fontSize: '0.76rem', color: '#80536F', marginTop: '4px', marginLeft: '24px' }}>
                Prevents the shop owner from uploading or scanning new bills until approved.
              </div>
            </div>

            <div className="form-group">
              <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, color: '#111522', marginBottom: '6px' }}>
                Internal Admin Notes (Optional)
              </label>
              <textarea
                className="auth-input"
                rows="3"
                placeholder="e.g. Called client on Nov 16, promised to pay via UPI by evening."
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
              style={{ background: '#B91C1C', borderColor: '#B91C1C', color: '#fff', fontWeight: 600 }}
            >
              <i className="fa-solid fa-user-xmark" style={{ marginRight: '6px' }}></i>
              Confirm Disapproval
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
