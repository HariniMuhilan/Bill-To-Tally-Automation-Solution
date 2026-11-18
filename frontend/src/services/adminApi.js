/**
 * BillBooks Admin API Client
 * Interfaces with FastAPI /api/admin/* and /api/* endpoints (fail-closed; no silent mock fallbacks).
 */

export const API_BASE = (
  import.meta.env.VITE_API_BASE ||
  (typeof window !== 'undefined' &&
  (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
    ? 'http://127.0.0.1:8000'
    : 'https://bill-to-tally-automation-solution-l68w.onrender.com')
).replace(/\/+$/, '');

function getAuthHeader() {
  const token =
    sessionStorage.getItem('billbooks_admin_jwt') ||
    localStorage.getItem('billbooks_admin_jwt');
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export function saveAdminToken(token, remember = false) {
  sessionStorage.setItem('billbooks_admin_jwt', token);
  if (remember) {
    localStorage.setItem('billbooks_admin_jwt', token);
  }
}

export function clearAdminToken() {
  sessionStorage.removeItem('billbooks_admin_jwt');
  localStorage.removeItem('billbooks_admin_jwt');
}

async function adminRequest(path, options = {}) {
  const headers = {
    Accept: 'application/json',
    ...getAuthHeader(),
    ...(options.headers || {}),
  };

  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers,
  });

  if (!res.ok) {
    const errBody = await res.json().catch(() => ({}));
    const err = new Error(errBody.detail || `Server error (HTTP ${res.status})`);
    err.status = res.status;
    if (res.status === 401) {
      clearAdminToken();
    }
    throw err;
  }

  return res.json();
}

// ----------------------------------------------------------------------------
// 1. Access Requests (/api/admin/requests)
// ----------------------------------------------------------------------------

export async function fetchAccessRequests(statusFilter = null) {
  let path = '/api/admin/requests';
  if (statusFilter && statusFilter !== 'ALL') {
    path += `?status=${encodeURIComponent(statusFilter)}`;
  }
  return adminRequest(path);
}

export async function rejectAccessRequest(requestId) {
  return adminRequest(`/api/admin/requests/${encodeURIComponent(requestId)}/reject`, {
    method: 'POST',
  });
}

// ----------------------------------------------------------------------------
// 2. Subscribers (/api/admin/users)
// ----------------------------------------------------------------------------

export async function fetchSubscribers() {
  return adminRequest('/api/admin/users');
}

export async function provisionSubscriber(payload) {
  return adminRequest('/api/admin/users/provision', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
}

export async function cancelSubscriber(userId) {
  return adminRequest(`/api/admin/users/${encodeURIComponent(userId)}/cancel`, {
    method: 'POST',
  });
}

export async function unblockSubscriber(userId, payload = {}) {
  return adminRequest(`/api/admin/users/${encodeURIComponent(userId)}/unblock`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
}

export async function resetDeviceSession(userId) {
  return adminRequest(`/api/admin/users/${encodeURIComponent(userId)}/reset-device`, {
    method: 'POST',
  });
}

export async function deleteSubscriber(userId) {
  return adminRequest(`/api/admin/users/${encodeURIComponent(userId)}`, {
    method: 'DELETE',
  });
}

export async function submitPublicDeletionRequest(payload) {
  const res = await fetch(`${API_BASE}/api/public/deletion-requests`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    const errBody = await res.json().catch(() => ({}));
    throw new Error(errBody.detail || `HTTP ${res.status}`);
  }
  return res.json();
}
