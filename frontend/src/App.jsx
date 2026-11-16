import React, { useState, useEffect } from 'react';
import AdminLogin from './components/admin/AdminLogin';
import AdminDashboardView from './components/AdminDashboardView';
import Toast from './components/Toast';
import { getAdminSession, saveAdminSession, clearAdminSession } from './data/adminMockData';
import { clearAdminToken } from './services/adminApi';

export default function App() {
  const [admin, setAdmin] = useState(() => getAdminSession());
  const [toasts, setToasts] = useState([]);

  // Handle static compliance URL fallbacks
  useEffect(() => {
    const path = window.location.pathname;
    if (path === '/email-confirmed' || path === '/email-confirmed/') {
      window.location.replace('/email-confirmed/index.html');
    } else if (path === '/delete-account' || path === '/delete-account/') {
      window.location.replace('/delete-account/index.html');
    } else if (path === '/privacy-policy' || path === '/privacy-policy/') {
      window.location.replace('/privacy-policy/index.html');
    } else if (path === '/terms' || path === '/terms/') {
      window.location.replace('/terms/index.html');
    }
  }, []);

  function showToast(message, type = 'success') {
    const id = Date.now() + Math.random();
    setToasts(prev => [...prev, { id, message, type }]);
  }

  function removeToast(id) {
    setToasts(prev => prev.filter(t => t.id !== id));
  }

  function handleLoginSuccess(authenticatedAdmin, remember) {
    setAdmin(authenticatedAdmin);
    saveAdminSession(authenticatedAdmin, remember);
    showToast(`Welcome back, ${authenticatedAdmin.fullName}! Admin session active.`, 'success');
  }

  function handleLogout() {
    clearAdminSession();
    clearAdminToken();
    setAdmin(null);
    showToast('Administrator logged out successfully.', 'info');
  }

  return (
    <div className="admin-app-root">
      {!admin ? (
        <AdminLogin
          onLoginSuccess={handleLoginSuccess}
          onShowToast={showToast}
        />
      ) : (
        <AdminDashboardView
          admin={admin}
          onLogout={handleLogout}
          onShowToast={showToast}
        />
      )}

      {/* Floating Toast Feedback Notifications */}
      <div className="toast-container" id="toast-container">
        {toasts.map(t => (
          <Toast
            key={t.id}
            message={t.message}
            type={t.type}
            onClose={() => removeToast(t.id)}
          />
        ))}
      </div>
    </div>
  );
}

