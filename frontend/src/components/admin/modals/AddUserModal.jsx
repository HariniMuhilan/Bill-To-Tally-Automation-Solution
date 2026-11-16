import React, { useState } from 'react';
import { generateCleanUsername, generateRandomPassword } from '../../../data/adminMockData';

export default function AddUserModal({ isOpen, onClose, onAddUser }) {
  const [shopName, setShopName] = useState('');
  const [ownerName, setOwnerName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [location, setLocation] = useState('Parrys Corner, Chennai');
  const [plan, setPlan] = useState('Pro Monthly');
  const [monthlyFee, setMonthlyFee] = useState(1499);
  const [paymentStatus, setPaymentStatus] = useState('PAID');
  const [autoApprove, setAutoApprove] = useState(true);
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [deadlineDate, setDeadlineDate] = useState('');

  if (!isOpen) return null;

  function handleShopNameChange(val) {
    setShopName(val);
    if (!username || username.startsWith('shop')) {
      setUsername(generateCleanUsername(val));
    }
  }

  function handlePlanChange(e) {
    const selectedPlan = e.target.value;
    setPlan(selectedPlan);
    if (selectedPlan === 'Starter Monthly') setMonthlyFee(999);
    else if (selectedPlan === 'Pro Monthly') setMonthlyFee(1499);
    else if (selectedPlan === 'Business Monthly') setMonthlyFee(2499);
  }

  function handleSubmit(e) {
    e.preventDefault();
    if (!shopName.trim() || !ownerName.trim()) {
      alert('Shop name and owner name are required.');
      return;
    }

    const defaultDeadline = new Date();
    defaultDeadline.setDate(defaultDeadline.getDate() + 30);
    const finalDeadline = deadlineDate || defaultDeadline.toISOString().split('T')[0];

    const newUser = {
      id: `USR-${Date.now().toString().slice(-4)}`,
      shopName: shopName.trim(),
      ownerName: ownerName.trim(),
      phone: phone.trim() || '+91 98400 00000',
      email: email.trim() || `${generateCleanUsername(shopName)}@gmail.com`,
      location: location.trim(),
      plan,
      monthlyFee: Number(monthlyFee),
      accountStatus: autoApprove && paymentStatus === 'PAID' ? 'APPROVED' : 'PENDING_APPROVAL',
      paymentStatus,
      paymentDeadline: finalDeadline,
      lastPaymentDate: paymentStatus === 'PAID' ? new Date().toISOString().split('T')[0] : null,
      lastPaymentMethod: paymentStatus === 'PAID' ? 'UPI (GPay)' : 'Pending',
      transactionRef: paymentStatus === 'PAID' ? `UPI-${Math.floor(100000000000 + Math.random() * 900000000000)}` : '',
      credentials: autoApprove && paymentStatus === 'PAID' ? {
        username: username.trim() || generateCleanUsername(shopName),
        password: password.trim() || generateRandomPassword('Shop'),
        issuedAt: new Date().toISOString(),
        active: true
      } : null,
      registrationDate: new Date().toISOString().split('T')[0],
      notes: 'Manually onboarded by Administrator.'
    };

    onAddUser(newUser);
    onClose();
  }

  return (
    <div className="modal-backdrop">
      <div className="modal-container admin-modal-card" style={{ maxWidth: '600px' }}>
        <div className="modal-header" style={{ borderBottom: '1px solid #E8E0E5' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div className="modal-icon-badge" style={{ background: '#F7F2F4', color: '#493044' }}>
              <i className="fa-solid fa-store"></i>
            </div>
            <div>
              <h3 style={{ margin: 0, fontSize: '1.15rem', color: '#111522' }}>
                Onboard New Shop / Client
              </h3>
              <p style={{ margin: 0, fontSize: '0.82rem', color: '#80536F' }}>
                Register business, configure monthly subscription & payment
              </p>
            </div>
          </div>
          <button type="button" className="btn-modal-close" onClick={onClose}>
            <i className="fa-solid fa-xmark"></i>
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal-body" style={{ padding: '20px 24px', maxHeight: '72vh', overflowY: 'auto' }}>
            
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '14px' }}>
              <div className="form-group">
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                  Shop / Business Name *
                </label>
                <input
                  type="text"
                  className="auth-input"
                  placeholder="e.g. Mahalakshmi Hardwares"
                  value={shopName}
                  onChange={(e) => handleShopNameChange(e.target.value)}
                  required
                />
              </div>

              <div className="form-group">
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                  Owner / Contact Name *
                </label>
                <input
                  type="text"
                  className="auth-input"
                  placeholder="e.g. S. Mahalingam"
                  value={ownerName}
                  onChange={(e) => setOwnerName(e.target.value)}
                  required
                />
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '14px' }}>
              <div className="form-group">
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                  Phone Number
                </label>
                <input
                  type="text"
                  className="auth-input"
                  placeholder="+91 98400 12345"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                />
              </div>

              <div className="form-group">
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                  Email Address
                </label>
                <input
                  type="email"
                  className="auth-input"
                  placeholder="shop@gmail.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                />
              </div>
            </div>

            <div className="form-group" style={{ marginBottom: '14px' }}>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                Location / Market Area
              </label>
              <input
                type="text"
                className="auth-input"
                placeholder="e.g. Nyniappa Naicken St, Parrys, Chennai"
                value={location}
                onChange={(e) => setLocation(e.target.value)}
              />
            </div>

            {/* Subscription & Monthly Billing Settings */}
            <div style={{ background: '#F7F2F4', padding: '14px', borderRadius: '8px', border: '1px solid #E8E0E5', marginBottom: '14px' }}>
              <div style={{ fontSize: '0.78rem', fontWeight: 700, color: '#493044', marginBottom: '10px' }}>
                MONTHLY SUBSCRIPTION & BILLING
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
                <div className="form-group">
                  <label style={{ display: 'block', fontSize: '0.78rem', fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                    Subscription Tier
                  </label>
                  <select className="auth-input" value={plan} onChange={handlePlanChange}>
                    <option value="Starter Monthly">Starter Monthly (₹999/mo)</option>
                    <option value="Pro Monthly">Pro Monthly (₹1,499/mo)</option>
                    <option value="Business Monthly">Business Monthly (₹2,499/mo)</option>
                  </select>
                </div>

                <div className="form-group">
                  <label style={{ display: 'block', fontSize: '0.78rem', fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                    Monthly Fee (₹)
                  </label>
                  <input
                    type="number"
                    className="auth-input"
                    value={monthlyFee}
                    onChange={(e) => setMonthlyFee(e.target.value)}
                    required
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div className="form-group">
                  <label style={{ display: 'block', fontSize: '0.78rem', fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                    Initial Payment Status
                  </label>
                  <select
                    className="auth-input"
                    value={paymentStatus}
                    onChange={(e) => setPaymentStatus(e.target.value)}
                  >
                    <option value="PAID">PAID (Payment Received)</option>
                    <option value="PENDING">PENDING (Awaiting Payment)</option>
                  </select>
                </div>

                <div className="form-group">
                  <label style={{ display: 'block', fontSize: '0.78rem', fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                    Monthly Payment Deadline
                  </label>
                  <input
                    type="date"
                    className="auth-input"
                    value={deadlineDate}
                    onChange={(e) => setDeadlineDate(e.target.value)}
                  />
                </div>
              </div>
            </div>

            {/* Login Credentials Grant Section */}
            {paymentStatus === 'PAID' && (
              <div style={{ background: '#F0FFF4', padding: '14px', borderRadius: '8px', border: '1px solid #C6F6D5' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                  <span style={{ fontSize: '0.78rem', fontWeight: 700, color: '#16794B' }}>
                    <i className="fa-solid fa-key" style={{ marginRight: '6px' }}></i>
                    ASSIGN LOGIN CREDENTIALS
                  </span>
                  <label style={{ fontSize: '0.78rem', color: '#16794B', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <input
                      type="checkbox"
                      checked={autoApprove}
                      onChange={(e) => setAutoApprove(e.target.checked)}
                    />
                    Approve & activate immediately
                  </label>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div className="form-group">
                    <label style={{ display: 'block', fontSize: '0.78rem', fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                      Login Username
                    </label>
                    <input
                      type="text"
                      className="auth-input"
                      placeholder="e.g. mahalakshmi"
                      value={username}
                      onChange={(e) => setUsername(e.target.value)}
                    />
                  </div>

                  <div className="form-group">
                    <label style={{ display: 'block', fontSize: '0.78rem', fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                      Login Password
                    </label>
                    <input
                      type="text"
                      className="auth-input"
                      placeholder="Auto or Custom password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                    />
                  </div>
                </div>
              </div>
            )}

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
              <i className="fa-solid fa-plus" style={{ marginRight: '6px' }}></i>
              Register & Save Shop Client
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

