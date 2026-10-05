'use client';

import React, { useEffect, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { fetchUserProfile, getKYCStatus } from '../../lib/api-client';

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
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#F8FAFC', fontFamily: 'Inter, sans-serif' }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: '28px', fontWeight: 800, color: '#0D253F', marginBottom: '8px' }}>PayNora</div>
          <div style={{ fontSize: '14px', color: '#64748B' }}>Loading financial core workspace...</div>
        </div>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: '#F8FAFC', fontFamily: 'Inter, sans-serif' }}>
      {/* Permanent Left Sidebar Navigation */}
      <aside style={{ width: '260px', background: '#0D253F', color: '#FFF', display: 'flex', flexDirection: 'column', borderRight: '1px solid #1E3A5F', flexShrink: 0 }}>
        {/* Brand */}
        <div style={{ padding: '24px', borderBottom: '1px solid rgba(255,255,255,0.08)' }}>
          <a href="/dashboard" style={{ textDecoration: 'none', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '26px', fontWeight: 800, color: '#FFF', letterSpacing: '-0.5px' }}>PayNora</span>
            <span style={{ fontSize: '11px', fontWeight: 700, color: '#00C853', background: 'rgba(0,200,83,0.15)', padding: '2px 8px', borderRadius: '6px' }}>FINTECH</span>
          </a>
          <div style={{ fontSize: '11px', color: '#94A3B8', marginTop: '6px' }}>Global Money Movement Platform</div>
        </div>

        {/* User Card */}
        <div style={{ padding: '20px 24px', borderBottom: '1px solid rgba(255,255,255,0.08)', background: 'rgba(255,255,255,0.03)' }}>
          <div style={{ fontSize: '14px', fontWeight: 700, color: '#FFF' }}>
            {profile?.first_name || 'Customer'} {profile?.last_name || ''}
          </div>
          <div style={{ fontSize: '12px', color: '#94A3B8', marginBottom: '8px' }}>{profile?.email || 'user@paynora.com'}</div>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: '5px', fontSize: '11px', fontWeight: 700, color: '#00C853', background: 'rgba(0,200,83,0.15)', padding: '3px 8px', borderRadius: '12px' }}>
            ● KYC {kycStatus?.kyc_status || 'APPROVED'}
          </div>
        </div>

        {/* Navigation Links */}
        <nav style={{ flex: 1, padding: '20px 12px', display: 'flex', flexDirection: 'column', gap: '4px', overflowY: 'auto' }}>
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
                  color: isActive ? '#FFF' : '#94A3B8',
                  background: isActive ? '#00C853' : 'transparent',
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
        <div style={{ padding: '16px 20px', borderTop: '1px solid rgba(255,255,255,0.08)' }}>
          <button
            onClick={handleLogout}
            style={{ width: '100%', padding: '10px', background: 'rgba(255,255,255,0.08)', color: '#CBD5E1', border: 'none', borderRadius: '8px', fontSize: '13px', fontWeight: 600, cursor: 'pointer', textAlign: 'center' }}
          >
            Log Out
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0, overflowY: 'auto' }}>
        {/* Top Header Bar */}
        <header style={{ background: '#FFF', borderBottom: '1px solid #E2E8F0', padding: '16px 36px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ fontSize: '16px', fontWeight: 600, color: '#334155' }}>
            Authoritative Financial Core: <span style={{ color: '#00C853', fontWeight: 700 }}>Online & Synchronized</span>
          </div>

          <div style={{ display: 'flex', gap: '12px' }}>
            <a
              href="/dashboard/send"
              style={{ padding: '10px 18px', background: '#00C853', color: '#FFF', borderRadius: '8px', textDecoration: 'none', fontSize: '13px', fontWeight: 700 }}
            >
              💸 Send Money
            </a>
            <a
              href="/dashboard/wallets"
              style={{ padding: '10px 18px', background: '#0D253F', color: '#FFF', borderRadius: '8px', textDecoration: 'none', fontSize: '13px', fontWeight: 700 }}
            >
              + Deposit Funds
            </a>
            <a
              href="/dashboard/ai"
              style={{ padding: '10px 18px', background: '#EDE9FE', color: '#6C5CE7', borderRadius: '8px', textDecoration: 'none', fontSize: '13px', fontWeight: 700 }}
            >
              ✨ PayNora AI
            </a>
          </div>
        </header>

        {/* Page Content */}
        <main style={{ padding: '36px' }}>{children}</main>
      </div>
    </div>
  );
}
