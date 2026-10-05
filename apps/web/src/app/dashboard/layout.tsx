'use client';

import React, { useEffect, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { fetchUserProfile, getKYCStatus } from '../../lib/api-client';
import { useTheme } from '../../lib/theme-context';

const NAV_ITEMS = [
  { label: 'Overview', href: '/dashboard', icon: '📊' },
  { label: 'Send Money', href: '/dashboard/send', icon: '💸' },
  { label: 'Wallets & Balances', href: '/dashboard/wallets', icon: '👛' },
  { label: 'Currency Exchange', href: '/dashboard/exchange', icon: '🔄' },
  { label: 'Recipients', href: '/dashboard/recipients', icon: '👥' },
  { label: 'Transactions', href: '/dashboard/transactions', icon: '📜' },
  { label: 'PayNora AI', href: '/dashboard/ai', icon: '✨' },
  { label: 'Settings & KYC', href: '/dashboard/settings', icon: '⚙️' }
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const { theme, toggleTheme, isDark } = useTheme();
  const [profile, setProfile] = useState<any>(null);
  const [kycStatus, setKycStatus] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem('paynora_token');
    if (!token) {
      router.push('/onboarding');
      return;
    }

    Promise.all([
      fetchUserProfile(token).catch(() => null),
      getKYCStatus(token).catch(() => null)
    ]).then(([p, k]) => {
      setProfile(p);
      setKycStatus(k);
      setLoading(false);
    });
  }, [router]);

  const handleLogout = () => {
    localStorage.removeItem('paynora_token');
    localStorage.removeItem('paynora_user_email');
    router.push('/');
  };

  if (loading) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'var(--bg-app)', fontFamily: 'Inter, sans-serif' }}>
        <div style={{ textAlign: 'center' }}>
          <img src="/logo.png" alt="PayNora" style={{ width: '56px', height: '56px', borderRadius: '14px', marginBottom: '12px' }} />
          <div style={{ fontSize: '24px', fontWeight: 800, color: '#00A3FF' }}>PayNora</div>
          <div style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '4px' }}>Synchronizing financial core...</div>
        </div>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: 'var(--bg-app)', fontFamily: 'Inter, sans-serif' }}>
      {/* Permanent Left Sidebar Navigation */}
      <aside style={{ width: '260px', background: isDark ? '#000000' : '#0D253F', color: '#FFF', display: 'flex', flexDirection: 'column', borderRight: `1px solid ${isDark ? '#1A1A1A' : '#1E3A5F'}`, flexShrink: 0 }}>
        {/* Brand with New Official Logo */}
        <div style={{ padding: '20px 24px', borderBottom: '1px solid rgba(255,255,255,0.08)' }}>
          <a href="/dashboard" style={{ textDecoration: 'none', display: 'flex', alignItems: 'center', gap: '12px' }}>
            <img src="/logo.png" alt="PayNora Logo" style={{ width: '38px', height: '38px', borderRadius: '10px' }} />
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span style={{ fontSize: '20px', fontWeight: 800, color: '#FFF', letterSpacing: '-0.5px' }}>PayNora</span>
                <span style={{ fontSize: '10px', fontWeight: 700, color: '#00A3FF', background: 'rgba(0,163,255,0.15)', padding: '2px 6px', borderRadius: '4px' }}>GLOBAL</span>
              </div>
              <div style={{ fontSize: '11px', color: '#888', marginTop: '2px' }}>Money Movement Platform</div>
            </div>
          </a>
        </div>

        {/* User Card */}
        <div style={{ padding: '18px 24px', borderBottom: '1px solid rgba(255,255,255,0.08)', background: 'rgba(255,255,255,0.02)' }}>
          <div style={{ fontSize: '14px', fontWeight: 700, color: '#FFF' }}>
            {profile?.first_name || 'Customer'} {profile?.last_name || ''}
          </div>
          <div style={{ fontSize: '12px', color: '#888', marginBottom: '8px' }}>{profile?.email || 'user@paynora.com'}</div>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: '5px', fontSize: '11px', fontWeight: 700, color: '#00A3FF', background: 'rgba(0,163,255,0.15)', padding: '3px 8px', borderRadius: '12px' }}>
            ● KYC {kycStatus?.kyc_status || 'APPROVED'}
          </div>
        </div>

        {/* Navigation Links */}
        <nav style={{ flex: 1, padding: '18px 12px', display: 'flex', flexDirection: 'column', gap: '4px', overflowY: 'auto' }}>
          {NAV_ITEMS.map((item) => {
            const isActive = pathname === item.href;
            return (
              <a
                key={item.href}
                href={item.href}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  padding: '12px 16px',
                  borderRadius: '10px',
                  fontSize: '14px',
                  fontWeight: isActive ? 700 : 500,
                  color: isActive ? '#FFF' : '#888',
                  background: isActive ? '#00A3FF' : 'transparent',
                  textDecoration: 'none',
                  transition: 'background 0.2s ease, color 0.2s ease'
                }}
              >
                <span style={{ fontSize: '18px' }}>{item.icon}</span>
                <span>{item.label}</span>
              </a>
            );
          })}
        </nav>

        {/* Bottom Actions */}
        <div style={{ padding: '16px 20px', borderTop: '1px solid rgba(255,255,255,0.08)', display: 'flex', flexDirection: 'column', gap: '10px' }}>
          {/* Theme toggle in sidebar */}
          <button
            onClick={toggleTheme}
            style={{
              width: '100%',
              padding: '9px 12px',
              background: 'rgba(255,255,255,0.06)',
              color: '#FFF',
              border: '1px solid rgba(255,255,255,0.1)',
              borderRadius: '8px',
              fontSize: '12px',
              fontWeight: 600,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '6px'
            }}
          >
            {isDark ? '☀️ Switch to Light' : '🌙 Pure Dark Mode'}
          </button>
          <button
            onClick={handleLogout}
            style={{ width: '100%', padding: '9px', background: 'rgba(255,255,255,0.06)', color: '#AAA', border: 'none', borderRadius: '8px', fontSize: '12px', fontWeight: 600, cursor: 'pointer', textAlign: 'center' }}
          >
            Log Out
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0, overflowY: 'auto' }}>
        {/* Top Header Bar */}
        <header style={{ background: 'var(--bg-header)', borderBottom: '1px solid var(--border-color)', padding: '16px 36px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', transition: 'background 0.2s' }}>
          <div style={{ fontSize: '15px', fontWeight: 600, color: 'var(--text-main)', display: 'flex', alignItems: 'center', gap: '8px' }}>
            Authoritative Financial Core: <span style={{ color: '#00A3FF', fontWeight: 700 }}>Online & Synchronized</span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            {/* Prominent Theme Toggle Button */}
            <button
              onClick={toggleTheme}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '8px',
                padding: '8px 14px',
                background: isDark ? 'rgba(255,255,255,0.08)' : '#F1F5F9',
                color: 'var(--text-main)',
                border: '1px solid var(--border-color)',
                borderRadius: '8px',
                fontSize: '13px',
                fontWeight: 600,
                cursor: 'pointer',
                transition: 'all 0.2s ease'
              }}
              title="Toggle Theme"
            >
              <span>{isDark ? '🌙' : '☀️'}</span>
              <span>{isDark ? 'Pure Dark' : 'Light Mode'}</span>
            </button>

            <a
              href="/dashboard/send"
              style={{ padding: '9px 16px', background: '#00A3FF', color: '#FFF', borderRadius: '8px', textDecoration: 'none', fontSize: '13px', fontWeight: 700 }}
            >
              💸 Send Money
            </a>
            <a
              href="/dashboard/wallets"
              style={{ padding: '9px 16px', background: isDark ? '#141414' : '#0D253F', border: `1px solid ${isDark ? '#262626' : 'transparent'}`, color: '#FFF', borderRadius: '8px', textDecoration: 'none', fontSize: '13px', fontWeight: 700 }}
            >
              + Deposit
            </a>
            <a
              href="/dashboard/ai"
              style={{ padding: '9px 16px', background: isDark ? 'rgba(0,163,255,0.12)' : '#EDE9FE', color: '#00A3FF', border: isDark ? '1px solid rgba(0,163,255,0.3)' : 'none', borderRadius: '8px', textDecoration: 'none', fontSize: '13px', fontWeight: 700 }}
            >
              ✨ Nora AI
            </a>
          </div>
        </header>

        {/* Page Content */}
        <main style={{ padding: '36px' }}>{children}</main>
      </div>
    </div>
  );
}
