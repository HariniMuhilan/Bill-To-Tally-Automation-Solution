import React, { useState } from 'react';
import { getAdminCredentials, saveAdminCredentials } from '../../../data/adminMockData';

export default function ForgotPasswordModal({ isOpen, onClose, onShowToast }) {
  const [step, setStep] = useState(1); // 1: identify, 2: security answer / PIN, 3: set new password
  const [usernameInput, setUsernameInput] = useState('');
  const [pinInput, setPinInput] = useState('');
  const [answerInput, setAnswerInput] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [errorMsg, setErrorMsg] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  if (!isOpen) return null;

  const currentAdmin = getAdminCredentials();

  function handleVerifyIdentity(e) {
    e.preventDefault();
    setErrorMsg('');
    const input = usernameInput.trim().toLowerCase();
    if (input === currentAdmin.username.toLowerCase() || input === currentAdmin.email.toLowerCase()) {
      setStep(2);
    } else {
      setErrorMsg('No administrator account found with that username or email.');
    }
  }

  function handleVerifySecurity(e) {
    e.preventDefault();
    setErrorMsg('');
    const enteredPin = pinInput.trim();
    const enteredAns = answerInput.trim().toLowerCase();

    const pinMatches = enteredPin && enteredPin === currentAdmin.securityPin;
    const ansMatches = enteredAns && enteredAns === currentAdmin.securityAnswer.toLowerCase();

    if (pinMatches || ansMatches) {
      setStep(3);
    } else {
      setErrorMsg('Invalid Security PIN or answer. Please check and try again.');
    }
  }

  function handleResetPassword(e) {
    e.preventDefault();
    setErrorMsg('');
    if (!newPassword || newPassword.length < 6) {
      setErrorMsg('Password must be at least 6 characters long.');
      return;
    }
    if (newPassword !== confirmPassword) {
      setErrorMsg('Passwords do not match.');
      return;
    }

    const updated = {
      ...currentAdmin,
      password: newPassword
    };
    saveAdminCredentials(updated);
    setSuccessMsg('Admin password updated successfully! You can now log in with your new credentials.');
    if (onShowToast) {
      onShowToast('Admin password reset successfully!', 'success');
    }
    setTimeout(() => {
      onClose();
      setStep(1);
      setSuccessMsg('');
      setUsernameInput('');
      setPinInput('');
      setAnswerInput('');
      setNewPassword('');
      setConfirmPassword('');
    }, 1600);
  }

  return (
    <div className="modal-backdrop">
      <div className="modal-container admin-modal-card" style={{ maxWidth: '520px' }}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div className="modal-icon-badge" style={{ background: '#F7F2F4', color: '#493044' }}>
              <i className="fa-solid fa-key"></i>
            </div>
            <div>
              <h3 style={{ margin: 0, fontSize: '1.15rem', color: '#111522' }}>Admin Password Recovery</h3>
              <p style={{ margin: 0, fontSize: '0.82rem', color: '#80536F' }}>
                Secure multi-factor reset for system administrator
              </p>
            </div>
          </div>
          <button 
            type="button" 
            className="btn-modal-close" 
            onClick={() => { onClose(); setStep(1); setErrorMsg(''); }}
          >
            <i className="fa-solid fa-xmark"></i>
          </button>
        </div>

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

          {/* STEP 1: Identify Account */}
          {step === 1 && !successMsg && (
            <form onSubmit={handleVerifyIdentity}>
              <p style={{ fontSize: '0.9rem', color: '#493044', marginBottom: '16px' }}>
                Enter your registered administrator username or official email address to initiate password recovery.
              </p>
              <div className="form-group" style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, color: '#111522', marginBottom: '6px' }}>
                  Admin Username or Email
                </label>
                <div className="input-icon-wrap">
                  <i className="fa-solid fa-shield-halved input-icon"></i>
                  <input
                    type="text"
                    className="auth-input"
                    placeholder="e.g. admin or admin@billbooks.app"
                    value={usernameInput}
                    onChange={(e) => setUsernameInput(e.target.value)}
                    required
                    autoFocus
                  />
                </div>
                <div style={{ marginTop: '8px', fontSize: '0.78rem', color: '#80536F' }}>
                  <i className="fa-solid fa-circle-info"></i> Default system username is <code>admin</code>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '20px' }}>
                <button 
                  type="button" 
                  className="btn btn-secondary" 
                  onClick={() => { onClose(); setErrorMsg(''); }}
                >
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" style={{ background: '#493044', color: '#fff' }}>
                  Next Step <i className="fa-solid fa-arrow-right" style={{ marginLeft: '6px' }}></i>
                </button>
              </div>
            </form>
          )}

          {/* STEP 2: Verify Security PIN or Question */}
          {step === 2 && !successMsg && (
            <form onSubmit={handleVerifySecurity}>
              <div className="admin-security-banner" style={{ background: '#F7F2F4', padding: '12px 16px', borderRadius: '8px', marginBottom: '16px', border: '1px solid #E8E0E5' }}>
                <div style={{ fontSize: '0.8rem', color: '#80536F', fontWeight: 600 }}>SECURITY VERIFICATION</div>
                <div style={{ fontSize: '0.88rem', color: '#111522', marginTop: '4px' }}>
                  Enter the 6-digit Master PIN or answer the security question configured for <strong>{currentAdmin.username}</strong>.
                </div>
              </div>

              <div className="form-group" style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, color: '#111522', marginBottom: '6px' }}>
                  Master Security PIN (6 digits)
                </label>
                <input
                  type="password"
                  className="auth-input"
                  placeholder="Enter 6-digit PIN (default: 202699)"
                  value={pinInput}
                  onChange={(e) => setPinInput(e.target.value)}
                  maxLength={6}
                />
                <div style={{ marginTop: '6px', fontSize: '0.76rem', color: '#80536F' }}>
                  Default Master PIN: <code>202699</code>
                </div>
              </div>

              <div style={{ textAlign: 'center', margin: '12px 0', color: '#80536F', fontSize: '0.8rem', fontWeight: 600 }}>
                — OR ANSWER SECURITY QUESTION —
              </div>

              <div className="form-group" style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, color: '#111522', marginBottom: '6px' }}>
                  Question: {currentAdmin.securityQuestion}
                </label>
                <input
                  type="text"
                  className="auth-input"
                  placeholder="e.g. Parrys Corner"
                  value={answerInput}
                  onChange={(e) => setAnswerInput(e.target.value)}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '20px' }}>
                <button 
                  type="button" 
                  className="btn btn-secondary" 
                  onClick={() => { setStep(1); setErrorMsg(''); }}
                >
                  <i className="fa-solid fa-arrow-left" style={{ marginRight: '6px' }}></i> Back
                </button>
                <button type="submit" className="btn btn-primary" style={{ background: '#493044', color: '#fff' }}>
                  Verify & Proceed <i className="fa-solid fa-check" style={{ marginLeft: '6px' }}></i>
                </button>
              </div>
            </form>
          )}

          {/* STEP 3: Set New Password */}
          {step === 3 && !successMsg && (
            <form onSubmit={handleResetPassword}>
              <p style={{ fontSize: '0.9rem', color: '#493044', marginBottom: '16px' }}>
                Create a strong new password for the administrator account.
              </p>

              <div className="form-group" style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, color: '#111522', marginBottom: '6px' }}>
                  New Password
                </label>
                <input
                  type="password"
                  className="auth-input"
                  placeholder="Enter at least 6 characters"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  required
                  autoFocus
                />
              </div>

              <div className="form-group" style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, color: '#111522', marginBottom: '6px' }}>
                  Confirm New Password
                </label>
                <input
                  type="password"
                  className="auth-input"
                  placeholder="Re-enter new password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  required
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '20px' }}>
                <button 
                  type="button" 
                  className="btn btn-secondary" 
                  onClick={() => { onClose(); setErrorMsg(''); }}
                >
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" style={{ background: '#16794B', color: '#fff', border: 'none' }}>
                  <i className="fa-solid fa-floppy-disk" style={{ marginRight: '6px' }}></i> Save & Update Password
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}
