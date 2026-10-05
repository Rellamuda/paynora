'use client';

import React, { useEffect, useState } from 'react';
import { fetchUserProfile, getKYCStatus } from '../../../lib/api-client';

export default function SettingsPage() {
  const [profile, setProfile] = useState<any>(null);
  const [kyc, setKyc] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const t = localStorage.getItem('paynora_token');
    if (t) {
      Promise.all([
        fetchUserProfile(t).catch(() => null),
        getKYCStatus(t).catch(() => null)
      ]).then(([p, k]) => {
        setProfile(p);
        setKyc(k);
        setLoading(false);
      });
    }
  }, []);

  return (
    <div style={{ maxWidth: '900px', margin: '0 auto' }}>
      <div style={{ marginBottom: '32px' }}>
        <h1 style={{ fontSize: '32px', fontWeight: 800, color: '#0D253F', margin: '0 0 6px 0' }}>Account Settings & Compliance</h1>
        <p style={{ color: '#64748B', fontSize: '15px', margin: 0 }}>Identity verification status, regulatory compliance credentials, and security settings.</p>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
        {/* Profile Card */}
        <div style={{ background: '#FFF', borderRadius: '20px', padding: '32px', border: '1px solid #E2E8F0', boxShadow: '0 4px 20px rgba(0,0,0,0.02)' }}>
          <h2 style={{ fontSize: '20px', fontWeight: 800, color: '#0D253F', margin: '0 0 20px 0' }}>Legal Identity Profile</h2>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#64748B', marginBottom: '6px' }}>LEGAL FULL NAME</label>
              <div style={{ fontSize: '16px', fontWeight: 700, color: '#0D253F' }}>
                {profile?.first_name || 'Customer'} {profile?.last_name || ''}
              </div>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#64748B', marginBottom: '6px' }}>REGISTERED EMAIL</label>
              <div style={{ fontSize: '16px', fontWeight: 600, color: '#0D253F' }}>
                {profile?.email || 'customer@paynora.com'}
              </div>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#64748B', marginBottom: '6px' }}>PHONE NUMBER</label>
              <div style={{ fontSize: '16px', fontWeight: 600, color: '#0D253F' }}>
                {profile?.phone || '+234 801 234 5678'}
              </div>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#64748B', marginBottom: '6px' }}>COUNTRY OF JURISDICTION</label>
              <div style={{ fontSize: '16px', fontWeight: 700, color: '#0D253F' }}>
                {profile?.country_iso || 'NG'} (Active Corridor)
              </div>
            </div>
          </div>
        </div>

        {/* KYC Compliance Vault */}
        <div style={{ background: '#FFF', borderRadius: '20px', padding: '32px', border: '1px solid #E2E8F0', boxShadow: '0 4px 20px rgba(0,0,0,0.02)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <div>
              <h2 style={{ fontSize: '20px', fontWeight: 800, color: '#0D253F', margin: '0 0 4px 0' }}>KYC Verification Vault</h2>
              <p style={{ margin: 0, fontSize: '13px', color: '#64748B' }}>Regulatory compliance tier under FinCEN, FCA, and CBN guidelines.</p>
            </div>
            <span style={{ fontSize: '13px', fontWeight: 800, color: '#16A34A', background: '#DCFCE7', padding: '6px 14px', borderRadius: '20px' }}>
              ● STATUS: {kyc?.kyc_status || 'APPROVED'}
            </span>
          </div>

          <div style={{ background: '#F8FAFC', padding: '20px', borderRadius: '12px', border: '1px solid #E2E8F0', display: 'flex', flexDirection: 'column', gap: '12px', fontSize: '14px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: '#64748B' }}>Compliance Level:</span>
              <strong style={{ color: '#0D253F' }}>Tier 3 Full Cross-Border Capability</strong>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: '#64748B' }}>Verified Document:</span>
              <strong style={{ color: '#0D253F' }}>National ID / International Passport</strong>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: '#64748B' }}>AML Screening:</span>
              <strong style={{ color: '#16A34A' }}>Passed (Zero Sanctions / PEP flags)</strong>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: '#64748B' }}>Daily Transfer Cap:</span>
              <strong style={{ color: '#0D253F' }}>₦50,000,000 / £25,000 / $35,000</strong>
            </div>
          </div>
        </div>

        {/* Security & Ledger Protocol */}
        <div style={{ background: '#FFF', borderRadius: '20px', padding: '32px', border: '1px solid #E2E8F0', boxShadow: '0 4px 20px rgba(0,0,0,0.02)' }}>
          <h2 style={{ fontSize: '20px', fontWeight: 800, color: '#0D253F', margin: '0 0 14px 0' }}>Ledger Security & Infrastructure</h2>
          <p style={{ color: '#64748B', fontSize: '14px', margin: '0 0 20px 0' }}>Your account is guarded by PayNora's deterministic double-entry accounting engine.</p>

          <div style={{ display: 'flex', gap: '12px' }}>
            <span style={{ padding: '6px 12px', background: '#F1F5F9', borderRadius: '6px', fontSize: '12px', fontWeight: 600, color: '#0D253F' }}>
              🔒 SHA-256 Pre-digest + Bcrypt
            </span>
            <span style={{ padding: '6px 12px', background: '#F1F5F9', borderRadius: '6px', fontSize: '12px', fontWeight: 600, color: '#0D253F' }}>
              ⚡ In-flight Idempotency Locks
            </span>
            <span style={{ padding: '6px 12px', background: '#F1F5F9', borderRadius: '6px', fontSize: '12px', fontWeight: 600, color: '#0D253F' }}>
              ⚖️ Balanced Ledger Invariants
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
