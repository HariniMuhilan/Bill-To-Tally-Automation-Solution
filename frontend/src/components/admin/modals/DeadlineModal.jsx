import React, { useState, useEffect } from 'react';

export default function DeadlineModal({ isOpen, onClose, user, onConfirmDeadlineChange }) {
  const [deadlineDate, setDeadlineDate] = useState('');
  const [reason, setReason] = useState('Standard monthly cycle');

  useEffect(() => {
    if (user && user.paymentDeadline) {
      setDeadlineDate(user.paymentDeadline);
    }
  }, [user]);

  if (!isOpen || !user) return null;

  function handleSubmit(e) {
    e.preventDefault();
    onConfirmDeadlineChange({
      userId: user.id,
      deadlineDate,
      reason
    });
    onClose();
  }

  function handleQuickAddDays(days) {
    const base = deadlineDate ? new Date(deadlineDate) : new Date();
    base.setDate(base.getDate() + days);
    setDeadlineDate(base.toISOString().split('T')[0]);
  }

  return (
    <div className="modal-backdrop">
      <div className="modal-container admin-modal-card" style={{ maxWidth: '480px' }}>
        <div className="modal-header" style={{ borderBottom: '1px solid #E8E0E5' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div className="modal-icon-badge" style={{ background: '#FFF3E0', color: '#B86E00' }}>
              <i className="fa-regular fa-clock"></i>
            </div>
            <div>
              <h3 style={{ margin: 0, fontSize: '1.15rem', color: '#111522' }}>
                Monthly Payment Deadline
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
            <div className="form-group" style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, color: '#111522', marginBottom: '6px' }}>
                Monthly Payment Deadline Date *
              </label>
              <input
                type="date"
                className="auth-input"
                value={deadlineDate}
                onChange={(e) => setDeadlineDate(e.target.value)}
                required
              />
            </div>

            {/* Quick Extension Buttons */}
            <div style={{ marginBottom: '16px' }}>
              <span style={{ display: 'block', fontSize: '0.78rem', color: '#80536F', fontWeight: 600, marginBottom: '6px' }}>
                Quick Adjustments:
              </span>
              <div style={{ display: 'flex', gap: '8px' }}>
                <button
                  type="button"
                  onClick={() => handleQuickAddDays(7)}
                  className="btn btn-sm btn-subtle"
                  style={{ flex: 1, fontSize: '0.75rem' }}
                >
                  +7 Days Grace
                </button>
                <button
                  type="button"
                  onClick={() => handleQuickAddDays(15)}
                  className="btn btn-sm btn-subtle"
                  style={{ flex: 1, fontSize: '0.75rem' }}
                >
                  +15 Days
                </button>
                <button
                  type="button"
                  onClick={() => handleQuickAddDays(30)}
                  className="btn btn-sm btn-subtle"
                  style={{ flex: 1, fontSize: '0.75rem' }}
                >
                  +1 Month
                </button>
              </div>
            </div>

            <div className="form-group">
              <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, color: '#111522', marginBottom: '6px' }}>
                Reason / Note for Deadline Adjustment
              </label>
              <input
                type="text"
                className="auth-input"
                placeholder="e.g. Granted 7-day grace period on client request"
                value={reason}
                onChange={(e) => setReason(e.target.value)}
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
              style={{ background: '#493044', borderColor: '#493044', color: '#fff', fontWeight: 600 }}
            >
              <i className="fa-solid fa-floppy-disk" style={{ marginRight: '6px' }}></i>
              Save Deadline
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
