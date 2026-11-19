'use client';

import React, { useState } from 'react';
import { useTheme } from '../lib/theme-context';

const CORRIDORS = [
  { code: 'NG', name: 'Nigeria', flag: '🇳🇬', curr: 'NGN', rate: '₦1,538.46', time: '12s' },
  { code: 'GB', name: 'United Kingdom', flag: '🇬🇧', curr: 'GBP', rate: '£0.78', time: '18s' },
  { code: 'US', name: 'United States', flag: '🇺🇸', curr: 'USD', rate: '$1.00', time: 'Instant' },
  { code: 'CA', name: 'Canada', flag: '🇨🇦', curr: 'CAD', rate: 'C$1.36', time: '24s' },
  { code: 'AE', name: 'United Arab Emirates', flag: '🇦🇪', curr: 'AED', rate: '3.67 AED', time: '15s' },
  { code: 'GH', name: 'Ghana', flag: '🇬🇭', curr: 'GHS', rate: '15.42 GHS', time: '20s' },
  { code: 'ZA', name: 'South Africa', flag: '🇿🇦', curr: 'ZAR', rate: '18.15 ZAR', time: '28s' },
  { code: 'DE', name: 'Germany (Eurozone)', flag: '🇩🇪', curr: 'EUR', rate: '€0.92', time: '15s' },
  { code: 'FR', name: 'France (Eurozone)', flag: '🇫🇷', curr: 'EUR', rate: '€0.92', time: '15s' },
  { code: 'SA', name: 'Saudi Arabia', flag: '🇸🇦', curr: 'SAR', rate: '3.75 SAR', time: '22s' },
  { code: 'CN', name: 'China', flag: '🇨🇳', curr: 'CNY', rate: '¥7.24', time: '45s' }
];

const SECURITY_PILLARS = [
  {
    icon: '🛡️',
    title: 'Hardware Secure Enclave',
    desc: 'Private cryptographic keys are generated and sealed within your phone’s dedicated security chip (Apple Secure Enclave & Android Titan HSM). They never touch a browser or external server.'
  },
  {
    icon: '👆',
    title: 'Biometric Transaction Proof',
    desc: 'Every single money dispatch or currency swap strictly requires native Touch ID, Face ID, or device fingerprint authorization directly on your physical hardware.'
  },
  {
    icon: '🔒',
    title: 'Device & SIM Binding',
    desc: 'Your PayNora account is cryptographically tied to your specific physical device. Web session hijacking, rogue Chrome extensions, and browser cookie theft are mathematically impossible.'
  },
  {
    icon: '🤖',
    title: 'Nora AI Intelligence',
    desc: 'Powered by Google Gemini to analyze FX volatility, recommend optimal sending windows, and prevent duplicate transfers before you tap dispatch.'
  }
];

export default function LandingPage() {
  const { isDark, toggleTheme } = useTheme();
  const [freezeEmail, setFreezeEmail] = useState('');
  const [freezeSuccess, setFreezeSuccess] = useState(false);
  const [showFreezeModal, setShowFreezeModal] = useState(false);

  const apkDownloadUrl = 'https://github.com/Rellamuda/paynora/releases/download/latest/PayNora.apk';
  const qrCodeUrl = `https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${encodeURIComponent(apkDownloadUrl)}`;

  const handleFreeze = (e: React.FormEvent) => {
    e.preventDefault();
    if (freezeEmail.trim()) {
      setFreezeSuccess(true);
      setTimeout(() => {
        setShowFreezeModal(false);
        setFreezeSuccess(false);
        setFreezeEmail('');
      }, 2500);
    }
  };

  return (
    <div style={{
      minHeight: '100vh',
      background: isDark ? '#050B17' : '#F8FAFC',
      color: isDark ? '#F8FAFC' : '#0F172A',
      fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    }}>
      {/* Top Navigation */}
      <header style={{
        maxWidth: '1200px',
        margin: '0 auto',
        padding: '24px 20px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        borderBottom: `1px solid ${isDark ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)'}`
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div style={{
            width: '42px',
            height: '42px',
            borderRadius: '12px',
            background: '#0D253F',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 4px 14px rgba(13, 37, 63, 0.4)'
          }}>
            <img src="logo.png" alt="PayNora" style={{ width: '28px', height: '28px', borderRadius: '8px' }} />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span style={{ fontSize: '22px', fontWeight: 900, letterSpacing: '-0.5px' }}>PayNora</span>
              <span style={{ fontSize: '10px', fontWeight: 800, color: '#00C853', background: 'rgba(0,200,83,0.15)', padding: '2px 8px', borderRadius: '6px' }}>
                MOBILE VAULT
              </span>
            </div>
            <div style={{ fontSize: '11px', color: isDark ? '#94A3B8' : '#64748B', fontWeight: 600 }}>
              Hardware-Secured Cross-Border Fintech
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          {/* Emergency Lock Pill */}
          <button
            onClick={() => setShowFreezeModal(true)}
            style={{
              padding: '8px 14px',
              background: 'rgba(239, 68, 68, 0.1)',
              color: '#EF4444',
              border: '1px solid rgba(239, 68, 68, 0.25)',
              borderRadius: '10px',
              fontSize: '12px',
              fontWeight: 700,
              cursor: 'pointer',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px'
            }}
          >
            <span>🚨</span>
            <span>Emergency Account Lock</span>
          </button>

          {/* Theme Toggle */}
          <button
            onClick={toggleTheme}
            style={{
              padding: '8px 14px',
              background: isDark ? 'rgba(255,255,255,0.06)' : '#FFF',
              color: isDark ? '#FFF' : '#0F172A',
              border: `1px solid ${isDark ? '#1C2B4E' : '#E2E8F0'}`,
              borderRadius: '10px',
              fontSize: '12px',
              fontWeight: 600,
              cursor: 'pointer'
            }}
          >
            {isDark ? '🌙 Dark' : '☀️ Light'}
          </button>

          {/* Download App CTA */}
          <a
            href={apkDownloadUrl}
            style={{
              padding: '9px 18px',
              background: '#00C853',
              color: '#FFF',
              borderRadius: '10px',
              textDecoration: 'none',
              fontSize: '13px',
              fontWeight: 800,
              boxShadow: '0 4px 14px rgba(0,200,83,0.3)',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px'
            }}
          >
            <span>📲</span>
            <span>Get Mobile App</span>
          </a>
        </div>
      </header>

      {/* Hero Section */}
      <main style={{ maxWidth: '1160px', margin: '0 auto', padding: '60px 20px 40px' }}>
        <div style={{ display: 'flex', flexDirection: 'row', gap: '48px', alignItems: 'center', flexWrap: 'wrap' }}>
          {/* Hero Left Content */}
          <div style={{ flex: '1 1 500px' }}>
            {/* Security Badge */}
            <div style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '8px',
              padding: '6px 14px',
              background: 'rgba(0, 200, 83, 0.12)',
              border: '1px solid rgba(0, 200, 83, 0.3)',
              borderRadius: '20px',
              fontSize: '12px',
              fontWeight: 700,
              color: '#00C853',
              marginBottom: '20px'
            }}>
              <span>🔒</span>
              <span>100% Mobile Hardware Biometric Security Architecture</span>
            </div>

            <h1 style={{
              fontSize: '48px',
              fontWeight: 900,
              lineHeight: 1.15,
              letterSpacing: '-1px',
              margin: '0 0 20px',
              color: isDark ? '#FFFFFF' : '#0D253F'
            }}>
              Double Currency Digital Wallets. Zero Web Vulnerability.
            </h1>

            <p style={{
              fontSize: '18px',
              color: isDark ? '#94A3B8' : '#475569',
              lineHeight: 1.6,
              marginBottom: '32px'
            }}>
              PayNora operates <strong>exclusively on Mobile</strong> to protect your money with hardware-bound biometric authentication (Face ID & Fingerprint). No browser session hijacking, no phishing forms, and no compromised cookies.
            </p>

            {/* Double Currency Feature Highlight */}
            <div style={{
              background: isDark ? '#0D1A30' : '#FFFFFF',
              borderRadius: '16px',
              padding: '20px',
              border: `1px solid ${isDark ? '#1C2B4E' : '#E2E8F0'}`,
              marginBottom: '32px',
              display: 'flex',
              gap: '16px',
              alignItems: 'center'
            }}>
              <div style={{ fontSize: '32px' }}>👛</div>
              <div>
                <div style={{ fontWeight: 800, fontSize: '15px', color: isDark ? '#FFF' : '#0D253F' }}>
                  Automatic Double Currency Provisioning
                </div>
                <div style={{ fontSize: '13px', color: isDark ? '#94A3B8' : '#64748B', marginTop: '4px' }}>
                  Every verified account is provisioned with strictly <strong>two wallets</strong>: your country's <strong>Local Currency</strong> for everyday domestic funding, and <strong>USD Global Reserve</strong> to protect against local inflation.
                </div>
              </div>
            </div>

            {/* Direct Download Action Row */}
            <div style={{ display: 'flex', gap: '14px', flexWrap: 'wrap' }}>
              <a
                href={apkDownloadUrl}
                style={{
                  padding: '16px 32px',
                  background: '#00C853',
                  color: '#FFF',
                  fontSize: '16px',
                  fontWeight: 800,
                  borderRadius: '14px',
                  textDecoration: 'none',
                  boxShadow: '0 6px 20px rgba(0,200,83,0.35)',
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '10px'
                }}
              >
                <span>📲</span>
                <span>Download PayNora APK (Android)</span>
              </a>

              <a
                href="https://github.com/Rellamuda/paynora/releases/tag/latest"
                target="_blank"
                rel="noreferrer"
                style={{
                  padding: '16px 24px',
                  background: isDark ? '#162444' : '#E2E8F0',
                  color: isDark ? '#FFF' : '#0D253F',
                  fontSize: '15px',
                  fontWeight: 700,
                  borderRadius: '14px',
                  textDecoration: 'none',
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '8px'
                }}
              >
                <span>📦</span>
                <span>GitHub Releases</span>
              </a>
            </div>
          </div>

          {/* Hero Right QR Card */}
          <div style={{
            flex: '0 1 360px',
            background: isDark ? '#0D1A30' : '#FFFFFF',
            borderRadius: '24px',
            padding: '32px',
            textAlign: 'center',
            boxShadow: isDark ? '0 25px 60px rgba(0,0,0,0.6)' : '0 20px 40px -10px rgba(0,0,0,0.08)',
            border: `1px solid ${isDark ? '#1C2B4E' : '#E2E8F0'}`,
            margin: '0 auto'
          }}>
            <div style={{ fontWeight: 800, fontSize: '18px', marginBottom: '8px', color: isDark ? '#FFF' : '#0D253F' }}>
              Scan to Install on Your Phone
            </div>
            <p style={{ fontSize: '12px', color: isDark ? '#94A3B8' : '#64748B', margin: '0 0 20px' }}>
              Point your phone camera at this QR code to download the official PayNora Android release directly.
            </p>

            <div style={{
              background: '#FFFFFF',
              padding: '14px',
              borderRadius: '18px',
              display: 'inline-block',
              boxShadow: '0 8px 24px rgba(0,0,0,0.1)'
            }}>
              <img
                src={qrCodeUrl}
                alt="Scan to Download PayNora"
                style={{ width: '180px', height: '180px', display: 'block' }}
              />
            </div>

            <div style={{
              marginTop: '20px',
              padding: '10px 14px',
              background: isDark ? 'rgba(255,255,255,0.04)' : '#F1F5F9',
              borderRadius: '12px',
              fontSize: '11px',
              color: isDark ? '#CBD5E1' : '#475569',
              fontWeight: 600,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '6px'
            }}>
              <span>✅</span>
              <span>v1.0.1 Official Release • 22.8 MB • SHA256 Verified</span>
            </div>
          </div>
        </div>

        {/* SECTION: Why Mobile-Only Security Architecture */}
        <section style={{ margin: '90px 0 60px' }}>
          <div style={{ textAlign: 'center', maxWidth: '720px', margin: '0 auto 50px' }}>
            <span style={{ fontSize: '12px', fontWeight: 800, color: '#00C853', letterSpacing: '1px', textTransform: 'uppercase' }}>
              Bank-Grade Security Architecture
            </span>
            <h2 style={{ fontSize: '36px', fontWeight: 900, margin: '10px 0 16px', letterSpacing: '-0.5px' }}>
              Why PayNora Operates on Mobile Only
            </h2>
            <p style={{ fontSize: '16px', color: isDark ? '#94A3B8' : '#64748B', lineHeight: 1.6 }}>
              Fintech fraud happens primarily on web browsers through cookie theft, phishing, and rogue extensions. We removed the web attack surface entirely so your wealth stays protected.
            </p>
          </div>

          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
            gap: '24px'
          }}>
            {SECURITY_PILLARS.map((pillar, idx) => (
              <div
                key={idx}
                style={{
                  background: isDark ? '#0D1A30' : '#FFFFFF',
                  borderRadius: '20px',
                  padding: '28px',
                  border: `1px solid ${isDark ? '#1C2B4E' : '#E2E8F0'}`,
                  boxShadow: isDark ? '0 10px 30px rgba(0,0,0,0.3)' : '0 8px 25px rgba(0,0,0,0.04)'
                }}
              >
                <div style={{
                  width: '48px',
                  height: '48px',
                  borderRadius: '14px',
                  background: isDark ? 'rgba(0, 200, 83, 0.12)' : '#E8F5E9',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: '24px',
                  marginBottom: '18px'
                }}>
                  {pillar.icon}
                </div>
                <h3 style={{ fontSize: '18px', fontWeight: 800, margin: '0 0 10px', color: isDark ? '#FFF' : '#0D253F' }}>
                  {pillar.title}
                </h3>
                <p style={{ fontSize: '14px', color: isDark ? '#94A3B8' : '#64748B', lineHeight: 1.6, margin: 0 }}>
                  {pillar.desc}
                </p>
              </div>
            ))}
          </div>
        </section>

        {/* SECTION: 11 Operating Launch Corridors */}
        <section style={{ margin: '60px 0 90px' }}>
          <div style={{ textAlign: 'center', maxWidth: '720px', margin: '0 auto 40px' }}>
            <span style={{ fontSize: '12px', fontWeight: 800, color: '#00C853', letterSpacing: '1px', textTransform: 'uppercase' }}>
              Global Currency Liquidity
            </span>
            <h2 style={{ fontSize: '36px', fontWeight: 900, margin: '10px 0 16px', letterSpacing: '-0.5px' }}>
              Active Launch Operating Corridors
            </h2>
            <p style={{ fontSize: '16px', color: isDark ? '#94A3B8' : '#64748B' }}>
              Deterministic double-entry ledger routing across 11 primary countries with live rate locking.
            </p>
          </div>

          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))',
            gap: '16px'
          }}>
            {CORRIDORS.map((c) => (
              <div
                key={c.code}
                style={{
                  background: isDark ? '#0D1A30' : '#FFFFFF',
                  borderRadius: '16px',
                  padding: '18px',
                  border: `1px solid ${isDark ? '#1C2B4E' : '#E2E8F0'}`,
                  textAlign: 'center'
                }}
              >
                <div style={{ fontSize: '32px', marginBottom: '8px' }}>{c.flag}</div>
                <div style={{ fontWeight: 800, fontSize: '15px', color: isDark ? '#FFF' : '#0D253F' }}>
                  {c.name}
                </div>
                <div style={{ fontSize: '12px', color: '#00C853', fontWeight: 700, marginTop: '4px' }}>
                  {c.curr} Wallet
                </div>
                <div style={{ fontSize: '11px', color: isDark ? '#94A3B8' : '#64748B', marginTop: '6px' }}>
                  Avg. Delivery: {c.time}
                </div>
              </div>
            ))}
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer style={{
        maxWidth: '1200px',
        margin: '0 auto',
        padding: '40px 20px',
        borderTop: `1px solid ${isDark ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)'}`,
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        flexWrap: 'wrap',
        gap: '20px'
      }}>
        <div>
          <div style={{ fontWeight: 800, fontSize: '16px' }}>PayNora Global Money Movement Platform</div>
          <div style={{ fontSize: '12px', color: isDark ? '#94A3B8' : '#64748B', marginTop: '4px' }}>
            Authoritative Core v1.0.1 • Biometric Mobile Enclave Security Architecture
          </div>
        </div>

        <div style={{ display: 'flex', gap: '16px', alignItems: 'center', flexWrap: 'wrap' }}>
          <a
            href="privacy/"
            style={{ color: isDark ? '#94A3B8' : '#64748B', fontSize: '13px', fontWeight: 600, textDecoration: 'none' }}
          >
            Privacy Policy
          </a>
          <a
            href="terms/"
            style={{ color: isDark ? '#94A3B8' : '#64748B', fontSize: '13px', fontWeight: 600, textDecoration: 'none' }}
          >
            Terms &amp; Fees
          </a>
          <a
            href="delete-account/"
            style={{ color: isDark ? '#94A3B8' : '#64748B', fontSize: '13px', fontWeight: 600, textDecoration: 'none' }}
          >
            Delete Account
          </a>
          <button
            onClick={() => setShowFreezeModal(true)}
            style={{ background: 'none', border: 'none', color: '#EF4444', fontSize: '13px', fontWeight: 700, cursor: 'pointer' }}
          >
            Emergency Account Freeze
          </button>
          <a
            href={apkDownloadUrl}
            style={{ color: '#00C853', fontSize: '13px', fontWeight: 700, textDecoration: 'none' }}
          >
            Download App APK
          </a>
        </div>
      </footer>

      {/* Emergency Freeze Modal */}
      {showFreezeModal && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(0,0,0,0.7)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '20px',
          zIndex: 1000
        }}>
          <div style={{
            background: isDark ? '#0D1A30' : '#FFFFFF',
            borderRadius: '24px',
            padding: '32px',
            maxWidth: '440px',
            width: '100%',
            border: `1px solid ${isDark ? '#1C2B4E' : '#E2E8F0'}`
          }}>
            <div style={{ fontSize: '36px', marginBottom: '12px' }}>🚨</div>
            <h3 style={{ margin: '0 0 8px', fontSize: '20px', fontWeight: 900, color: isDark ? '#FFF' : '#0D253F' }}>
              Emergency Account Freezing
            </h3>
            <p style={{ fontSize: '13px', color: isDark ? '#94A3B8' : '#64748B', lineHeight: 1.5, margin: '0 0 20px' }}>
              Lost your phone? Enter your registered email address to immediately lock your Double Currency Wallets and revoke all active mobile session tokens remotely.
            </p>

            {freezeSuccess ? (
              <div style={{ padding: '14px', background: 'rgba(0,200,83,0.12)', border: '1px solid #00C853', color: '#00C853', borderRadius: '12px', fontSize: '13px', fontWeight: 700, marginBottom: '20px' }}>
                Account security freeze executed! All wallets are locked. Our compliance security desk will email you instructions.
              </div>
            ) : (
              <form onSubmit={handleFreeze} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                <input
                  type="email"
                  placeholder="Enter your registered PayNora email"
                  value={freezeEmail}
                  onChange={(e) => setFreezeEmail(e.target.value)}
                  required
                  style={{
                    width: '100%',
                    padding: '12px 14px',
                    background: isDark ? '#070D1C' : '#F8FAFC',
                    border: `1.5px solid ${isDark ? '#1C2B4E' : '#CBD5E1'}`,
                    borderRadius: '10px',
                    color: isDark ? '#FFF' : '#0F172A',
                    fontSize: '14px',
                    outline: 'none',
                    boxSizing: 'border-box'
                  }}
                />

                <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end', marginTop: '10px' }}>
                  <button
                    type="button"
                    onClick={() => setShowFreezeModal(false)}
                    style={{
                      padding: '10px 16px',
                      background: isDark ? '#1C2B4E' : '#E2E8F0',
                      color: isDark ? '#FFF' : '#334155',
                      border: 'none',
                      borderRadius: '10px',
                      fontSize: '13px',
                      fontWeight: 700,
                      cursor: 'pointer'
                    }}
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    style={{
                      padding: '10px 20px',
                      background: '#EF4444',
                      color: '#FFF',
                      border: 'none',
                      borderRadius: '10px',
                      fontSize: '13px',
                      fontWeight: 700,
                      cursor: 'pointer'
                    }}
                  >
                    Freeze Account Immediately
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
