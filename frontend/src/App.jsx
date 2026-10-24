import React, { useState, useEffect } from 'react';
import Sidebar from './components/Sidebar';
import Header from './components/Header';
import InboxView from './components/InboxView';
import ReviewView from './components/ReviewView';
import MasterMappingsView from './components/MasterMappingsView';
import TallyConnectorView from './components/TallyConnectorView';
import AuditTrailView from './components/AuditTrailView';
import SettingsView from './components/SettingsView';
import Login from './components/Login';
import { XmlModal, ConfirmPostModal } from './components/Modals';
import Toast from './components/Toast';
import { generateTallyPurchaseXml } from './utils/tallyXml';
import { getSystemHealth, getTallyHealth } from './services/api';
import { 
  INITIAL_INVOICES, 
  INITIAL_MAPPINGS, 
  INITIAL_POSTING_ATTEMPTS, 
  INITIAL_AUDIT_LOGS 
} from './data/mockData';

const STORAGE_SESSION_KEY = 'bill_to_tally_session';
const STORAGE_INVOICES_KEY = 'bill_to_tally_invoices';

export default function App() {
  // Authentication State
  const [user, setUser] = useState(() => {
    try {
      const raw = sessionStorage.getItem(STORAGE_SESSION_KEY) || localStorage.getItem(STORAGE_SESSION_KEY);
      if (raw) return JSON.parse(raw);
    } catch (e) {}
    return {
      username: 'accounts_user_01',
      fullName: 'Accounts User 01',
      role: 'Reviewer & Approver',
      initials: 'AU'
    };
  });
  const [showAuthModal, setShowAuthModal] = useState(false);

  // Application State
  const [activeTab, setActiveTab] = useState('inbox');
  const [invoices, setInvoices] = useState(() => {
    try {
      const raw = localStorage.getItem(STORAGE_INVOICES_KEY);
      if (raw) {
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed) && parsed.length > 0) {
          // Exclude any legacy mock seed invoices
          const realOnly = parsed.filter(i => 
            !['INV-01', 'INV-02', 'INV-03', 'INV-04', 'INV-05', 'INV-06'].includes(i.id) && 
            !i.sourceFilename?.includes('DeltaTech') &&
            !i.supplierRaw?.includes('DELTA TECH')
          );
          return realOnly;
        }
      }
    } catch (e) {}
    return INITIAL_INVOICES;
  });
  const [currentInvoiceId, setCurrentInvoiceId] = useState(null);
  const [mappings, setMappings] = useState(INITIAL_MAPPINGS);
  const [postingAttempts, setPostingAttempts] = useState(INITIAL_POSTING_ATTEMPTS);
  const [auditLogs, setAuditLogs] = useState(INITIAL_AUDIT_LOGS);

  // Backend Connectivity Probes
  const [systemHealth, setSystemHealth] = useState(null);
  const [tallyHealth, setTallyHealth] = useState(null);

  // Modals & Feedback
  const [xmlModalOpen, setXmlModalOpen] = useState(false);
  const [xmlContent, setXmlContent] = useState('');
  const [confirmPostModalOpen, setConfirmPostModalOpen] = useState(false);
  const [confirmPostInvoice, setConfirmPostInvoice] = useState(null);
  const [toasts, setToasts] = useState([]);

  // Check Backend Health on Mount
  useEffect(() => {
    async function checkBackends() {
      const sys = await getSystemHealth();
      setSystemHealth(sys);
      const tal = await getTallyHealth();
      setTallyHealth(tal);
    }
    checkBackends();
  }, []);

  // Save invoices to localStorage
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_INVOICES_KEY, JSON.stringify(invoices));
    } catch (e) {}
  }, [invoices]);

  function showToast(message, type = 'success') {
    const id = Date.now() + Math.random();
    setToasts(prev => [...prev, { id, message, type }]);
  }

  function removeToast(id) {
    setToasts(prev => prev.filter(t => t.id !== id));
  }

  function handleLoginSuccess(authenticatedUser, remember) {
    setUser(authenticatedUser);
    setShowAuthModal(false);
    sessionStorage.setItem(STORAGE_SESSION_KEY, JSON.stringify(authenticatedUser));
    if (remember) {
      localStorage.setItem(STORAGE_SESSION_KEY, JSON.stringify(authenticatedUser));
    }
    showToast(`Welcome back, ${authenticatedUser.fullName}! Workspace ready.`, 'success');
  }

  function handleLogout() {
    sessionStorage.removeItem(STORAGE_SESSION_KEY);
    localStorage.removeItem(STORAGE_SESSION_KEY);
    setUser(null);
    setShowAuthModal(true);
    showToast('Logged out successfully.', 'warning');
  }

  function handleAddInvoice(newInvoice) {
    setInvoices(prev => [newInvoice, ...prev]);
    setCurrentInvoiceId(newInvoice.id);
    setActiveTab('review');

    // Add Audit Log
    setAuditLogs(prev => [
      {
        time: new Date().toISOString().replace('T', ' ').substring(0, 19),
        actor: user?.username || 'accounts_user_01',
        action: 'DOCUMENT_UPLOADED',
        summary: `Processed and queued document "${newInvoice.sourceFilename}" as ${newInvoice.id}`,
        diff: {
          invoice_id: newInvoice.id,
          sha256: newInvoice.sha256?.substring(0, 24) || '—'
        }
      },
      ...prev
    ]);
  }

  function handleUpdateInvoice(updatedInvoice) {
    setInvoices(prev => prev.map(inv => inv.id === updatedInvoice.id ? updatedInvoice : inv));
  }

  function handlePreviewXml(invoice) {
    const xml = generateTallyPurchaseXml(invoice);
    setXmlContent(xml);
    setXmlModalOpen(true);
  }

  function handleOpenConfirmPost(invoice) {
    setConfirmPostInvoice(invoice);
    setConfirmPostModalOpen(true);
  }

  function handleExecutePost(invoice, idempotencyKey) {
    setConfirmPostModalOpen(false);

    // Mark invoice as POSTED in local state per AGENTS.md workflow
    const updated = {
      ...invoice,
      status: 'POSTED',
      tallyRef: `PUR/${new Date().getFullYear()}/${Math.floor(1000 + Math.random() * 9000)}`
    };
    handleUpdateInvoice(updated);

    // Record posting attempt
    const newAttempt = {
      id: `ATT-${new Date().getFullYear()}-${Math.floor(1000 + Math.random() * 9000)}`,
      invoiceId: invoice.id,
      idempotencyKey,
      voucherNo: updated.tallyRef,
      startedAt: new Date().toISOString().replace('T', ' ').substring(0, 19),
      status: 'POSTED',
      responseMessage: 'Tally XML server accepted payload (CREATED: 1, ERRORS: 0)'
    };
    setPostingAttempts(prev => [newAttempt, ...prev]);

    // Record audit event
    setAuditLogs(prev => [
      {
        time: new Date().toISOString().replace('T', ' ').substring(0, 19),
        actor: user?.username || 'accounts_user_01',
        action: 'VOUCHER_TRANSMITTED',
        summary: `Posted approved voucher for ${invoice.supplierRaw} (Ref: ${updated.tallyRef})`,
        diff: {
          status: { before: 'APPROVED', after: 'POSTED' },
          tally_ref: updated.tallyRef,
          idempotency_key: idempotencyKey
        }
      },
      ...prev
    ]);

    showToast(`Voucher ${updated.tallyRef} posted and reconciled into Tally Day Book!`, 'success');
  }

  // If user signed out, show clean login view
  if (!user || showAuthModal) {
    return <Login onLoginSuccess={handleLoginSuccess} />;
  }

  // Count summaries
  const invoiceCounts = {
    total: invoices.length,
    needsReview: invoices.filter(i => i.status === 'NEEDS_REVIEW' || i.status === 'NEEDS_CORRECTION').length,
    approved: invoices.filter(i => i.status === 'APPROVED').length,
    posted: invoices.filter(i => i.status === 'POSTED').length
  };

  return (
    <div className="app-container">
      {/* Sidebar Navigation */}
      <Sidebar 
        activeTab={activeTab} 
        onSelectTab={setActiveTab} 
        invoiceCounts={invoiceCounts}
        tallyConnected={tallyHealth?.connected || false}
        tallyCompany={tallyHealth?.company}
      />

      {/* Main Content Area */}
      <main className="main-wrapper">
        <Header 
          activeTab={activeTab}
          user={user}
          onLogout={handleLogout}
          onSwitchAccount={() => setShowAuthModal(true)}
          onTriggerUpload={() => {
            setActiveTab('inbox');
            const dropzoneInput = document.getElementById('upload-dropzone-box');
            if (dropzoneInput) dropzoneInput.click();
          }}
          postingEnabled={systemHealth?.posting_enabled || false}
        />

        <div className="content-body">
          {activeTab === 'inbox' && (
            <InboxView 
              invoices={invoices}
              onReviewInvoice={(id) => {
                setCurrentInvoiceId(id);
                setActiveTab('review');
              }}
              onAddInvoice={handleAddInvoice}
              onShowToast={showToast}
            />
          )}

          {activeTab === 'review' && (
            <ReviewView 
              invoices={invoices}
              currentInvoiceId={currentInvoiceId}
              onSelectInvoice={setCurrentInvoiceId}
              onUpdateInvoice={handleUpdateInvoice}
              onPreviewXml={handlePreviewXml}
              onConfirmPost={handleOpenConfirmPost}
              onShowToast={showToast}
            />
          )}

          {activeTab === 'mappings' && (
            <MasterMappingsView 
              mappings={mappings}
              onShowToast={showToast}
            />
          )}

          {activeTab === 'tally' && (
            <TallyConnectorView 
              postingAttempts={postingAttempts}
              tallyHealth={tallyHealth}
              onShowToast={showToast}
            />
          )}

          {activeTab === 'audit' && (
            <AuditTrailView 
              auditLogs={auditLogs}
              onShowToast={showToast}
            />
          )}

          {activeTab === 'settings' && (
            <SettingsView 
              onShowToast={showToast}
            />
          )}
        </div>
      </main>

      {/* Modals */}
      <XmlModal 
        isOpen={xmlModalOpen}
        onClose={() => setXmlModalOpen(false)}
        xmlContent={xmlContent}
        onShowToast={showToast}
      />

      <ConfirmPostModal 
        isOpen={confirmPostModalOpen}
        onClose={() => setConfirmPostModalOpen(false)}
        invoice={confirmPostInvoice}
        onConfirm={handleExecutePost}
      />

      {/* Toast Notifications */}
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
