import React, { useState } from 'react';

export default function MasterMappingsView({ mappings, onShowToast }) {
  const [activeTab, setActiveTab] = useState('suppliers');

  const items = mappings[activeTab] || [];

  return (
    <section className="tab-pane active" id="tab-mappings">
      <div className="glass-card">
        <div className="table-toolbar">
          <div className="filter-pills">
            <button 
              className={`filter-pill ${activeTab === 'suppliers' ? 'active' : ''}`}
              onClick={() => setActiveTab('suppliers')}
            >
              <i className="fa-solid fa-users-viewfinder"></i> Supplier Ledgers ({mappings.suppliers?.length || 0})
            </button>
            <button 
              className={`filter-pill ${activeTab === 'items' ? 'active' : ''}`}
              onClick={() => setActiveTab('items')}
            >
              <i className="fa-solid fa-boxes-stacked"></i> Stock Items ({mappings.items?.length || 0})
            </button>
            <button 
              className={`filter-pill ${activeTab === 'ledgers' ? 'active' : ''}`}
              onClick={() => setActiveTab('ledgers')}
            >
              <i className="fa-solid fa-book-bookmark"></i> Purchase Ledgers ({mappings.ledgers?.length || 0})
            </button>
            <button 
              className={`filter-pill ${activeTab === 'units' ? 'active' : ''}`}
              onClick={() => setActiveTab('units')}
            >
              <i className="fa-solid fa-scale-balanced"></i> Units of Measure ({mappings.units?.length || 0})
            </button>
          </div>

          <button 
            type="button" 
            className="btn btn-secondary btn-sm"
            onClick={() => onShowToast('Syncing masters from TallyPrime XML server (port 9000)...', 'warning')}
          >
            <i className="fa-solid fa-arrows-rotate"></i> Sync from TallyPrime
          </button>
        </div>

        <table className="data-table">
          <thead>
            <tr>
              <th>Mapping ID</th>
              <th>Raw Text (OCR Extracted)</th>
              <th>Mapped TallyPrime Master</th>
              <th>Category</th>
              <th>Master GUID</th>
              <th>Status</th>
              <th>Last Synced</th>
            </tr>
          </thead>
          <tbody>
            {items.map(row => (
              <tr key={row.id}>
                <td><strong className="mono" style={{ color: 'var(--color-azure-text)' }}>{row.id}</strong></td>
                <td><span style={{ fontWeight: 600 }}>{row.raw}</span></td>
                <td>
                  <span style={{ color: row.status === 'VERIFIED' ? 'var(--color-azure-text)' : 'var(--color-amber-text)', fontWeight: 700 }}>
                    {row.tally}
                  </span>
                </td>
                <td><span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{row.category}</span></td>
                <td><span className="mono" style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>{row.guid || '—'}</span></td>
                <td>
                  <span className={`status-badge ${row.status === 'VERIFIED' ? 'approved' : 'needs-review'}`}>
                    <i className={`fa-solid ${row.status === 'VERIFIED' ? 'fa-check' : 'fa-clock'}`}></i> {row.status}
                  </span>
                </td>
                <td><span className="mono" style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{row.date}</span></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
