import React, { useState, useEffect } from 'react';
import AdminLogin from './components/admin/AdminLogin';
import AdminDashboard from './components/admin/AdminDashboard';
import Toast from './components/Toast';
import { getAdminSession, saveAdminSession, clearAdminSession, DEFAULT_ADMIN } from './data/adminMockData';

export default function App() {
  const [admin, setAdmin] = useState(() => getAdminSession());
  const [toasts, setToasts] = useState([]);

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
    showToast(`Welcome back, ${authenticatedAdmin.fullName}! Admin session started.`, 'success');
  }

  function handleLogout() {
    clearAdminSession();
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
        <AdminDashboard
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
