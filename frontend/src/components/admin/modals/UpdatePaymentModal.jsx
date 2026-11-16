import React, { useState, useEffect } from 'react';

export default function UpdatePaymentModal({ isOpen, onClose, user, onConfirmPaymentUpdate }) {
  const [paymentStatus, setPaymentStatus] = useState('PAID');
  const [amountPaid, setAmountPaid] = useState('');
  const [paymentDate, setPaymentDate] = useState('');
  const [paymentMethod, setPaymentMethod] = useState('UPI (GPay)');
  const [transactionRef, setTransactionRef] = useState('');
  const [deadlineDate, setDeadlineDate] = useState('');
  const [advanceDeadline, setAdvanceDeadline] = useState(true);
  const [notes, setNotes] = useState('');

  useEffect(() => {
    if (user) {
      setPaymentStatus(user.paymentStatus || 'PAID');
      setAmountPaid(user.monthlyFee || 1499);
      setPaymentDate(new Date().toISOString().split('T')[0]);
      setPaymentMethod(user.lastPaymentMethod && user.lastPaymentMethod !== 'Awaiting Payment' ? user.lastPaymentMethod : 'UPI (GPay)');
      setTransactionRef(user.transactionRef || `UPI-${Math.floor(100000000000 + Math.random() * 900000000000)}`);
      
      // Calculate next monthly deadline date (30 days from now)
      const nextMonth = new Date();
      nextMonth.setDate(nextMonth.getDate() + 30);
      setDeadlineDate(user.paymentDeadline || nextMonth.toISOString().split('T')[0]);
      setNotes(user.notes || '');
    }
  }, [user]);

  if (!isOpen || !user) return null;

  function handleSubmit(e) {
    e.preventDefault();

    let finalDeadline = deadlineDate;
    if (paymentStatus === 'PAID' && advanceDeadline) {
      // Calculate next monthly cycle deadline: current deadline + 1 month, or 30 days from paymentDate
      const baseDate = paymentDate ? new Date(paymentDate) : new Date();
      baseDate.setMonth(baseDate.getMonth() + 1);
      finalDeadline = baseDate.toISOString().split('T')[0];
    }

    onConfirmPaymentUpdate({
      userId: user.id,
      paymentStatus,
      amountPaid: Number(amountPaid) || user.monthlyFee,
      paymentDate: paymentStatus === 'PAID' ? paymentDate : user.lastPaymentDate,
      paymentMethod: paymentStatus === 'PAID' ? paymentMethod : user.lastPaymentMethod,
      transactionRef: paymentStatus === 'PAID' ? transactionRef.trim() : user.transactionRef,
      deadlineDate: finalDeadline,
      notes: notes.trim()
    });
    onClose();
  }

  return (
    <div className="modal-backdrop">
      <div className="modal-container admin-modal-card" style={{ maxWidth: '540px' }}>
        <div className="modal-header" style={{ borderBottom: '1px solid #E8E0E5' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div className="modal-icon-badge" style={{ background: '#FFF3E0', color: '#E65100' }}>
              <i className="fa-solid fa-file-invoice-dollar"></i>
            </div>
            <div>
              <h3 style={{ margin: 0, fontSize: '1.15rem', color: '#111522' }}>
                Update Payment Status Manually
              </h3>
              <p style={{ margin: 0, fontSize: '0.82rem', color: '#80536F' }}>
                {user.shopName} &bull; Monthly Fee: ₹{user.monthlyFee}
              </p>
            </div>
          </div>
          <button type="button" className="btn-modal-close" onClick={onClose}>
            <i className="fa-solid fa-xmark"></i>
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal-body" style={{ padding: '20px 24px', maxHeight: '72vh', overflowY: 'auto' }}>
            
            {/* Status Selector */}
            <div className="form-group" style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: '#111522', marginBottom: '6px' }}>
                Select Payment Status *
              </label>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '8px' }}>
                {[
                  { key: 'PAID', label: 'PAID', color: '#16794B', bg: '#E6F4EA' },
                  { key: 'PENDING', label: 'PENDING', color: '#B86E00', bg: '#FEF3C7' },
                  { key: 'OVERDUE', label: 'OVERDUE', color: '#B91C1C', bg: '#FEE2E2' },
                  { key: 'FAILED', label: 'FAILED', color: '#6B7280', bg: '#F3F4F6' }
                ].map(s => (
                  <button
                    key={s.key}
                    type="button"
                    onClick={() => setPaymentStatus(s.key)}
                    style={{
                      padding: '10px 4px',
                      borderRadius: '8px',
                      border: paymentStatus === s.key ? `2px solid ${s.color}` : '1px solid #E8E0E5',
                      background: paymentStatus === s.key ? s.bg : '#FFFFFF',
                      color: s.color,
                      fontWeight: 700,
                      fontSize: '0.78rem',
                      cursor: 'pointer',
                      textAlign: 'center',
                      transition: 'all 0.15s ease'
                    }}
                  >
                    <i className={
                      s.key === 'PAID' ? 'fa-solid fa-check-circle' :
                      s.key === 'PENDING' ? 'fa-solid fa-clock' :
                      s.key === 'OVERDUE' ? 'fa-solid fa-triangle-exclamation' : 'fa-solid fa-circle-xmark'
                    } style={{ display: 'block', marginBottom: '4px', fontSize: '1rem' }}></i>
                    {s.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Payment Details when marked PAID */}
            {paymentStatus === 'PAID' && (
              <div style={{ background: '#F7FDF9', padding: '16px', borderRadius: '10px', border: '1px solid #C6F6D5', marginBottom: '16px' }}>
                <div style={{ fontSize: '0.8rem', fontWeight: 700, color: '#16794B', marginBottom: '12px' }}>
                  <i className="fa-solid fa-receipt" style={{ marginRight: '6px' }}></i>
                  PAYMENT RECEIPT DETAILS
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
                  <div className="form-group">
                    <label style={{ display: 'block', fontSize: '0.78rem', fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                      Amount Received (₹) *
                    </label>
                    <input
                      type="number"
                      className="auth-input"
                      value={amountPaid}
                      onChange={(e) => setAmountPaid(e.target.value)}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label style={{ display: 'block', fontSize: '0.78rem', fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                      Payment Date *
                    </label>
                    <input
                      type="date"
                      className="auth-input"
                      value={paymentDate}
                      onChange={(e) => setPaymentDate(e.target.value)}
                      required
                    />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div className="form-group">
                    <label style={{ display: 'block', fontSize: '0.78rem', fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                      Payment Mode
                    </label>
                    <select
                      className="auth-input"
                      value={paymentMethod}
                      onChange={(e) => setPaymentMethod(e.target.value)}
                    >
                      <option value="UPI (GPay)">UPI (Google Pay)</option>
                      <option value="UPI (PhonePe)">UPI (PhonePe)</option>
                      <option value="UPI (Paytm / BHIM)">UPI (Paytm / BHIM)</option>
                      <option value="Bank Transfer (NEFT/IMPS)">Bank Transfer (NEFT/IMPS)</option>
                      <option value="Cash Payment">Cash Payment</option>
                      <option value="Credit / Debit Card">Credit / Debit Card</option>
                      <option value="Cheque">Cheque</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label style={{ display: 'block', fontSize: '0.78rem', fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                      Transaction / UTR No.
                    </label>
                    <input
                      type="text"
                      className="auth-input"
                      placeholder="e.g. 431802914022"
                      value={transactionRef}
                      onChange={(e) => setTransactionRef(e.target.value)}
                    />
                  </div>
                </div>

                {/* Monthly Cycle Advance Option */}
                <div style={{ marginTop: '12px', borderTop: '1px dashed #A7F3D0', paddingTop: '10px' }}>
                  <label className="admin-checkbox-label" style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
                    <input
                      type="checkbox"
                      checked={advanceDeadline}
                      onChange={(e) => setAdvanceDeadline(e.target.checked)}
                    />
                    <span style={{ fontSize: '0.82rem', fontWeight: 600, color: '#16794B' }}>
                      Automatically advance next monthly payment deadline (+30 days)
                    </span>
                  </label>
                </div>
              </div>
            )}

            {/* Monthly Payment Deadline Configuration */}
            <div style={{ background: '#F7F2F4', padding: '14px 16px', borderRadius: '10px', border: '1px solid #E8E0E5', marginBottom: '16px' }}>
              <div className="form-group">
                <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: '#111522', marginBottom: '6px' }}>
                  <i className="fa-regular fa-calendar-days" style={{ marginRight: '6px', color: '#493044' }}></i>
                  Monthly Payment Deadline Date
                </label>
                <input
                  type="date"
                  className="auth-input"
                  value={deadlineDate}
                  onChange={(e) => setDeadlineDate(e.target.value)}
                  required
                />
                <div style={{ fontSize: '0.76rem', color: '#80536F', marginTop: '4px' }}>
                  Tracks the monthly recurring billing cycle deadline. System flags overdue accounts automatically.
                </div>
              </div>
            </div>

            {/* Admin Notes */}
            <div className="form-group">
              <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, color: '#111522', marginBottom: '6px' }}>
                Payment Notes / Audit Remarks
              </label>
              <textarea
                className="auth-input"
                rows="2"
                placeholder="e.g. Manually reconciled against HDFC current account statement."
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
              style={{ background: '#493044', borderColor: '#493044', color: '#fff', fontWeight: 600 }}
            >
              <i className="fa-solid fa-floppy-disk" style={{ marginRight: '6px' }}></i>
              Save Payment Status & Deadline
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
