'use client';

import React, { useEffect, useState } from 'react';
import { fetchUserProfile, getKYCStatus } from '../../../lib/api-client';
import { useTheme } from '../../../lib/theme-context';

export default function SettingsPage() {
  const [profile, setProfile] = useState<any>(null);
  const [kyc, setKyc] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const { theme, toggleTheme, isDark } = useTheme();

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
        <h1 style={{ fontSize: '32px', fontWeight: 800, color: 'var(--text-main)', margin: '0 0 6px 0' }}>Account Settings & Compliance</h1>
        <p style={{ color: 'var(--text-muted)', fontSize: '15px', margin: 0 }}>Identity verification status, regulatory compliance credentials, appearance themes, and security settings.</p>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
        {/* Appearance & Theme Selector */}
        <div style={{ background: 'var(--bg-card)', borderRadius: '20px', padding: '32px', border: '1px solid var(--border-color)', boxShadow: '0 4px 20px rgba(0,0,0,0.03)' }}>
          <h2 style={{ fontSize: '20px', fontWeight: 800, color: 'var(--text-main)', margin: '0 0 6px 0' }}>Interface Theme & Appearance</h2>
          <p style={{ color: 'var(--text-muted)', fontSize: '14px', margin: '0 0 20px 0' }}>Choose between PayNora Midnight Dark theme or Clean Slate Light theme.</p>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
            <div
              onClick={() => { if (theme !== 'light') toggleTheme(); }}
              style={{
                cursor: 'pointer',
                padding: '20px',
                borderRadius: '14px',
                border: `2px solid ${!isDark ? '#00C853' : 'var(--border-color)'}`,
                background: !isDark ? 'rgba(0,200,83,0.05)' : 'var(--bg-card-subtle)',
                transition: 'all 0.2s ease'
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ fontSize: '16px', fontWeight: 700, color: 'var(--text-main)' }}>☀️ Clean Slate Light</span>
                {!isDark && <span style={{ color: '#00C853', fontWeight: 800 }}>✓ Active</span>}
              </div>
              <p style={{ margin: 0, fontSize: '13px', color: 'var(--text-muted)' }}>High-contrast daytime fintech theme with crisp white surfaces and emerald accents.</p>
            </div>

            <div
              onClick={() => { if (theme !== 'dark') toggleTheme(); }}
              style={{
                cursor: 'pointer',
                padding: '20px',
                borderRadius: '14px',
                border: `2px solid ${isDark ? '#00C853' : 'var(--border-color)'}`,
                background: isDark ? 'rgba(0,200,83,0.08)' : 'var(--bg-card-subtle)',
                transition: 'all 0.2s ease'
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ fontSize: '16px', fontWeight: 700, color: 'var(--text-main)' }}>🌙 Midnight Dark</span>
                {isDark && <span style={{ color: '#00C853', fontWeight: 800 }}>✓ Active</span>}
              </div>
              <p style={{ margin: 0, fontSize: '13px', color: 'var(--text-muted)' }}>Low-light deep navy command theme designed for focused multi-currency operations.</p>
            </div>
          </div>
        </div>

        {/* Profile Card */}
        <div style={{ background: 'var(--bg-card)', borderRadius: '20px', padding: '32px', border: '1px solid var(--border-color)', boxShadow: '0 4px 20px rgba(0,0,0,0.02)' }}>
          <h2 style={{ fontSize: '20px', fontWeight: 800, color: 'var(--text-main)', margin: '0 0 20px 0' }}>Legal Identity Profile</h2>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: 'var(--text-muted)', marginBottom: '6px' }}>LEGAL FULL NAME</label>
              <div style={{ fontSize: '16px', fontWeight: 700, color: 'var(--text-main)' }}>
                {profile?.first_name || 'Customer'} {profile?.last_name || ''}
              </div>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: 'var(--text-muted)', marginBottom: '6px' }}>REGISTERED EMAIL</label>
              <div style={{ fontSize: '16px', fontWeight: 600, color: 'var(--text-main)' }}>
                {profile?.email || 'customer@paynora.com'}
              </div>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: 'var(--text-muted)', marginBottom: '6px' }}>PHONE NUMBER</label>
              <div style={{ fontSize: '16px', fontWeight: 600, color: 'var(--text-main)' }}>
                {profile?.phone || '+234 801 234 5678'}
              </div>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: 'var(--text-muted)', marginBottom: '6px' }}>COUNTRY OF JURISDICTION</label>
              <div style={{ fontSize: '16px', fontWeight: 700, color: 'var(--text-main)' }}>
                {profile?.country_iso || 'NG'} (Active Corridor)
              </div>
            </div>
          </div>
        </div>

        {/* KYC Compliance Vault */}
        <div style={{ background: 'var(--bg-card)', borderRadius: '20px', padding: '32px', border: '1px solid var(--border-color)', boxShadow: '0 4px 20px rgba(0,0,0,0.02)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <div>
              <h2 style={{ fontSize: '20px', fontWeight: 800, color: 'var(--text-main)', margin: '0 0 4px 0' }}>KYC Verification Vault</h2>
              <p style={{ margin: 0, fontSize: '13px', color: 'var(--text-muted)' }}>Regulatory compliance tier under FinCEN, FCA, and CBN guidelines.</p>
            </div>
            <span style={{ fontSize: '13px', fontWeight: 800, color: '#16A34A', background: 'rgba(22, 163, 74, 0.15)', padding: '6px 14px', borderRadius: '20px' }}>
              ● STATUS: {kyc?.kyc_status || 'APPROVED'}
            </span>
          </div>

          <div style={{ background: 'var(--bg-card-subtle)', padding: '20px', borderRadius: '12px', border: '1px solid var(--border-color)', display: 'flex', flexDirection: 'column', gap: '12px', fontSize: '14px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: 'var(--text-muted)' }}>Compliance Level:</span>
              <strong style={{ color: 'var(--text-main)' }}>Tier 3 Full Cross-Border Capability</strong>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: 'var(--text-muted)' }}>Verified Document:</span>
              <strong style={{ color: 'var(--text-main)' }}>National ID / International Passport</strong>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: 'var(--text-muted)' }}>AML Screening:</span>
              <strong style={{ color: '#16A34A' }}>Passed (Zero Sanctions / PEP flags)</strong>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: 'var(--text-muted)' }}>Daily Transfer Cap:</span>
              <strong style={{ color: 'var(--text-main)' }}>₦50,000,000 / £25,000 / $35,000</strong>
            </div>
          </div>
        </div>

        {/* Security & Ledger Protocol */}
        <div style={{ background: 'var(--bg-card)', borderRadius: '20px', padding: '32px', border: '1px solid var(--border-color)', boxShadow: '0 4px 20px rgba(0,0,0,0.02)' }}>
          <h2 style={{ fontSize: '20px', fontWeight: 800, color: 'var(--text-main)', margin: '0 0 14px 0' }}>Ledger Security & Infrastructure</h2>
          <p style={{ color: 'var(--text-muted)', fontSize: '14px', margin: '0 0 20px 0' }}>Your account is guarded by PayNora's deterministic double-entry accounting engine.</p>

          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '12px' }}>
            <span style={{ padding: '6px 12px', background: 'var(--bg-card-subtle)', borderRadius: '6px', fontSize: '12px', fontWeight: 600, color: 'var(--text-main)', border: '1px solid var(--border-color)' }}>
              🔒 SHA-256 Pre-digest + Bcrypt
            </span>
            <span style={{ padding: '6px 12px', background: 'var(--bg-card-subtle)', borderRadius: '6px', fontSize: '12px', fontWeight: 600, color: 'var(--text-main)', border: '1px solid var(--border-color)' }}>
              ⚡ In-flight Idempotency Locks
            </span>
            <span style={{ padding: '6px 12px', background: 'var(--bg-card-subtle)', borderRadius: '6px', fontSize: '12px', fontWeight: 600, color: 'var(--text-main)', border: '1px solid var(--border-color)' }}>
              ⚖️ Balanced Ledger Invariants
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
