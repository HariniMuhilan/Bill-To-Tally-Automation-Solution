import React, { useState } from 'react';
import billbooksLogo from '../../assets/billbooks_logo.svg';
import { API_BASE, saveAdminToken, clearAdminToken } from '../../services/adminApi';
import ForgotPasswordModal from './modals/ForgotPasswordModal';

const SUPABASE_URL = (import.meta.env.VITE_SUPABASE_URL || 'https://fechwdczejepckkhbizm.supabase.co').replace(/\/+$/, '');
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || 'sb_publishable_JkKCUhgqkhXb20YR-r2ZMw_tBYq-77z';

export default function AdminLogin({ onLoginSuccess, onShowToast }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(true);
  const [errorMsg, setErrorMsg] = useState('');
  const [loading, setLoading] = useState(false);
  const [forgotModalOpen, setForgotModalOpen] = useState(false);

  async function handleLogin(e) {
    e.preventDefault();
    setErrorMsg('');
    const email = username.trim();

    if (!email || !password) {
      setErrorMsg('Please enter your administrator email and password.');
      return;
    }

    setLoading(true);

    try {
      // Authenticate directly with Supabase Auth REST API (no local dev bypass)
      const cleanEmail = email.includes('@') ? email.toLowerCase() : `${email.toLowerCase()}@billbooks.app`;
      const authRes = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
        method: 'POST',
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: cleanEmail,
          password: password,
        }),
      });

      if (!authRes.ok) {
        const errJson = await authRes.json().catch(() => ({}));
        const message = errJson.error_description || errJson.msg || 'Invalid administrator email or password.';
        setErrorMsg(message);
        setLoading(false);
        return;
      }

      const authData = await authRes.json();
      const accessToken = authData.access_token;
      saveAdminToken(accessToken, rememberMe);

      // 2. Verify admin privilege against FastAPI /api/admin/users
      const verifyRes = await fetch(`${API_BASE}/api/admin/users`, {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Accept': 'application/json',
        },
      });

      if (verifyRes.status === 403) {
        clearAdminToken();
        setErrorMsg('This account is authenticated, but is not authorized in ADMIN_EMAILS as an administrator.');
        setLoading(false);
        return;
      }

      if (!verifyRes.ok && verifyRes.status !== 200) {
        clearAdminToken();
        const errJson = await verifyRes.json().catch(() => ({}));
        setErrorMsg(errJson.detail || `Backend verification error (${verifyRes.status}). Check server status.`);
        setLoading(false);
        return;
      }

      // Authorized admin session confirmed
      setLoading(false);
      onLoginSuccess({
        email: authData.user?.email || email,
        fullName: authData.user?.user_metadata?.full_name || authData.user?.email?.split('@')[0] || 'Administrator',
      }, rememberMe);

    } catch (err) {
      clearAdminToken();
      setErrorMsg(`Authentication failed: ${err.message || 'Cannot reach server'}`);
      setLoading(false);
    }
  }

  return (
    <div className="auth-page admin-auth-page">
      <div className="auth-wrapper admin-auth-wrapper">
        <header className="auth-brand-header auth-brand-billbooks">
          <img 
            src={billbooksLogo} 
            alt="BillBooks Purchase Voucher Automation" 
            className="auth-billbooks-logo" 
          />
          <div className="admin-portal-badge">
            <i className="fa-solid fa-shield-halved"></i>
            <span>ADMINISTRATOR CONTROL PORTAL</span>
          </div>
        </header>

        <main className="auth-layout-grid admin-auth-grid">
          <section className="auth-card admin-auth-card" aria-label="Admin Authentication">
            <div className="admin-login-header">
              <div className="admin-shield-icon">
                <i className="fa-solid fa-lock"></i>
              </div>
              <h2>Admin Login</h2>
              <p>Sign in to manage client approvals, monthly subscriptions, payment deadlines, and login credentials.</p>
            </div>

            {errorMsg && (
              <div className="admin-alert admin-alert-danger" style={{ margin: '0 28px 16px 28px' }}>
                <i className="fa-solid fa-triangle-exclamation"></i>
                <span>{errorMsg}</span>
              </div>
            )}

            <form onSubmit={handleLogin} style={{ padding: '0 28px 28px 28px' }}>
              <div className="form-group" style={{ marginBottom: '18px' }}>
                <label htmlFor="admin-username" style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, color: '#111522', marginBottom: '6px' }}>
                  Admin Email
                </label>
                <div className="input-icon-wrap">
                  <i className="fa-solid fa-user-shield input-icon"></i>
                  <input
                    type="email"
                    id="admin-username"
                    className="auth-input"
                    placeholder="admin@billbooks.app"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    required
                    autoFocus
                  />
                </div>
              </div>

              <div className="form-group" style={{ marginBottom: '14px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                  <label htmlFor="admin-password" style={{ fontSize: '0.82rem', fontWeight: 600, color: '#111522' }}>
                    Password
                  </label>
                  <button
                    type="button"
                    className="btn-link-forgot"
                    onClick={() => setForgotModalOpen(true)}
                    style={{ background: 'none', border: 'none', color: '#FF9900', fontSize: '0.8rem', fontWeight: 600, cursor: 'pointer', padding: 0 }}
                  >
                    Forgot Password?
                  </button>
                </div>
                <div className="input-icon-wrap">
                  <i className="fa-solid fa-key input-icon"></i>
                  <input
                    type={showPassword ? 'text' : 'password'}
                    id="admin-password"
                    className="auth-input"
                    placeholder="Enter admin password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                  />
                  <button
                    type="button"
                    className="btn-toggle-password"
                    onClick={() => setShowPassword(!showPassword)}
                    title="Toggle password visibility"
                  >
                    <i className={showPassword ? 'fa-regular fa-eye-slash' : 'fa-regular fa-eye'}></i>
                  </button>
                </div>
              </div>

              <div className="auth-extras-row" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                <label className="custom-checkbox" style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
                  <input
                    type="checkbox"
                    checked={rememberMe}
                    onChange={(e) => setRememberMe(e.target.checked)}
                  />
                  <span className="checkbox-mark"></span>
                  <span className="checkbox-label" style={{ fontSize: '0.82rem', color: '#493044' }}>Keep admin session active</span>
                </label>
              </div>

              <button
                type="submit"
                className="btn btn-primary btn-auth-submit"
                style={{ width: '100%', background: '#493044', borderColor: '#493044', padding: '12px', fontSize: '0.92rem', fontWeight: 700 }}
                disabled={loading}
              >
                {loading ? (
                  <span><i className="fa-solid fa-circle-notch fa-spin"></i> Authenticating...</span>
                ) : (
                  <span><i className="fa-solid fa-arrow-right-to-bracket"></i> Login to Admin Dashboard</span>
                )}
              </button>
            </form>
          </section>
        </main>

        <footer className="auth-footer" style={{ marginTop: '20px', textAlign: 'center', fontSize: '0.78rem', color: '#80536F' }}>
          <span>Ashan Tech Labs &bull; BillBooks Multi-Tenant Admin & Subscription Engine</span>
        </footer>
      </div>

      <ForgotPasswordModal
        isOpen={forgotModalOpen}
        onClose={() => setForgotModalOpen(false)}
        onShowToast={onShowToast}
      />
    </div>
  );
}

