import React from 'react';

export default function AdminStatsCards({ users }) {
  const total = users.length;
  const approved = users.filter(u => u.accountStatus === 'APPROVED').length;
  const pending = users.filter(u => u.accountStatus === 'PENDING_APPROVAL').length;
  const disapproved = users.filter(u => u.accountStatus === 'DISAPPROVED').length;
  const blocked = users.filter(u => u.accountStatus === 'BLOCKED').length;

  const paidCount = users.filter(u => u.paymentStatus === 'PAID').length;
  const overdueCount = users.filter(u => u.paymentStatus === 'OVERDUE').length;

  const totalMonthlyPotential = users.reduce((acc, u) => acc + (Number(u.monthlyFee) || 0), 0);
  const totalMonthlyCollected = users
    .filter(u => u.paymentStatus === 'PAID')
    .reduce((acc, u) => acc + (Number(u.monthlyFee) || 0), 0);

  const stats = [
    {
      id: 'total',
      label: 'TOTAL CLIENTS',
      value: total,
      subtext: 'Registered wholesale shops',
      icon: 'fa-solid fa-store',
      color: '#493044',
      bg: '#F7F2F4'
    },
    {
      id: 'approved',
      label: 'APPROVED & ACTIVE',
      value: approved,
      subtext: 'Credentials issued & active',
      icon: 'fa-solid fa-circle-check',
      color: '#16794B',
      bg: '#E6F4EA'
    },
    {
      id: 'pending',
      label: 'PENDING APPROVAL',
      value: pending,
      subtext: 'Awaiting review / credentials',
      icon: 'fa-solid fa-clock-rotate-left',
      color: '#B86E00',
      bg: '#FEF3C7'
    },
    {
      id: 'overdue',
      label: 'OVERDUE / DISAPPROVED',
      value: `${overdueCount} / ${disapproved}`,
      subtext: 'Payment pending or overdue',
      icon: 'fa-solid fa-triangle-exclamation',
      color: '#B91C1C',
      bg: '#FEE2E2'
    },
    {
      id: 'blocked',
      label: 'BLOCKED ACCOUNTS',
      value: blocked,
      subtext: 'Access restricted by admin',
      icon: 'fa-solid fa-ban',
      color: '#111522',
      bg: '#E5E7EB'
    },
    {
      id: 'revenue',
      label: 'MONTHLY SUBSCRIPTIONS',
      value: `₹${totalMonthlyCollected.toLocaleString('en-IN')}`,
      subtext: `Target: ₹${totalMonthlyPotential.toLocaleString('en-IN')} (${paidCount}/${total} paid)`,
      icon: 'fa-solid fa-indian-rupee-sign',
      color: '#FF9900',
      bg: '#FFF3E0'
    }
  ];

  return (
    <div className="admin-stats-grid">
      {stats.map(s => (
        <div key={s.id} className="admin-stat-card">
          <div className="stat-card-top">
            <span className="stat-card-label">{s.label}</span>
            <div className="stat-card-icon" style={{ background: s.bg, color: s.color }}>
              <i className={s.icon}></i>
            </div>
          </div>
          <div className="stat-card-value" style={{ color: s.color }}>
            {s.value}
          </div>
          <div className="stat-card-subtext">{s.subtext}</div>
        </div>
      ))}
    </div>
  );
}
