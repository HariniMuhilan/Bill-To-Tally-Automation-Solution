import React, { useState, useEffect } from 'react';
import AdminHeader from './AdminHeader';
import AdminStatsCards from './AdminStatsCards';
import UserManagementTable from './UserManagementTable';

// Modals
import ApproveModal from './modals/ApproveModal';
import DisapproveModal from './modals/DisapproveModal';
import BlockModal from './modals/BlockModal';
import UpdatePaymentModal from './modals/UpdatePaymentModal';
import DeadlineModal from './modals/DeadlineModal';
import CredentialsModal from './modals/CredentialsModal';
import AddUserModal from './modals/AddUserModal';

import { getStoredAdminUsers, saveStoredAdminUsers } from '../../data/adminMockData';

export default function AdminDashboard({ admin, onLogout, onShowToast }) {
  const [users, setUsers] = useState(() => getStoredAdminUsers());

  // Modal active targets
  const [approveUser, setApproveUser] = useState(null);
  const [disapproveUser, setDisapproveUser] = useState(null);
  const [blockUser, setBlockUser] = useState(null);
  const [paymentUser, setPaymentUser] = useState(null);
  const [deadlineUser, setDeadlineUser] = useState(null);
  const [credentialsUser, setCredentialsUser] = useState(null);
  const [addUserModalOpen, setAddUserModalOpen] = useState(false);

  // Sync to localStorage
  useEffect(() => {
    saveStoredAdminUsers(users);
  }, [users]);

  // Derived counts for header alerts
  const pendingCount = users.filter(u => u.accountStatus === 'PENDING_APPROVAL').length;
  const overdueCount = users.filter(u => u.paymentStatus === 'OVERDUE').length;

  // 1. APPROVE USER & ISSUE CREDENTIALS
  function handleConfirmApprove({ userId, username, password, paymentVerified, paymentMethod, transactionRef, deadlineDate, notes }) {
    setUsers(prev => prev.map(u => {
      if (u.id !== userId) return u;
      return {
        ...u,
        accountStatus: 'APPROVED',
        paymentStatus: paymentVerified ? 'PAID' : u.paymentStatus,
        lastPaymentDate: paymentVerified ? new Date().toISOString().split('T')[0] : u.lastPaymentDate,
        lastPaymentMethod: paymentVerified ? paymentMethod : u.lastPaymentMethod,
        transactionRef: paymentVerified ? transactionRef : u.transactionRef,
        paymentDeadline: deadlineDate || u.paymentDeadline,
        credentials: {
          username,
          password,
          issuedAt: new Date().toISOString(),
          active: true
        },
        notes: notes ? `${notes} (Approved on ${new Date().toLocaleDateString('en-IN')})` : u.notes
      };
    }));

    const approvedTarget = users.find(u => u.id === userId);
    onShowToast(`User approved! Credentials issued for ${approvedTarget?.shopName || 'client'}.`, 'success');
  }

  // 2. DISAPPROVE USER
  function handleConfirmDisapprove({ userId, reason, suspendCredentials, notes }) {
    setUsers(prev => prev.map(u => {
      if (u.id !== userId) return u;
      return {
        ...u,
        accountStatus: 'DISAPPROVED',
        paymentStatus: u.paymentStatus === 'PAID' ? 'PENDING' : u.paymentStatus,
        credentials: u.credentials ? {
          ...u.credentials,
          active: !suspendCredentials
        } : null,
        notes: `${reason}. ${notes}`.trim()
      };
    }));

    const target = users.find(u => u.id === userId);
    onShowToast(`Account for ${target?.shopName} disapproved. Reason: ${reason}`, 'warning');
  }

  // 3. BLOCK / UNBLOCK USER
  function handleConfirmBlockToggle({ userId, blockAction, reason, notes }) {
    const isBlocking = blockAction === 'BLOCK';

    setUsers(prev => prev.map(u => {
      if (u.id !== userId) return u;
      return {
        ...u,
        accountStatus: isBlocking ? 'BLOCKED' : (u.paymentStatus === 'PAID' ? 'APPROVED' : 'PENDING_APPROVAL'),
        credentials: u.credentials ? {
          ...u.credentials,
          active: !isBlocking
        } : null,
        notes: `${isBlocking ? 'BLOCKED' : 'UNBLOCKED'}: ${reason}. ${notes}`.trim()
      };
    }));

    const target = users.find(u => u.id === userId);
    if (isBlocking) {
      onShowToast(`Account for ${target?.shopName} has been BLOCKED. Access revoked.`, 'danger');
    } else {
      onShowToast(`Account for ${target?.shopName} has been UNBLOCKED.`, 'success');
    }
  }

  // 4. MANUAL PAYMENT UPDATE
  function handleConfirmPaymentUpdate({ userId, paymentStatus, amountPaid, paymentDate, paymentMethod, transactionRef, deadlineDate, notes }) {
    setUsers(prev => prev.map(u => {
      if (u.id !== userId) return u;
      return {
        ...u,
        paymentStatus,
        monthlyFee: amountPaid,
        lastPaymentDate: paymentDate,
        lastPaymentMethod: paymentMethod,
        transactionRef,
        paymentDeadline: deadlineDate,
        notes: notes ? `${notes} (Payment updated manually by admin)` : u.notes
      };
    }));

    const target = users.find(u => u.id === userId);
    onShowToast(`Payment status updated to ${paymentStatus} for ${target?.shopName}.`, 'success');
  }

  // 5. CHANGE MONTHLY DEADLINE
  function handleConfirmDeadlineChange({ userId, deadlineDate, reason }) {
    setUsers(prev => prev.map(u => {
      if (u.id !== userId) return u;
      return {
        ...u,
        paymentDeadline: deadlineDate,
        notes: reason ? `${reason} (Deadline updated)` : u.notes
      };
    }));

    const target = users.find(u => u.id === userId);
    onShowToast(`Payment deadline updated to ${deadlineDate} for ${target?.shopName}.`, 'info');
  }

  // 6. ADD NEW SHOP
  function handleAddNewUser(newUser) {
    setUsers(prev => [newUser, ...prev]);
    onShowToast(`New shop "${newUser.shopName}" onboarded successfully!`, 'success');
  }

  // 7. DELETE USER
  function handleDeleteUser(userId) {
    const target = users.find(u => u.id === userId);
    setUsers(prev => prev.filter(u => u.id !== userId));
    onShowToast(`Shop client "${target?.shopName || userId}" deleted.`, 'info');
  }

  return (
    <div className="admin-portal-layout">
      {/* Header */}
      <AdminHeader
        admin={admin}
        onLogout={onLogout}
        pendingCount={pendingCount}
        overdueCount={overdueCount}
      />

      {/* Main Container */}
      <main className="admin-main-content">
        <div className="admin-container">
          
          {/* Welcome Banner */}
          <div className="admin-welcome-bar">
            <div>
              <h1 className="admin-welcome-title">Client Approvals & Subscription Management</h1>
              <p className="admin-welcome-desc">
                Review wholesale shop signups, verify payments, issue user credentials, and monitor monthly billing deadlines.
              </p>
            </div>
            <div className="admin-welcome-actions">
              <button
                type="button"
                className="btn btn-secondary"
                onClick={() => {
                  setUsers(getStoredAdminUsers());
                  onShowToast('Client data reloaded from database.', 'info');
                }}
                title="Reload latest records"
              >
                <i className="fa-solid fa-arrows-rotate" style={{ marginRight: '6px' }}></i>
                Refresh
              </button>
              <button
                type="button"
                className="btn btn-primary"
                onClick={() => setAddUserModalOpen(true)}
                style={{ background: '#493044', borderColor: '#493044', color: '#fff' }}
              >
                <i className="fa-solid fa-user-plus" style={{ marginRight: '6px' }}></i>
                Onboard Shop
              </button>
            </div>
          </div>

          {/* Stats Cards */}
          <AdminStatsCards users={users} />

          {/* User Management Table */}
          <UserManagementTable
            users={users}
            onApproveUser={(user) => setApproveUser(user)}
            onDisapproveUser={(user) => setDisapproveUser(user)}
            onBlockUserToggle={(user) => setBlockUser(user)}
            onUpdatePayment={(user) => setPaymentUser(user)}
            onChangeDeadline={(user) => setDeadlineUser(user)}
            onViewCredentials={(user) => setCredentialsUser(user)}
            onAddNewUser={() => setAddUserModalOpen(true)}
            onDeleteUser={handleDeleteUser}
            onShowToast={onShowToast}
          />

        </div>
      </main>

      {/* MODALS */}
      <ApproveModal
        isOpen={Boolean(approveUser)}
        user={approveUser}
        onClose={() => setApproveUser(null)}
        onConfirmApprove={handleConfirmApprove}
      />

      <DisapproveModal
        isOpen={Boolean(disapproveUser)}
        user={disapproveUser}
        onClose={() => setDisapproveUser(null)}
        onConfirmDisapprove={handleConfirmDisapprove}
      />

      <BlockModal
        isOpen={Boolean(blockUser)}
        user={blockUser}
        onClose={() => setBlockUser(null)}
        onConfirmBlockToggle={handleConfirmBlockToggle}
      />

      <UpdatePaymentModal
        isOpen={Boolean(paymentUser)}
        user={paymentUser}
        onClose={() => setPaymentUser(null)}
        onConfirmPaymentUpdate={handleConfirmPaymentUpdate}
      />

      <DeadlineModal
        isOpen={Boolean(deadlineUser)}
        user={deadlineUser}
        onClose={() => setDeadlineUser(null)}
        onConfirmDeadlineChange={handleConfirmDeadlineChange}
      />

      <CredentialsModal
        isOpen={Boolean(credentialsUser)}
        user={credentialsUser}
        onClose={() => setCredentialsUser(null)}
        onShowToast={onShowToast}
      />

      <AddUserModal
        isOpen={addUserModalOpen}
        onClose={() => setAddUserModalOpen(false)}
        onAddUser={handleAddNewUser}
      />
    </div>
  );
}
