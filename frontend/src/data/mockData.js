/**
 * Default Seed Mock Data for Bill-to-Tally Automation
 * Ashan Tech Labs
 */

export const INITIAL_INVOICES = [];

export const INITIAL_MAPPINGS = {
  suppliers: [],
  items: [],
  ledgers: [
    { id: 'MAP-LED-01', raw: 'Purchase Accounts 18% GST', tally: 'Purchase - GST 18%', category: 'Purchase Accounts', guid: 'c31d8cd9-8f00-4b82-9642-120000000010', status: 'VERIFIED', date: '2026-09-01' },
    { id: 'MAP-LED-02', raw: 'Printing and Stationery Expenses', tally: 'Printing & Stationery Exp', category: 'Indirect Expenses', guid: 'c31d8cd9-8f00-4b82-9642-120000000011', status: 'VERIFIED', date: '2026-09-01' },
    { id: 'MAP-LED-03', raw: 'Input CGST 9%', tally: 'Input CGST @ 9%', category: 'Duties & Taxes', guid: 'c31d8cd9-8f00-4b82-9642-120000000012', status: 'VERIFIED', date: '2026-09-01' },
    { id: 'MAP-LED-04', raw: 'Input SGST 9%', tally: 'Input SGST @ 9%', category: 'Duties & Taxes', guid: 'c31d8cd9-8f00-4b82-9642-120000000013', status: 'VERIFIED', date: '2026-09-01' },
  ],
  units: [
    { id: 'MAP-UNT-01', raw: 'NOS / NUMBERS', tally: 'NOS (Numbers)', category: 'Simple Unit', guid: null, status: 'VERIFIED', date: '2026-09-01' },
    { id: 'MAP-UNT-02', raw: 'PCS / PIECES', tally: 'PCS (Pieces)', category: 'Simple Unit', guid: null, status: 'VERIFIED', date: '2026-09-01' },
    { id: 'MAP-UNT-03', raw: 'SETS / KITS', tally: 'SETS (Sets)', category: 'Simple Unit', guid: null, status: 'VERIFIED', date: '2026-09-01' },
    { id: 'MAP-UNT-04', raw: 'REAMS', tally: 'RMS (Reams)', category: 'Simple Unit', guid: null, status: 'VERIFIED', date: '2026-09-01' },
  ]
};

export const INITIAL_POSTING_ATTEMPTS = [];

export const INITIAL_AUDIT_LOGS = [];
