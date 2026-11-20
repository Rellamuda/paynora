'use client';

import React from 'react';

export default function PrivacyPolicyPage() {
  return (
    <div style={{ minHeight: '100vh', background: '#070E1A', color: '#F8FAFC', fontFamily: 'Inter, system-ui, sans-serif', padding: '48px 20px' }}>
      <div style={{ maxWidth: '820px', margin: '0 auto', background: '#0F1B31', borderRadius: '20px', padding: '36px', border: '1px solid rgba(255,255,255,0.08)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
          <h1 style={{ fontSize: '28px', fontWeight: 900, margin: 0 }}>SendMoni Privacy Policy & Data Safety</h1>
          <a href="../" style={{ color: '#00C853', textDecoration: 'none', fontWeight: 700, fontSize: '14px' }}>← Back to SendMoni</a>
        </div>
        <p style={{ color: '#94A3B8', fontSize: '13px' }}>Effective Date: November 2026 · Compliant with GDPR, NDPR, CCPA, Apple App Store & Google Play User Data Policies</p>

        <h3 style={{ color: '#00C853', marginTop: '24px' }}>1. Information We Collect</h3>
        <p style={{ color: '#CBD5E1', lineHeight: 1.7, fontSize: '14px' }}>
          SendMoni collects your legal full name, email address, phone number, country of residence, and optional KYC identity document strictly to provision your Double-Currency Digital Wallets (Local Currency + USD/GBP), assign your unique 10-digit SendMoni Account Number and @tag, verify identity under Anti-Money Laundering (AML) regulations, and execute money transfers and utility bill payments.
        </p>

        <h3 style={{ color: '#00C853', marginTop: '24px' }}>2. Payment Card & Bank Processing (Paystack & Flutterwave)</h3>
        <p style={{ color: '#CBD5E1', lineHeight: 1.7, fontSize: '14px' }}>
          SendMoni never stores raw credit/debit card numbers, PINs, or CVV security codes on its servers. All card deposits, bank transfers, USSD collections, and mobile money transactions are processed directly by PCI-DSS Level 1 certified licensed payment gateway partners <strong>Paystack</strong> and <strong>Flutterwave</strong>.
        </p>

        <h3 style={{ color: '#00C853', marginTop: '24px' }}>3. Data Encryption & Mobile Hardware Enclave</h3>
        <p style={{ color: '#CBD5E1', lineHeight: 1.7, fontSize: '14px' }}>
          SendMoni operates a Mobile-Only transaction architecture. All data in transit is encrypted using TLS 1.3, and authentication tokens are stored inside your mobile device&apos;s hardware-backed Secure Storage (Keychain / Keystore). We never sell or rent user data to third-party advertisers.
        </p>

        <h3 style={{ color: '#00C853', marginTop: '24px' }}>4. Account & Personal Data Deletion Rights</h3>
        <p style={{ color: '#CBD5E1', lineHeight: 1.7, fontSize: '14px' }}>
          You may permanently delete your SendMoni account, wallets, and personal data at any time directly inside the mobile app (<strong>Vault / Settings → Delete My Account &amp; Personal Data</strong>) or via our web deletion portal at <a href="../delete-account/" style={{ color: '#00C853' }}>/delete-account</a>.
        </p>

        <h3 style={{ color: '#00C853', marginTop: '24px' }}>5. Contact & Data Protection Desk</h3>
        <p style={{ color: '#CBD5E1', lineHeight: 1.7, fontSize: '14px' }}>
          For privacy inquiries, data subject access requests, or regulatory compliance questions, contact: <strong>support@paynora.com</strong>
        </p>
      </div>
    </div>
  );
}
