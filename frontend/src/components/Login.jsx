import React, { useState } from 'react';

const DEFAULT_ACCOUNTS = [
  {
    username: 'accounts_user_01',
    password: 'tally@2026',
    fullName: 'Accounts User 01',
    role: 'Reviewer & Approver',
    initials: 'AU'
  },
  {
    username: 'admin',
    password: 'admin@2026',
    fullName: 'System Administrator',
    role: 'Administrator',
    initials: 'SA'
  },
  {
    username: 'operator',
    password: 'operator123',
    fullName: 'Data Entry Operator',
    role: 'Data Entry Operator',
    initials: 'OP'
  }
];

export default function Login({ onLoginSuccess }) {
  const [activeTab, setActiveTab] = useState('signin');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [loading, setLoading] = useState(false);

  // Sign In Form State
  const [signInUser, setSignInUser] = useState('');
  const [signInPass, setSignInPass] = useState('');
  const [rememberMe, setRememberMe] = useState(true);

  // Sign Up Form State
  const [signUpName, setSignUpName] = useState('');
  const [signUpUser, setSignUpUser] = useState('');
  const [signUpPass, setSignUpPass] = useState('');
  const [signUpConfirmPass, setSignUpConfirmPass] = useState('');

  function getStoredUsers() {
    try {
      const stored = localStorage.getItem('bill_to_tally_users');
      if (stored) {
        const parsed = JSON.parse(stored);
        if (Array.isArray(parsed) && parsed.length > 0) return parsed;
      }
    } catch (e) {}
    localStorage.setItem('bill_to_tally_users', JSON.stringify(DEFAULT_ACCOUNTS));
    return DEFAULT_ACCOUNTS;
  }

  function handleSignIn(e) {
    e.preventDefault();
    setErrorMsg('');

    const users = getStoredUsers();
    const match = users.find(
      u => u.username.toLowerCase() === signInUser.trim().toLowerCase() && u.password === signInPass
    );

    if (!match) {
      setErrorMsg('Invalid username or password. Please try again.');
      return;
    }

    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      onLoginSuccess(match, rememberMe);
    }, 600);
  }

  function handleSignUp(e) {
    e.preventDefault();
    setErrorMsg('');

    if (!signUpName.trim() || !signUpUser.trim() || !signUpPass) {
      setErrorMsg('Please fill out all required fields.');
      return;
    }

    if (signUpPass !== signUpConfirmPass) {
      setErrorMsg('Passwords do not match.');
      return;
    }

    const users = getStoredUsers();
    if (users.some(u => u.username.toLowerCase() === signUpUser.trim().toLowerCase())) {
      setErrorMsg(`Username "${signUpUser}" is already taken.`);
      return;
    }

    const nameParts = signUpName.trim().split(' ').filter(Boolean);
    const initials = nameParts.length >= 2
      ? (nameParts[0][0] + nameParts[nameParts.length - 1][0]).toUpperCase()
      : signUpName.trim().substring(0, 2).toUpperCase();

    const newUser = {
      username: signUpUser.trim(),
      password: signUpPass,
      fullName: signUpName.trim(),
      role: 'Reviewer & Approver',
      initials,
      createdAt: new Date().toISOString()
    };

    users.push(newUser);
    localStorage.setItem('bill_to_tally_users', JSON.stringify(users));

    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      onLoginSuccess(newUser, true);
    }, 600);
  }

  return (
    <div className="auth-page">
      <div className="auth-wrapper">
        <header className="auth-brand-header">
          <div className="auth-logo-badge">
            <i className="fa-solid fa-receipt"></i>
          </div>
          <div className="auth-brand-text">
            <h1>BILL TO TALLY</h1>
            <span>Ashan Tech Labs &bull; TallyPrime Voucher Automation Gateway</span>
          </div>
        </header>

        <main className="auth-layout-grid">
          <section className="auth-card" aria-label="Authentication Form">
            <div className="auth-tabs" role="tablist">
              <button 
                type="button" 
                className={`auth-tab-btn ${activeTab === 'signin' ? 'active' : ''}`}
                onClick={() => { setActiveTab('signin'); setErrorMsg(''); }}
              >
                <i className="fa-solid fa-arrow-right-to-bracket"></i>
                <span>Sign In</span>
              </button>
              <button 
                type="button" 
                className={`auth-tab-btn ${activeTab === 'signup' ? 'active' : ''}`}
                onClick={() => { setActiveTab('signup'); setErrorMsg(''); }}
              >
                <i className="fa-solid fa-user-plus"></i>
                <span>Create Account</span>
              </button>
            </div>

            {errorMsg && (
              <div style={{ margin: '16px 32px 0 32px', padding: '10px 14px', background: '#fee2e2', border: '1px solid #f87171', borderRadius: '8px', color: '#b91c1c', fontSize: '0.82rem', fontWeight: 600 }}>
                <i className="fa-solid fa-triangle-exclamation" style={{ marginRight: '8px' }}></i>
                {errorMsg}
              </div>
            )}

            {/* TAB 1: SIGN IN */}
            {activeTab === 'signin' && (
              <div className="auth-tab-pane active">
                <div className="auth-pane-header">
                  <h2>Welcome Back</h2>
                  <p>Sign in to access your purchase voucher inbox, OCR review, and TallyPrime connector.</p>
                </div>

                <form onSubmit={handleSignIn} autoComplete="on">
                  <div className="form-group">
                    <label htmlFor="signin-username">Username or ID</label>
                    <div className="input-icon-wrap">
                      <i className="fa-solid fa-user input-icon"></i>
                      <input 
                        type="text" 
                        id="signin-username" 
                        className="auth-input" 
                        placeholder="e.g. accounts_user_01" 
                        value={signInUser}
                        onChange={(e) => setSignInUser(e.target.value)}
                        required 
                        autoFocus
                      />
                    </div>
                  </div>

                  <div className="form-group">
                    <label htmlFor="signin-password">Password</label>
                    <div className="input-icon-wrap">
                      <i className="fa-solid fa-lock input-icon"></i>
                      <input 
                        type={showPassword ? 'text' : 'password'} 
                        id="signin-password" 
                        className="auth-input" 
                        placeholder="Enter your password" 
                        value={signInPass}
                        onChange={(e) => setSignInPass(e.target.value)}
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

                  <div className="auth-extras-row">
                    <label className="custom-checkbox">
                      <input 
                        type="checkbox" 
                        checked={rememberMe} 
                        onChange={(e) => setRememberMe(e.target.checked)} 
                      />
                      <span className="checkbox-mark"></span>
                      <span className="checkbox-label">Keep me logged in</span>
                    </label>
                  </div>

                  <button type="submit" className="btn btn-primary btn-auth-submit" disabled={loading}>
                    {loading ? (
                      <span><i className="fa-solid fa-circle-notch fa-spin"></i> Authenticating...</span>
                    ) : (
                      <span><i className="fa-solid fa-arrow-right-to-bracket"></i> Sign In to Bill-to-Tally</span>
                    )}
                  </button>
                </form>
              </div>
            )}

            {/* TAB 2: SIGN UP */}
            {activeTab === 'signup' && (
              <div className="auth-tab-pane active">
                <div className="auth-pane-header">
                  <h2>Create an Account</h2>
                  <p>Register a new account to begin processing bills and syncing vouchers to TallyPrime.</p>
                </div>

                <form onSubmit={handleSignUp} autoComplete="off">
                  <div className="form-group">
                    <label htmlFor="signup-name">Full Name</label>
                    <div className="input-icon-wrap">
                      <i className="fa-solid fa-id-card input-icon"></i>
                      <input 
                        type="text" 
                        id="signup-name" 
                        className="auth-input" 
                        placeholder="e.g. Harini Muhilan" 
                        value={signUpName}
                        onChange={(e) => setSignUpName(e.target.value)}
                        required 
                      />
                    </div>
                  </div>

                  <div className="form-group">
                    <label htmlFor="signup-username">Username</label>
                    <div className="input-icon-wrap">
                      <i className="fa-solid fa-at input-icon"></i>
                      <input 
                        type="text" 
                        id="signup-username" 
                        className="auth-input" 
                        placeholder="Choose a unique username" 
                        value={signUpUser}
                        onChange={(e) => setSignUpUser(e.target.value)}
                        required 
                      />
                    </div>
                  </div>

                  <div className="form-group">
                    <label htmlFor="signup-password">Password</label>
                    <div className="input-icon-wrap">
                      <i className="fa-solid fa-lock input-icon"></i>
                      <input 
                        type={showPassword ? 'text' : 'password'} 
                        id="signup-password" 
                        className="auth-input" 
                        placeholder="At least 6 characters" 
                        minLength={6}
                        value={signUpPass}
                        onChange={(e) => setSignUpPass(e.target.value)}
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

                  <div className="form-group">
                    <label htmlFor="signup-confirm-password">Confirm Password</label>
                    <div className="input-icon-wrap">
                      <i className="fa-solid fa-check-double input-icon"></i>
                      <input 
                        type={showConfirmPassword ? 'text' : 'password'} 
                        id="signup-confirm-password" 
                        className="auth-input" 
                        placeholder="Re-enter password" 
                        value={signUpConfirmPass}
                        onChange={(e) => setSignUpConfirmPass(e.target.value)}
                        required 
                      />
                      <button 
                        type="button" 
                        className="btn-toggle-password" 
                        onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                        title="Toggle password visibility"
                      >
                        <i className={showConfirmPassword ? 'fa-regular fa-eye-slash' : 'fa-regular fa-eye'}></i>
                      </button>
                    </div>
                  </div>

                  <button type="submit" className="btn btn-primary btn-auth-submit" disabled={loading}>
                    {loading ? (
                      <span><i className="fa-solid fa-circle-notch fa-spin"></i> Registering Account...</span>
                    ) : (
                      <span><i className="fa-solid fa-user-plus"></i> Create Account & Enter App</span>
                    )}
                  </button>
                </form>
              </div>
            )}
          </section>
        </main>

        <footer className="auth-footer">
          <span>Ashan Tech Labs &bull; Bill-to-Tally Automation Solution</span>
        </footer>
      </div>
    </div>
  );
}
