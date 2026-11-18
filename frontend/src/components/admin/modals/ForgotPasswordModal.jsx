import React, { useState } from 'react';

const SUPABASE_URL = (import.meta.env.VITE_SUPABASE_URL || 'https://fechwdczejepckkhbizm.supabase.co').replace(/\/+$/, '');
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || 'sb_publishable_JkKCUhgqkhXb20YR-r2ZMw_tBYq-77z';

export default function ForgotPasswordModal({ isOpen, onClose, onShowToast }) {
  const [emailInput, setEmailInput] = useState('admin@billbooks.app');
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  if (!isOpen) return null;

  async function handleSendResetEmail(e) {
    e.preventDefault();
    setErrorMsg('');
    setSuccessMsg('');
    const email = emailInput.trim().toLowerCase();
    if (!email || !email.includes('@')) {
      setErrorMsg('Please enter a valid administrator email address.');
      return;
    }

    setLoading(true);
    try {
      const res = await fetch(`${SUPABASE_URL}/auth/v1/recover`, {
        method: 'POST',
        headers: {
          apikey: SUPABASE_ANON_KEY,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email }),
      });

      if (!res.ok) {
        const errJson = await res.json().catch(() => ({}));
        throw new Error(errJson.msg || errJson.error_description || `HTTP ${res.status}`);
      }

      setSuccessMsg(
        `If ${email} has a live inbox, a Supabase password recovery email was sent. For system-managed accounts (such as admin@billbooks.app), reset the password in Supabase Dashboard -> Authentication -> Users.`
      );
      if (onShowToast) {
        onShowToast('Password recovery requested.', 'info');
      }
    } catch (err) {
      setErrorMsg(err.message || 'Could not initiate password recovery.');
    } finally {
      setLoading(false);
    }
  }

  function handleClose() {
    setErrorMsg('');
    setSuccessMsg('');
    onClose();
  }

  return (
    <div className="modal-backdrop">
      <div className="modal-container admin-modal-card" style={{ maxWidth: '480px' }}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div className="modal-icon-badge" style={{ background: '#F7F2F4', color: '#493044' }}>
              <i className="fa-solid fa-key"></i>
            </div>
            <div>
              <h3 style={{ margin: 0, fontSize: '1.15rem', color: '#111522' }}>Admin Password Recovery</h3>
              <p style={{ margin: 0, fontSize: '0.82rem', color: '#80536F' }}>
                Managed via Supabase Authentication
              </p>
            </div>
          </div>
          <button type="button" className="btn-modal-close" onClick={handleClose}>
            <i className="fa-solid fa-xmark"></i>
          </button>
        </div>

        <form onSubmit={handleSendResetEmail}>
          <div className="modal-body" style={{ padding: '24px' }}>
            {errorMsg && (
              <div className="admin-alert admin-alert-danger" style={{ marginBottom: '16px' }}>
                <i className="fa-solid fa-circle-exclamation"></i>
                <span>{errorMsg}</span>
              </div>
            )}

            {successMsg && (
              <div className="admin-alert admin-alert-success" style={{ marginBottom: '16px' }}>
                <i className="fa-solid fa-circle-check"></i>
                <span>{successMsg}</span>
              </div>
            )}

            <p style={{ fontSize: '0.88rem', color: '#493044', marginBottom: '16px' }}>
              Enter your administrator email address to trigger a Supabase password reset, or update the password directly in <strong>Supabase Dashboard &rarr; Authentication &rarr; Users</strong>.
            </p>

            <div className="form-group">
              <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, color: '#111522', marginBottom: '6px' }}>
                Administrator Email
              </label>
              <div className="input-icon-wrap">
                <i className="fa-solid fa-shield-halved input-icon"></i>
                <input
                  type="email"
                  className="auth-input"
                  placeholder="admin@billbooks.app"
                  value={emailInput}
                  onChange={(e) => setEmailInput(e.target.value)}
                  required
                  autoFocus
                />
              </div>
            </div>
          </div>

          <div className="modal-footer" style={{ borderTop: '1px solid #E8E0E5', padding: '14px 24px', display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
            <button type="button" className="btn btn-secondary" onClick={handleClose}>
              Close
            </button>
            <button
              type="submit"
              className="btn btn-primary"
              style={{ background: '#493044', borderColor: '#493044', color: '#fff', fontWeight: 700 }}
              disabled={loading}
            >
              {loading ? 'Sending...' : 'Send Recovery Email'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
