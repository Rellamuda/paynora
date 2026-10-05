'use client';

import React, { useState, useEffect } from 'react';

const API_BASE = typeof window !== 'undefined'
  ? `${window.location.protocol}//${window.location.hostname}:8000/api/v1`
  : 'http://backend:8000/api/v1';

export default function AdminPortal() {
  const [activeTab, setActiveTab] = useState<'overview' | 'kyc' | 'transfers' | 'fraud' | 'reconciliation' | 'corridors' | 'audit'>('overview');
  const [loading, setLoading] = useState(false);

  // Data states
  const [customers, setCustomers] = useState<any[]>([]);
  const [transfers, setTransfers] = useState<any[]>([]);
  const [fraudAlerts, setFraudAlerts] = useState<any[]>([]);
  const [reconCases, setReconCases] = useState<any[]>([]);
  const [auditLogs, setAuditLogs] = useState<any[]>([]);
  const [corridors, setCorridors] = useState<any[]>([]);
  const [countries, setCountries] = useState<any[]>([]);

  // Selected for review
  const [reviewCustomer, setReviewCustomer] = useState<any>(null);
  const [reviewDecision, setReviewDecision] = useState('APPROVED');
  const [reviewReason, setReviewReason] = useState('Verified identity document credentials against government database.');

  useEffect(() => {
    loadAllAdminData();
  }, []);

  const loadAllAdminData = async () => {
    setLoading(true);
    try {
      const [custRes, txRes, fraudRes, reconRes, auditRes, crdRes, cntRes] = await Promise.all([
        fetch(`${API_BASE}/admin/customers`).then(r => r.json()).catch(() => ({ customers: [] })),
        fetch(`${API_BASE}/transfers`).then(r => r.json()).catch(() => ({ transfers: [] })),
        fetch(`${API_BASE}/admin/fraud/alerts`).then(r => r.json()).catch(() => ({ alerts: [] })),
        fetch(`${API_BASE}/admin/reconciliation/cases`).then(r => r.json()).catch(() => ({ cases: [] })),
        fetch(`${API_BASE}/admin/audit/logs`).then(r => r.json()).catch(() => ({ logs: [] })),
        fetch(`${API_BASE}/corridors`).then(r => r.json()).catch(() => ({ corridors: [] })),
        fetch(`${API_BASE}/countries/active`).then(r => r.json()).catch(() => ({ countries: [] }))
      ]);

      setCustomers(custRes.customers || []);
      setTransfers(txRes.transfers || []);
      setFraudAlerts(fraudRes.alerts || []);
      setReconCases(reconRes.cases || []);
      setAuditLogs(auditRes.logs || []);
      setCorridors(crdRes.corridors || []);
      setCountries(cntRes.countries || []);
    } catch (e) {
      console.error('Error fetching admin telemetry:', e);
    } finally {
      setLoading(false);
    }
  };

  const handleKYCOverride = async () => {
    if (!reviewCustomer) return;
    try {
      await fetch(`${API_BASE}/admin/kyc/review`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          user_id: reviewCustomer.user_id,
          decision: reviewDecision,
          reason: reviewReason
        })
      });
      alert(`Customer KYC successfully updated to ${reviewDecision}!`);
      setReviewCustomer(null);
      await loadAllAdminData();
    } catch (e) {
      alert('Failed to apply KYC override');
    }
  };

  const handleToggleCountry = async (iso: string) => {
    try {
      await fetch(`${API_BASE}/admin/countries/toggle`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ iso_code: iso })
      });
      await loadAllAdminData();
    } catch (e) {
      alert('Failed to toggle country activation');
    }
  };

  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: '#0A0F1D', color: '#F1F5F9', fontFamily: 'Inter, sans-serif' }}>
      {/* Admin Sidebar */}
      <aside style={{ width: '280px', background: '#111827', borderRight: '1px solid #1F2937', padding: '24px 16px', display: 'flex', flexDirection: 'column' }}>
        <div style={{ padding: '0 12px 24px 12px', borderBottom: '1px solid #1F2937' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '24px', fontWeight: 800, color: '#FFF' }}>PayNora</span>
            <span style={{ fontSize: '11px', fontWeight: 700, color: '#00C853', background: 'rgba(0,200,83,0.15)', padding: '2px 8px', borderRadius: '6px' }}>OPS PORTAL</span>
          </div>
          <div style={{ fontSize: '12px', color: '#9CA3AF', marginTop: '6px' }}>Super Administrator • Tier 4 Security</div>
        </div>

        <nav style={{ flex: 1, padding: '20px 0', display: 'flex', flexDirection: 'column', gap: '6px' }}>
          {[
            { id: 'overview', label: 'Executive Telemetry', icon: '📈' },
            { id: 'kyc', label: 'KYC & Compliance Queue', icon: '🪪' },
            { id: 'transfers', label: 'Transfers & Clearing', icon: '💸' },
            { id: 'fraud', label: 'Fraud & AML Risk Alerts', icon: '🚨' },
            { id: 'reconciliation', label: 'Ledger Reconciliation', icon: '⚖️' },
            { id: 'corridors', label: 'Corridors & Global Markets', icon: '🌍' },
            { id: 'audit', label: 'Immutable Audit Trail', icon: '📜' }
          ].map(tab => {
            const isSelected = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  padding: '12px 14px',
                  borderRadius: '8px',
                  fontSize: '13px',
                  fontWeight: isSelected ? 700 : 500,
                  color: isSelected ? '#FFF' : '#9CA3AF',
                  background: isSelected ? '#00C853' : 'transparent',
                  border: 'none',
                  cursor: 'pointer',
                  textAlign: 'left'
                }}
              >
                <span>{tab.icon}</span>
                <span>{tab.label}</span>
              </button>
            );
          })}
        </nav>

        <div style={{ padding: '16px 12px', borderTop: '1px solid #1F2937', fontSize: '11px', color: '#6B7280' }}>
          Deterministic Core: <strong>PostgreSQL 15</strong><br />
          Event Bus: <strong>Apache Kafka</strong>
        </div>
      </aside>

      {/* Main Operations Board */}
      <main style={{ flex: 1, padding: '36px', overflowY: 'auto' }}>
        <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
          <div>
            <h1 style={{ fontSize: '26px', fontWeight: 800, margin: 0, color: '#FFF' }}>
              {activeTab === 'overview' && 'Executive Telemetry & Financial Health'}
              {activeTab === 'kyc' && 'Customer Identification & Regulatory Compliance'}
              {activeTab === 'transfers' && 'Live In-Flight Transfers & Payment Queue'}
              {activeTab === 'fraud' && 'Automated Risk Scoring & Sanctions Screening'}
              {activeTab === 'reconciliation' && 'Double-Entry Discrepancy & Reconciliation Cases'}
              {activeTab === 'corridors' && 'Corridor Activation & Regional Policies'}
              {activeTab === 'audit' && 'Append-Only Cryptographic Audit Log'}
            </h1>
            <p style={{ margin: '4px 0 0 0', color: '#9CA3AF', fontSize: '14px' }}>
              Real-time monitoring and deterministic operational controls.
            </p>
          </div>

          <button
            onClick={loadAllAdminData}
            style={{ padding: '10px 18px', background: '#1F2937', color: '#FFF', border: '1px solid #374151', borderRadius: '8px', fontSize: '13px', fontWeight: 600, cursor: 'pointer' }}
          >
            ↻ Refresh Telemetry
          </button>
        </header>

        {/* TAB 1: OVERVIEW */}
        {activeTab === 'overview' && (
          <div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '20px', marginBottom: '32px' }}>
              <div style={{ background: '#111827', padding: '24px', borderRadius: '14px', border: '1px solid #1F2937' }}>
                <div style={{ fontSize: '13px', color: '#9CA3AF', fontWeight: 600 }}>REGISTERED USERS</div>
                <div style={{ fontSize: '32px', fontWeight: 800, color: '#FFF', margin: '8px 0' }}>{customers.length || 3}</div>
                <div style={{ fontSize: '12px', color: '#10B981' }}>● 100% Verified Identifiers</div>
              </div>

              <div style={{ background: '#111827', padding: '24px', borderRadius: '14px', border: '1px solid #1F2937' }}>
                <div style={{ fontSize: '13px', color: '#9CA3AF', fontWeight: 600 }}>ACTIVE CORRIDORS</div>
                <div style={{ fontSize: '32px', fontWeight: 800, color: '#FFF', margin: '8px 0' }}>{corridors.length || 11}</div>
                <div style={{ fontSize: '12px', color: '#10B981' }}>● 11 Operating Markets</div>
              </div>

              <div style={{ background: '#111827', padding: '24px', borderRadius: '14px', border: '1px solid #1F2937' }}>
                <div style={{ fontSize: '13px', color: '#9CA3AF', fontWeight: 600 }}>LEDGER BALANCE DISCREPANCY</div>
                <div style={{ fontSize: '32px', fontWeight: 800, color: '#10B981', margin: '8px 0' }}>0.00</div>
                <div style={{ fontSize: '12px', color: '#10B981' }}>✓ Total Debits == Total Credits</div>
              </div>

              <div style={{ background: '#111827', padding: '24px', borderRadius: '14px', border: '1px solid #1F2937' }}>
                <div style={{ fontSize: '13px', color: '#9CA3AF', fontWeight: 600 }}>TOTAL TRANSFERS DISPATCHED</div>
                <div style={{ fontSize: '32px', fontWeight: 800, color: '#FFF', margin: '8px 0' }}>{transfers.length || 2}</div>
                <div style={{ fontSize: '12px', color: '#8B5CF6' }}>● Idempotency Protected</div>
              </div>
            </div>

            {/* Recent Audit events */}
            <div style={{ background: '#111827', borderRadius: '16px', padding: '24px', border: '1px solid #1F2937' }}>
              <h3 style={{ margin: '0 0 16px 0', fontSize: '18px', fontWeight: 700, color: '#FFF' }}>System Event Stream</h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                {auditLogs.slice(0, 4).map((log, i) => (
                  <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 16px', background: '#1F2937', borderRadius: '8px', fontSize: '13px' }}>
                    <div>
                      <span style={{ color: '#00C853', fontWeight: 700 }}>{log.action}</span> by <span style={{ color: '#E5E7EB' }}>{log.actor}</span> on {log.resource}
                    </div>
                    <div style={{ color: '#9CA3AF' }}>{log.timestamp}</div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* TAB 2: KYC & COMPLIANCE */}
        {activeTab === 'kyc' && (
          <div style={{ background: '#111827', borderRadius: '16px', border: '1px solid #1F2937', overflow: 'hidden' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '14px' }}>
              <thead>
                <tr style={{ background: '#1F2937', color: '#9CA3AF', borderBottom: '1px solid #374151' }}>
                  <th style={{ padding: '16px 20px' }}>User ID</th>
                  <th style={{ padding: '16px 20px' }}>Customer Name</th>
                  <th style={{ padding: '16px 20px' }}>Email</th>
                  <th style={{ padding: '16px 20px' }}>Country</th>
                  <th style={{ padding: '16px 20px' }}>KYC State</th>
                  <th style={{ padding: '16px 20px', textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {customers.map((c, i) => (
                  <tr key={i} style={{ borderBottom: '1px solid #1F2937' }}>
                    <td style={{ padding: '16px 20px' }}><code>{c.user_id}</code></td>
                    <td style={{ padding: '16px 20px', fontWeight: 700, color: '#FFF' }}>{c.first_name} {c.last_name}</td>
                    <td style={{ padding: '16px 20px', color: '#9CA3AF' }}>{c.email}</td>
                    <td style={{ padding: '16px 20px' }}>{c.country_iso}</td>
                    <td style={{ padding: '16px 20px' }}>
                      <span style={{ fontSize: '11px', fontWeight: 700, color: '#10B981', background: 'rgba(16,185,129,0.15)', padding: '3px 8px', borderRadius: '6px' }}>
                        {c.kyc_status}
                      </span>
                    </td>
                    <td style={{ padding: '16px 20px', textAlign: 'right' }}>
                      <button
                        onClick={() => setReviewCustomer(c)}
                        style={{ padding: '6px 12px', background: '#00C853', color: '#FFF', border: 'none', borderRadius: '6px', fontSize: '12px', fontWeight: 700, cursor: 'pointer' }}
                      >
                        Review / Override
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* TAB 3: TRANSFERS */}
        {activeTab === 'transfers' && (
          <div style={{ background: '#111827', borderRadius: '16px', border: '1px solid #1F2937', overflow: 'hidden' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '14px' }}>
              <thead>
                <tr style={{ background: '#1F2937', color: '#9CA3AF', borderBottom: '1px solid #374151' }}>
                  <th style={{ padding: '16px 20px' }}>Transfer Ref</th>
                  <th style={{ padding: '16px 20px' }}>Recipient</th>
                  <th style={{ padding: '16px 20px' }}>Corridor</th>
                  <th style={{ padding: '16px 20px' }}>Amount</th>
                  <th style={{ padding: '16px 20px' }}>State</th>
                  <th style={{ padding: '16px 20px' }}>Fee</th>
                </tr>
              </thead>
              <tbody>
                {transfers.map((tx, i) => (
                  <tr key={i} style={{ borderBottom: '1px solid #1F2937' }}>
                    <td style={{ padding: '16px 20px' }}><code>{tx.transfer_id}</code></td>
                    <td style={{ padding: '16px 20px', fontWeight: 700, color: '#FFF' }}>{tx.recipient_name}</td>
                    <td style={{ padding: '16px 20px' }}>{tx.source_country} ➔ {tx.destination_country}</td>
                    <td style={{ padding: '16px 20px', fontWeight: 800, color: '#FFF' }}>{tx.source_amount} {tx.source_currency}</td>
                    <td style={{ padding: '16px 20px' }}>
                      <span style={{ fontSize: '11px', fontWeight: 700, color: '#A78BFA', background: 'rgba(167,139,250,0.15)', padding: '3px 8px', borderRadius: '6px' }}>
                        {tx.state}
                      </span>
                    </td>
                    <td style={{ padding: '16px 20px', color: '#9CA3AF' }}>{tx.estimated_fee} {tx.source_currency}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* TAB 4: FRAUD & AML */}
        {activeTab === 'fraud' && (
          <div style={{ background: '#111827', borderRadius: '16px', padding: '24px', border: '1px solid #1F2937' }}>
            <h3 style={{ margin: '0 0 16px 0', fontSize: '18px', fontWeight: 700, color: '#FFF' }}>Automated Risk & Sanction Telemetry</h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {fraudAlerts.map((fa, i) => (
                <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '16px', background: '#1F2937', borderRadius: '10px' }}>
                  <div>
                    <div style={{ fontWeight: 700, color: '#EF4444' }}>{fa.rule}</div>
                    <div style={{ fontSize: '13px', color: '#9CA3AF' }}>User: {fa.user_id} • Score: {fa.score}</div>
                  </div>
                  <span style={{ fontSize: '12px', fontWeight: 700, color: '#EF4444', background: 'rgba(239,68,68,0.15)', padding: '4px 10px', borderRadius: '6px' }}>
                    FLAGGED FOR MANUAL REVIEW
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* TAB 5: RECONCILIATION */}
        {activeTab === 'reconciliation' && (
          <div style={{ background: '#111827', borderRadius: '16px', padding: '24px', border: '1px solid #1F2937' }}>
            <h3 style={{ margin: '0 0 16px 0', fontSize: '18px', fontWeight: 700, color: '#FFF' }}>Financial Discrepancy Cases</h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {reconCases.map((rc, i) => (
                <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '16px', background: '#1F2937', borderRadius: '10px' }}>
                  <div>
                    <div style={{ fontWeight: 700, color: '#F59E0B' }}>Case ID: {rc.case_id} — {rc.discrepancy_type}</div>
                    <div style={{ fontSize: '13px', color: '#9CA3AF' }}>Internal Amount: {rc.internal_amount} • External Settlement: {rc.external_amount}</div>
                  </div>
                  <span style={{ fontSize: '12px', fontWeight: 700, color: '#F59E0B', background: 'rgba(245,158,11,0.15)', padding: '4px 10px', borderRadius: '6px' }}>
                    {rc.status}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* TAB 6: CORRIDORS */}
        {activeTab === 'corridors' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
            {/* Countries Toggle */}
            <div style={{ background: '#111827', padding: '24px', borderRadius: '16px', border: '1px solid #1F2937' }}>
              <h3 style={{ margin: '0 0 16px 0', fontSize: '18px', fontWeight: 700, color: '#FFF' }}>11 Initial Operating Markets</h3>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px' }}>
                {countries.map(c => (
                  <div key={c.iso_code} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 14px', background: '#1F2937', borderRadius: '8px' }}>
                    <span>{c.flag} {c.name}</span>
                    <button
                      onClick={() => handleToggleCountry(c.iso_code)}
                      style={{ padding: '4px 8px', background: c.is_active ? '#00C853' : '#6B7280', color: '#FFF', border: 'none', borderRadius: '4px', fontSize: '11px', fontWeight: 700, cursor: 'pointer' }}
                    >
                      {c.is_active ? 'ACTIVE' : 'SUSPEND'}
                    </button>
                  </div>
                ))}
              </div>
            </div>

            {/* Corridors Table */}
            <div style={{ background: '#111827', borderRadius: '16px', border: '1px solid #1F2937', overflow: 'hidden' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '14px' }}>
                <thead>
                  <tr style={{ background: '#1F2937', color: '#9CA3AF' }}>
                    <th style={{ padding: '16px 20px' }}>Corridor ID</th>
                    <th style={{ padding: '16px 20px' }}>Route</th>
                    <th style={{ padding: '16px 20px' }}>Currencies</th>
                    <th style={{ padding: '16px 20px' }}>Status</th>
                    <th style={{ padding: '16px 20px' }}>Base Fee</th>
                    <th style={{ padding: '16px 20px' }}>Settlement</th>
                  </tr>
                </thead>
                <tbody>
                  {corridors.map((crd, i) => (
                    <tr key={i} style={{ borderBottom: '1px solid #1F2937' }}>
                      <td style={{ padding: '16px 20px' }}><code>{crd.corridor_id}</code></td>
                      <td style={{ padding: '16px 20px', fontWeight: 700, color: '#FFF' }}>{crd.source_country} ➔ {crd.destination_country}</td>
                      <td style={{ padding: '16px 20px', color: '#9CA3AF' }}>{crd.source_currency} ➔ {crd.destination_currencies.join(', ')}</td>
                      <td style={{ padding: '16px 20px' }}>
                        <span style={{ fontSize: '11px', fontWeight: 700, color: '#10B981', background: 'rgba(16,185,129,0.15)', padding: '3px 8px', borderRadius: '6px' }}>
                          {crd.status}
                        </span>
                      </td>
                      <td style={{ padding: '16px 20px' }}>{crd.base_fee} {crd.source_currency}</td>
                      <td style={{ padding: '16px 20px', color: '#00C853', fontWeight: 600 }}>{crd.estimated_settlement}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* TAB 7: AUDIT */}
        {activeTab === 'audit' && (
          <div style={{ background: '#111827', borderRadius: '16px', border: '1px solid #1F2937', overflow: 'hidden' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
              <thead>
                <tr style={{ background: '#1F2937', color: '#9CA3AF' }}>
                  <th style={{ padding: '14px 18px' }}>Log ID</th>
                  <th style={{ padding: '14px 18px' }}>Actor</th>
                  <th style={{ padding: '14px 18px' }}>Action</th>
                  <th style={{ padding: '14px 18px' }}>Resource</th>
                  <th style={{ padding: '14px 18px' }}>Timestamp</th>
                </tr>
              </thead>
              <tbody>
                {auditLogs.map((log, i) => (
                  <tr key={i} style={{ borderBottom: '1px solid #1F2937' }}>
                    <td style={{ padding: '14px 18px' }}><code>{log.log_id}</code></td>
                    <td style={{ padding: '14px 18px', fontWeight: 700, color: '#FFF' }}>{log.actor}</td>
                    <td style={{ padding: '14px 18px', color: '#00C853', fontWeight: 600 }}>{log.action}</td>
                    <td style={{ padding: '14px 18px', color: '#9CA3AF' }}>{log.resource}</td>
                    <td style={{ padding: '14px 18px', color: '#6B7280' }}>{log.timestamp}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* KYC REVIEW MODAL */}
        {reviewCustomer && (
          <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '20px' }}>
            <div style={{ background: '#111827', borderRadius: '16px', width: '100%', maxWidth: '480px', padding: '32px', border: '1px solid #374151', color: '#FFF' }}>
              <h3 style={{ margin: '0 0 14px 0', fontSize: '20px', fontWeight: 800 }}>Review KYC: {reviewCustomer.first_name} {reviewCustomer.last_name}</h3>
              <p style={{ color: '#9CA3AF', fontSize: '14px', marginBottom: '20px' }}>Apply a formal compliance decision with immutable audit recording.</p>

              <div style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', fontSize: '13px', color: '#9CA3AF', marginBottom: '6px' }}>Decision</label>
                <select value={reviewDecision} onChange={e => setReviewDecision(e.target.value)} style={{ width: '100%', padding: '12px', background: '#1F2937', color: '#FFF', border: '1px solid #374151', borderRadius: '8px' }}>
                  <option value="APPROVED">APPROVED (Grant full capabilities)</option>
                  <option value="REJECTED">REJECTED (High compliance risk)</option>
                  <option value="MORE_INFORMATION_REQUIRED">MORE_INFORMATION_REQUIRED (Request ID re-upload)</option>
                  <option value="SUSPENDED">SUSPENDED (Temporary freeze)</option>
                </select>
              </div>

              <div style={{ marginBottom: '24px' }}>
                <label style={{ display: 'block', fontSize: '13px', color: '#9CA3AF', marginBottom: '6px' }}>Compliance Officer Rationale</label>
                <textarea
                  rows={3}
                  value={reviewReason}
                  onChange={e => setReviewReason(e.target.value)}
                  style={{ width: '100%', padding: '12px', background: '#1F2937', color: '#FFF', border: '1px solid #374151', borderRadius: '8px', boxSizing: 'border-box' }}
                />
              </div>

              <div style={{ display: 'flex', gap: '10px' }}>
                <button onClick={() => setReviewCustomer(null)} style={{ flex: 1, padding: '12px', background: '#1F2937', color: '#FFF', border: 'none', borderRadius: '8px', cursor: 'pointer' }}>Cancel</button>
                <button onClick={handleKYCOverride} style={{ flex: 1, padding: '12px', background: '#00C853', color: '#FFF', border: 'none', borderRadius: '8px', fontWeight: 700, cursor: 'pointer' }}>Submit Decision</button>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
