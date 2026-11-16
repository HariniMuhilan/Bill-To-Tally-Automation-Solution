import React, { useState } from 'react';

export default function CredentialsModal({ isOpen, onClose, user, onShowToast }) {
  const [copied, setCopied] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  if (!isOpen || !user) return null;

  const creds = user.credentials;

  const shareText = `*BillBooks Purchase Voucher Automation*
*Account Credentials for ${user.shopName}*

👤 *Username:* ${creds?.username || 'Not assigned'}
🔑 *Password:* ${creds?.password || 'Not assigned'}
🏬 *Shop Name:* ${user.shopName}
🗓 *Monthly Plan:* ${user.plan} (₹${user.monthlyFee}/month)
⏰ *Payment Deadline:* ${user.paymentDeadline || 'N/A'}

📱 *Download & Login App:* https://billbooks.app
_Please change your password upon first login._`;

  function handleCopy() {
    navigator.clipboard.writeText(shareText);
    setCopied(true);
    if (onShowToast) {
      onShowToast(`Credentials for ${user.shopName} copied to clipboard!`, 'success');
    }
    setTimeout(() => setCopied(false), 2500);
  }

  return (
    <div className="modal-backdrop">
      <div className="modal-container admin-modal-card" style={{ maxWidth: '480px' }}>
        <div className="modal-header" style={{ borderBottom: '1px solid #E8E0E5' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div className="modal-icon-badge" style={{ background: '#F7F2F4', color: '#493044' }}>
              <i className="fa-solid fa-id-badge"></i>
            </div>
            <div>
              <h3 style={{ margin: 0, fontSize: '1.15rem', color: '#111522' }}>
                Client Login Credentials
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

        <div className="modal-body" style={{ padding: '20px 24px' }}>
          {creds ? (
            <>
              {/* Credentials Box */}
              <div style={{ background: '#FDFBFC', border: '1px solid #E8E0E5', borderRadius: '10px', padding: '16px', marginBottom: '16px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px', paddingBottom: '8px', borderBottom: '1px solid #F0E8EC' }}>
                  <span style={{ fontSize: '0.78rem', fontWeight: 700, color: '#80536F' }}>LOGIN CREDENTIALS</span>
                  <span className={`admin-pill ${user.accountStatus === 'APPROVED' ? 'pill-approved' : 'pill-disapproved'}`}>
                    {user.accountStatus === 'APPROVED' ? 'Active Access' : 'Suspended'}
                  </span>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '10px' }}>
                  <div>
                    <span style={{ display: 'block', fontSize: '0.75rem', color: '#80536F', fontWeight: 600 }}>Username</span>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', background: '#FFFFFF', border: '1px solid #E8E0E5', borderRadius: '6px', padding: '8px 12px', marginTop: '3px' }}>
                      <span style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: '0.92rem', fontWeight: 700, color: '#111522' }}>
                        {creds.username}
                      </span>
                      <button
                        type="button"
                        onClick={() => {
                          navigator.clipboard.writeText(creds.username);
                          if (onShowToast) onShowToast('Username copied!', 'info');
                        }}
                        className="btn btn-sm btn-subtle"
                        style={{ padding: '2px 8px', fontSize: '0.75rem' }}
                      >
                        <i className="fa-regular fa-copy"></i>
                      </button>
                    </div>
                  </div>

                  <div>
                    <span style={{ display: 'block', fontSize: '0.75rem', color: '#80536F', fontWeight: 600 }}>Password</span>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', background: '#FFFFFF', border: '1px solid #E8E0E5', borderRadius: '6px', padding: '8px 12px', marginTop: '3px' }}>
                      <span style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: '0.92rem', fontWeight: 700, color: '#111522' }}>
                        {showPassword ? creds.password : '••••••••••••'}
                      </span>
                      <div style={{ display: 'flex', gap: '6px' }}>
                        <button
                          type="button"
                          onClick={() => setShowPassword(!showPassword)}
                          className="btn btn-sm btn-subtle"
                          style={{ padding: '2px 8px', fontSize: '0.75rem' }}
                        >
                          <i className={showPassword ? 'fa-regular fa-eye-slash' : 'fa-regular fa-eye'}></i>
                        </button>
                        <button
                          type="button"
                          onClick={() => {
                            navigator.clipboard.writeText(creds.password);
                            if (onShowToast) onShowToast('Password copied!', 'info');
                          }}
                          className="btn btn-sm btn-subtle"
                          style={{ padding: '2px 8px', fontSize: '0.75rem' }}
                        >
                          <i className="fa-regular fa-copy"></i>
                        </button>
                      </div>
                    </div>
                  </div>
                </div>

                <div style={{ marginTop: '12px', fontSize: '0.75rem', color: '#80536F' }}>
                  Issued: {creds.issuedAt ? new Date(creds.issuedAt).toLocaleString('en-IN') : 'N/A'}
                </div>
              </div>

              {/* Share Template Preview */}
              <div style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#111522', marginBottom: '6px' }}>
                  WhatsApp / SMS Message Template
                </label>
                <div style={{ background: '#F7F2F4', padding: '12px', borderRadius: '8px', border: '1px solid #E8E0E5', fontSize: '0.78rem', color: '#493044', whiteSpace: 'pre-wrap', maxHeight: '140px', overflowY: 'auto', fontFamily: 'monospace' }}>
                  {shareText}
                </div>
              </div>
            </>
          ) : (
            <div style={{ textAlign: 'center', padding: '24px 12px', color: '#80536F' }}>
              <i className="fa-solid fa-lock" style={{ fontSize: '2rem', color: '#B86E00', marginBottom: '10px', display: 'block' }}></i>
              <div style={{ fontWeight: 600, color: '#111522', marginBottom: '4px' }}>
                Credentials Not Yet Issued
              </div>
              <p style={{ fontSize: '0.82rem', margin: 0 }}>
                This user is awaiting payment verification. Approve the account to issue login credentials.
              </p>
            </div>
          )}
        </div>

        <div className="modal-footer" style={{ borderTop: '1px solid #E8E0E5', padding: '16px 24px', display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
          <button type="button" className="btn btn-secondary" onClick={onClose}>
            Close
          </button>
          {creds && (
            <button
              type="button"
              className="btn btn-primary"
              onClick={handleCopy}
              style={{ background: '#16794B', borderColor: '#16794B', color: '#fff', fontWeight: 600 }}
            >
              <i className={copied ? 'fa-solid fa-check' : 'fa-solid fa-share-nodes'} style={{ marginRight: '6px' }}></i>
              {copied ? 'Copied to Clipboard!' : 'Copy WhatsApp / SMS Message'}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

