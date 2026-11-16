import React, { useState } from 'react';
import billbooksLogo from '../../assets/billbooks_logo.svg';
import { getAdminCredentials } from '../../data/adminMockData';
import ForgotPasswordModal from './modals/ForgotPasswordModal';

export default function AdminLogin({ onLoginSuccess, onShowToast }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(true);
  const [errorMsg, setErrorMsg] = useState('');
  const [loading, setLoading] = useState(false);
  const [forgotModalOpen, setForgotModalOpen] = useState(false);

  function handleLogin(e) {
    e.preventDefault();
    setErrorMsg('');

    const creds = getAdminCredentials();
    const enteredUser = username.trim().toLowerCase();
    const isUserMatch = enteredUser === creds.username.toLowerCase() || enteredUser === creds.email.toLowerCase();
    const isPassMatch = password === creds.password;

    if (!isUserMatch || !isPassMatch) {
      setErrorMsg('Invalid administrator credentials. Please check your username and password.');
      return;
    }

    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      onLoginSuccess(creds, rememberMe);
    }, 450);
  }

  function handleDemoLogin() {
    setUsername('admin');
    setPassword('admin@2026');
    setErrorMsg('');
    setLoading(true);
    const creds = getAdminCredentials();
    setTimeout(() => {
      setLoading(false);
      onLoginSuccess(creds, true);
    }, 400);
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
                  Admin Username or Email
                </label>
                <div className="input-icon-wrap">
                  <i className="fa-solid fa-user-shield input-icon"></i>
                  <input
                    type="text"
                    id="admin-username"
                    className="auth-input"
                    placeholder="e.g. admin or admin@billbooks.app"
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

              <div style={{ textAlign: 'center', margin: '16px 0 10px 0', position: 'relative' }}>
                <span style={{ background: '#FFFFFF', padding: '0 10px', fontSize: '0.78rem', color: '#80536F', position: 'relative', zIndex: 1 }}>
                  OR QUICK ACCESS
                </span>
                <div style={{ position: 'absolute', top: '50%', left: 0, right: 0, height: '1px', background: '#E8E0E5' }}></div>
              </div>

              <button
                type="button"
                className="btn btn-secondary"
                onClick={handleDemoLogin}
                style={{ width: '100%', padding: '10px', fontSize: '0.85rem', fontWeight: 600, background: '#F7F2F4', border: '1px solid #E8E0E5', color: '#493044' }}
              >
                <i className="fa-solid fa-bolt" style={{ color: '#FF9900', marginRight: '6px' }}></i>
                Quick Demo Admin Login (<code>admin / admin@2026</code>)
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

