'use client';

import React from 'react';
import { useTheme } from '../../lib/theme-context';

export default function MobileRedirectAuthPage() {
  const { isDark, toggleTheme } = useTheme();

  const apkDownloadUrl = 'https://github.com/Rellamuda/paynora/releases/download/latest/PayNora.apk';
  const qrCodeUrl = `https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${encodeURIComponent(apkDownloadUrl)}`;

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'center',
      alignItems: 'center',
      padding: '32px 16px',
      background: isDark ? '#050B17' : '#F8FAFC',
      color: isDark ? '#F8FAFC' : '#0F172A',
      fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    }}>
      {/* Top Controls */}
      <div style={{ position: 'absolute', top: '24px', right: '24px', display: 'flex', gap: '10px' }}>
        <button
          onClick={toggleTheme}
          style={{
            padding: '8px 14px',
            background: isDark ? 'rgba(255,255,255,0.08)' : '#FFF',
            color: isDark ? '#FFF' : '#0F172A',
            border: `1px solid ${isDark ? '#1C2B4E' : '#E2E8F0'}`,
            borderRadius: '10px',
            fontSize: '13px',
            fontWeight: 600,
            cursor: 'pointer'
          }}
        >
          {isDark ? '🌙 Dark' : '☀️ Light'}
        </button>
      </div>

      {/* Main Card */}
      <div style={{
        width: '100%',
        maxWidth: '460px',
        background: isDark ? '#0D1A30' : '#FFFFFF',
        borderRadius: '24px',
        padding: '36px',
        boxShadow: isDark ? '0 25px 60px rgba(0,0,0,0.5)' : '0 20px 40px -15px rgba(0,0,0,0.07)',
        border: `1px solid ${isDark ? '#1C2B4E' : '#E2E8F0'}`,
        textAlign: 'center'
      }}>
        {/* Brand Icon */}
        <div style={{
          width: '60px',
          height: '60px',
          borderRadius: '18px',
          background: '#0D253F',
          margin: '0 auto 16px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          boxShadow: '0 8px 24px rgba(13, 37, 63, 0.35)'
        }}>
          <img src="/logo.png" alt="PayNora" style={{ width: '40px', height: '40px', borderRadius: '12px' }} />
        </div>

        <h2 style={{ fontSize: '24px', fontWeight: 900, margin: '0 0 6px', letterSpacing: '-0.5px' }}>
          Mobile-Only Security Vault
        </h2>

        {/* Security Badge */}
        <div style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: '6px',
          padding: '4px 12px',
          background: 'rgba(0, 200, 83, 0.12)',
          border: '1px solid rgba(0, 200, 83, 0.25)',
          borderRadius: '20px',
          fontSize: '11px',
          fontWeight: 800,
          color: '#00C853',
          marginBottom: '18px'
        }}>
          <span>🛡️</span>
          <span>HARDWARE BIOMETRIC SECURITY ARCHITECTURE</span>
        </div>

        <p style={{ fontSize: '14px', color: isDark ? '#94A3B8' : '#64748B', lineHeight: 1.6, margin: '0 0 24px' }}>
          For your safety, all <strong>PayNora account registration, KYC onboarding, and money movement</strong> are cryptographically sealed to physical mobile hardware. Browsers are excluded to prevent cookie theft and session hijacking.
        </p>

        {/* QR Code Container */}
        <div style={{
          background: '#FFFFFF',
          padding: '14px',
          borderRadius: '18px',
          display: 'inline-block',
          boxShadow: '0 8px 24px rgba(0,0,0,0.1)',
          marginBottom: '20px'
        }}>
          <img
            src={qrCodeUrl}
            alt="Scan to Download PayNora Mobile"
            style={{ width: '160px', height: '160px', display: 'block' }}
          />
        </div>

        <div style={{ fontSize: '12px', fontWeight: 700, color: isDark ? '#CBD5E1' : '#334155', marginBottom: '20px' }}>
          Scan with your phone camera or tap below to download:
        </div>

        {/* Action Button */}
        <a
          href={apkDownloadUrl}
          style={{
            display: 'block',
            width: '100%',
            padding: '15px',
            background: '#00C853',
            color: '#FFFFFF',
            borderRadius: '14px',
            fontSize: '15px',
            fontWeight: 800,
            textDecoration: 'none',
            boxShadow: '0 4px 16px rgba(0, 200, 83, 0.35)',
            boxSizing: 'border-box',
            marginBottom: '12px'
          }}
        >
          📲 Download PayNora APK (Android) →
        </a>

        <a
          href="/"
          style={{
            display: 'inline-block',
            fontSize: '13px',
            color: isDark ? '#94A3B8' : '#64748B',
            textDecoration: 'none',
            fontWeight: 600,
            marginTop: '8px'
          }}
        >
          ← Return to PayNora Homepage
        </a>
      </div>
    </div>
  );
}
