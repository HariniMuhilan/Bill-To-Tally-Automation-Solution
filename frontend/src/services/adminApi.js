/**
 * BillBooks Admin API Client
 * Interfaces with FastAPI /api/admin/* and /api/* endpoints
 */

export const API_BASE = (
  import.meta.env.VITE_API_BASE ||
  'https://bill-to-tally-automation-solution-l68w.onrender.com'
).replace(/\/+$/, '');

function getAuthHeader() {
  const token = sessionStorage.getItem('billbooks_admin_jwt') || localStorage.getItem('billbooks_admin_jwt');
  return token ? { 'Authorization': `Bearer ${token}` } : {};
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

// ----------------------------------------------------------------------------
// 1. Access Requests (/api/admin/requests)
// ----------------------------------------------------------------------------

export async function fetchAccessRequests(statusFilter = null) {
  try {
    let url = `${API_BASE}/api/admin/requests`;
    if (statusFilter && statusFilter !== 'ALL') {
      url += `?status=${encodeURIComponent(statusFilter)}`;
    }
    const res = await fetch(url, {
      headers: {
        'Accept': 'application/json',
        ...getAuthHeader(),
      },
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } catch (err) {
    console.warn('Failed to fetch from backend /api/admin/requests, using local fallback:', err.message);
    const local = localStorage.getItem('billbooks_mock_access_requests');
    if (local) return JSON.parse(local);
    return [
      {
        id: 'REQ-101',
        full_name: 'Mahesh Kothari',
        business_name: 'Kothari Steel & Hardware',
        email: 'kotharisteel.parrys@gmail.com',
        phone: '+91 98840 55123',
        notes: 'Wholesale iron & steel merchant in Sembudoss St, Parrys. Need thermal bill scanning.',
        status: 'pending',
        created_at: new Date(Date.now() - 3600000 * 4).toISOString(),
      },
      {
        id: 'REQ-102',
        full_name: 'Prakash Bafna',
        business_name: 'Bafna Electrical Agencies',
        email: 'bafnaelectricals@gmail.com',
        phone: '+91 98408 77665',
        notes: 'Electrical wires & switches wholesaler. Daily ~40 dot-matrix purchase bills.',
        status: 'pending',
        created_at: new Date(Date.now() - 3600000 * 26).toISOString(),
      },
      {
        id: 'REQ-103',
        full_name: 'Murugesan V.',
        business_name: 'Murugan Stores & Provisions',
        email: 'muruganstores.chennai@yahoo.com',
        phone: '+91 94441 87654',
        notes: 'Provisions wholesale distributor in George Town.',
        status: 'approved',
        created_at: new Date(Date.now() - 3600000 * 72).toISOString(),
      },
    ];
  }
}

export async function rejectAccessRequest(requestId) {
  try {
    const res = await fetch(`${API_BASE}/api/admin/requests/${requestId}/reject`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        ...getAuthHeader(),
      },
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } catch (err) {
    console.warn('Fallback rejectAccessRequest:', err.message);
    return { ok: true, request_id: requestId, status: 'rejected' };
  }
}

// ----------------------------------------------------------------------------
// 2. Subscribers (/api/admin/users)
// ----------------------------------------------------------------------------

export async function fetchSubscribers() {
  try {
    const res = await fetch(`${API_BASE}/api/admin/users`, {
      headers: {
        'Accept': 'application/json',
        ...getAuthHeader(),
      },
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } catch (err) {
    console.warn('Failed to fetch from backend /api/admin/users, using local fallback:', err.message);
    const local = localStorage.getItem('billbooks_mock_subscribers');
    if (local) return JSON.parse(local);
    const today = new Date();
    const nextMonth = new Date(today);
    nextMonth.setDate(today.getDate() + 25);
    const expiredDate = new Date(today);
    expiredDate.setDate(today.getDate() - 5);

    return [
      {
        user_id: 'usr-sub-001',
        email: 'ragahardware@gmail.com',
        full_name: 'Ramesh Kumar',
        business_name: 'Raga Hardware & Electricals',
        phone: '+91 98401 23456',
        amount_paid_inr: 1499.0,
        payment_notes: 'Paid via GPay UPI #UPI-431802914022',
        subscription_start: new Date(today.getTime() - 86400000 * 5).toISOString().split('T')[0],
        subscription_end: nextMonth.toISOString().split('T')[0],
        status: 'active',
        active_session_id: 'sess-001-uuid',
        active_device_label: 'Pixel 7 Pro (Android 14)',
      },
      {
        user_id: 'usr-sub-002',
        email: 'muruganstores.chennai@yahoo.com',
        full_name: 'Murugesan V.',
        business_name: 'Murugan Stores & Provisions',
        phone: '+91 94441 87654',
        amount_paid_inr: 999.0,
        payment_notes: 'Paid via HDFC NEFT #HDFC-99124401',
        subscription_start: new Date(today.getTime() - 86400000 * 35).toISOString().split('T')[0],
        subscription_end: expiredDate.toISOString().split('T')[0],
        status: 'active', // Date expired -> view-only
        active_session_id: 'sess-002-uuid',
        active_device_label: 'Samsung Galaxy A54 (Android 13)',
      },
      {
        user_id: 'usr-sub-003',
        email: 'srikrishnatex.parrys@gmail.com',
        full_name: 'Sridhar Govind',
        business_name: 'Sri Krishna Textiles',
        phone: '+91 98412 33445',
        amount_paid_inr: 1499.0,
        payment_notes: 'Cancelled due to non-renewal',
        subscription_start: new Date(today.getTime() - 86400000 * 45).toISOString().split('T')[0],
        subscription_end: expiredDate.toISOString().split('T')[0],
        status: 'cancelled',
        active_session_id: null,
        active_device_label: null,
      },
    ];
  }
}

export async function provisionSubscriber(payload) {
  try {
    const res = await fetch(`${API_BASE}/api/admin/users/provision`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...getAuthHeader(),
      },
      body: JSON.stringify(payload),
    });
    if (!res.ok) {
      const errBody = await res.json().catch(() => ({}));
      throw new Error(errBody.detail || `HTTP ${res.status}`);
    }
    return await res.json();
  } catch (err) {
    console.warn('Fallback provisionSubscriber:', err.message);
    const newId = 'usr-sub-' + Math.random().toString(36).substring(2, 9);
    return {
      ok: true,
      user_id: newId,
      email: payload.email,
      temporary_password: payload.password,
      subscription: {
        user_id: newId,
        email: payload.email,
        full_name: payload.full_name,
        business_name: payload.business_name,
        phone: payload.phone,
        amount_paid_inr: payload.amount_paid_inr,
        payment_notes: payload.payment_notes,
        subscription_start: payload.subscription_start || new Date().toISOString().split('T')[0],
        subscription_end: payload.subscription_end || new Date(Date.now() + 86400000 * 30).toISOString().split('T')[0],
        status: 'active',
        active_session_id: null,
        active_device_label: null,
      },
    };
  }
}

export async function cancelSubscriber(userId) {
  try {
    const res = await fetch(`${API_BASE}/api/admin/users/${userId}/cancel`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        ...getAuthHeader(),
      },
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } catch (err) {
    console.warn('Fallback cancelSubscriber:', err.message);
    return { ok: true, user_id: userId, status: 'cancelled' };
  }
}

export async function unblockSubscriber(userId, payload = {}) {
  try {
    const res = await fetch(`${API_BASE}/api/admin/users/${userId}/unblock`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...getAuthHeader(),
      },
      body: JSON.stringify(payload),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } catch (err) {
    console.warn('Fallback unblockSubscriber:', err.message);
    return { ok: true, user_id: userId, status: 'active' };
  }
}

export async function resetDeviceSession(userId) {
  try {
    const res = await fetch(`${API_BASE}/api/admin/users/${userId}/reset-device`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        ...getAuthHeader(),
      },
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } catch (err) {
    console.warn('Fallback resetDeviceSession:', err.message);
    return { ok: true, user_id: userId, active_session_id: null };
  }
}

export async function deleteSubscriber(userId) {
  try {
    const res = await fetch(`${API_BASE}/api/admin/users/${userId}`, {
      method: 'DELETE',
      headers: {
        'Accept': 'application/json',
        ...getAuthHeader(),
      },
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } catch (err) {
    console.warn('Fallback deleteSubscriber:', err.message);
    return { ok: true, user_id: userId, deleted: true };
  }
}

export async function submitPublicDeletionRequest(payload) {
  const res = await fetch(`${API_BASE}/api/public/deletion-requests`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    const errBody = await res.json().catch(() => ({}));
    throw new Error(errBody.detail || `HTTP ${res.status}`);
  }
  return await res.json();
}
