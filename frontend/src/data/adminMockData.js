/**
 * BillBooks Admin Portal - Session & Helper Utilities
 * Ashan Tech Labs
 */

export const INITIAL_CLIENT_USERS = [
  {
    id: 'USR-101',
    shopName: 'Raga Hardware & Electricals',
    ownerName: 'Ramesh Kumar',
    phone: '+91 98401 23456',
    email: 'ragahardware@gmail.com',
    location: 'Nyniappa Naicken St, Parrys, Chennai',
    plan: 'Pro Monthly',
    monthlyFee: 1499,
    accountStatus: 'APPROVED', // APPROVED | PENDING_APPROVAL | DISAPPROVED | BLOCKED
    paymentStatus: 'PAID',     // PAID | PENDING | OVERDUE | FAILED
    paymentDeadline: '2026-12-10', // YYYY-MM-DD
    lastPaymentDate: '2026-11-10',
    lastPaymentMethod: 'UPI (GPay)',
    transactionRef: 'UPI-431802914022',
    credentials: {
      username: 'ragahardware',
      password: 'Raga@Parrys2026',
      issuedAt: '2026-11-10T10:30:00Z',
      active: true
    },
    registrationDate: '2026-10-15',
    notes: 'Payment received on time via GPay. Verified by Admin.'
  },
  {
    id: 'USR-102',
    shopName: 'Kothari Steel & Hardware',
    ownerName: 'Mahesh Kothari',
    phone: '+91 98840 55123',
    email: 'kotharisteel.parrys@gmail.com',
    location: 'Sembudoss St, Parrys, Chennai',
    plan: 'Business Monthly',
    monthlyFee: 2499,
    accountStatus: 'PENDING_APPROVAL',
    paymentStatus: 'PENDING',
    paymentDeadline: '2026-11-20',
    lastPaymentDate: null,
    lastPaymentMethod: 'Awaiting Payment',
    transactionRef: '',
    credentials: null,
    registrationDate: '2026-11-14',
    notes: 'New registration. Waiting for UPI confirmation before issuing login credentials.'
  },
  {
    id: 'USR-103',
    shopName: 'Murugan Stores & Provisions',
    ownerName: 'Murugesan V.',
    phone: '+91 94441 87654',
    email: 'muruganstores.chennai@yahoo.com',
    location: 'Govindappa Naicken St, George Town, Chennai',
    plan: 'Starter Monthly',
    monthlyFee: 999,
    accountStatus: 'APPROVED',
    paymentStatus: 'PAID',
    paymentDeadline: '2026-12-05',
    lastPaymentDate: '2026-11-05',
    lastPaymentMethod: 'Bank Transfer (NEFT)',
    transactionRef: 'NEFT-HDFC-99124401',
    credentials: {
      username: 'muruganstores',
      password: 'Murugan@2026',
      issuedAt: '2026-11-05T14:15:00Z',
      active: true
    },
    registrationDate: '2026-09-01',
    notes: 'Monthly subscription regular. Continuous Tally sync enabled.'
  },
  {
    id: 'USR-104',
    shopName: 'Sri Krishna Textiles',
    ownerName: 'Sridhar Govind',
    phone: '+91 98412 33445',
    email: 'srikrishnatex.parrys@gmail.com',
    location: 'Godown St, Parrys, Chennai',
    plan: 'Pro Monthly',
    monthlyFee: 1499,
    accountStatus: 'DISAPPROVED',
    paymentStatus: 'OVERDUE',
    paymentDeadline: '2026-11-08',
    lastPaymentDate: '2026-10-08',
    lastPaymentMethod: 'Unpaid',
    transactionRef: '',
    credentials: {
      username: 'srikrishnatex',
      password: 'Tex@Parrys2026',
      issuedAt: '2026-10-08T11:00:00Z',
      active: false
    },
    registrationDate: '2026-10-01',
    notes: 'November payment failed to clear. Account disapproved until payment receipt is furnished.'
  },
  {
    id: 'USR-105',
    shopName: 'Chennai Tools & Bearing Mart',
    ownerName: 'Anand Rajan',
    phone: '+91 97909 11223',
    email: 'anand.bearingmart@gmail.com',
    location: 'Broadway Main Rd, Chennai',
    plan: 'Starter Monthly',
    monthlyFee: 999,
    accountStatus: 'BLOCKED',
    paymentStatus: 'FAILED',
    paymentDeadline: '2026-10-25',
    lastPaymentDate: '2026-09-25',
    lastPaymentMethod: 'Bounced Cheque',
    transactionRef: 'CHQ-BOUNCE-019',
    credentials: {
      username: 'chennaitools',
      password: 'Tools@2026',
      issuedAt: '2026-09-25T16:00:00Z',
      active: false
    },
    registrationDate: '2026-09-15',
    notes: 'Blocked due to bounced cheque and unresponsiveness. Immediate admin contact required.'
  },
  {
    id: 'USR-106',
    shopName: 'Bafna Electrical Agencies',
    ownerName: 'Prakash Bafna',
    phone: '+91 98408 77665',
    email: 'bafnaelectricals@gmail.com',
    location: 'Nyniappa Naicken St, Chennai',
    plan: 'Pro Monthly',
    monthlyFee: 1499,
    accountStatus: 'PENDING_APPROVAL',
    paymentStatus: 'PAID',
    paymentDeadline: '2026-12-15',
    lastPaymentDate: '2026-11-15',
    lastPaymentMethod: 'UPI (PhonePe)',
    transactionRef: 'UPI-PP-98102941',
    credentials: null,
    registrationDate: '2026-11-15',
    notes: 'Payment verified via PhonePe UPI. Ready for admin to grant login credentials.'
  }
];

const STORAGE_USERS_KEY = 'billbooks_admin_users';
const STORAGE_ADMIN_SESSION_KEY = 'billbooks_admin_session';

export function getStoredAdminUsers() {
  try {
    const raw = localStorage.getItem(STORAGE_USERS_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed) && parsed.length > 0) return parsed;
    }
  } catch (e) {}
  saveStoredAdminUsers(INITIAL_CLIENT_USERS);
  return INITIAL_CLIENT_USERS;
}

export function saveStoredAdminUsers(users) {
  try {
    localStorage.setItem(STORAGE_USERS_KEY, JSON.stringify(users));
  } catch (e) {}
}

export function getAdminSession() {
  try {
    const raw = sessionStorage.getItem(STORAGE_ADMIN_SESSION_KEY) || localStorage.getItem(STORAGE_ADMIN_SESSION_KEY);
    if (raw) return JSON.parse(raw);
  } catch (e) {}
  return null;
}

export function saveAdminSession(session, remember = false) {
  try {
    sessionStorage.setItem(STORAGE_ADMIN_SESSION_KEY, JSON.stringify(session));
    if (remember) {
      localStorage.setItem(STORAGE_ADMIN_SESSION_KEY, JSON.stringify(session));
    }
  } catch (e) {}
}

export function clearAdminSession() {
  try {
    sessionStorage.removeItem(STORAGE_ADMIN_SESSION_KEY);
    localStorage.removeItem(STORAGE_ADMIN_SESSION_KEY);
  } catch (e) {}
}

export function generateRandomPassword(prefix = 'Bill') {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$';
  let rand = '';
  for (let i = 0; i < 4; i++) {
    rand += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return `${prefix}@${new Date().getFullYear()}${rand}`;
}

export function generateCleanUsername(shopName) {
  const cleaned = shopName
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '')
    .substring(0, 14);
  return cleaned || `user${Math.floor(1000 + Math.random() * 9000)}`;
}

export function calculateDaysRemaining(deadlineDateStr) {
  if (!deadlineDateStr) return { days: 0, status: 'UNKNOWN' };
  const deadline = new Date(deadlineDateStr);
  deadline.setHours(23, 59, 59, 999);
  const now = new Date();
  const diffMs = deadline - now;
  const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

  if (diffDays < 0) {
    return { days: Math.abs(diffDays), status: 'OVERDUE' };
  } else if (diffDays === 0) {
    return { days: 0, status: 'DUE_TODAY' };
  } else if (diffDays <= 3) {
    return { days: diffDays, status: 'DUE_SOON' };
  } else {
    return { days: diffDays, status: 'SAFE' };
  }
}

