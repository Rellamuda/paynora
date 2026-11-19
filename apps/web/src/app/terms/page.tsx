'use client';

import React from 'react';

export default function TermsOfServicePage() {
  return (
    <div style={{ minHeight: '100vh', background: '#070E1A', color: '#F8FAFC', fontFamily: 'Inter, system-ui, sans-serif', padding: '48px 20px' }}>
      <div style={{ maxWidth: '820px', margin: '0 auto', background: '#0F1B31', borderRadius: '20px', padding: '36px', border: '1px solid rgba(255,255,255,0.08)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
          <h1 style={{ fontSize: '28px', fontWeight: 900, margin: 0 }}>Terms of Service &amp; Fee Transparency</h1>
          <a href="../" style={{ color: '#00C853', textDecoration: 'none', fontWeight: 700, fontSize: '14px' }}>← Back to PayNora</a>
        </div>
        <p style={{ color: '#94A3B8', fontSize: '13px' }}>Effective Date: November 2026 · PayNora Global Money Movement Platform</p>

        <h3 style={{ color: '#00C853', marginTop: '24px' }}>1. Regulatory &amp; Partner Disclosure</h3>
        <p style={{ color: '#CBD5E1', lineHeight: 1.7, fontSize: '14px' }}>
          PayNora is a financial technology application, not a commercial bank. Payment collection, card acquiring, bank account resolution, and payout settlement services are provided through licensed PCI-DSS Level 1 payment processors <strong>Paystack</strong> and <strong>Flutterwave</strong>.
        </p>

        <h3 style={{ color: '#00C853', marginTop: '24px' }}>2. Double-Currency Wallet Architecture</h3>
        <p style={{ color: '#CBD5E1', lineHeight: 1.7, fontSize: '14px' }}>
          Every registered user is provisioned strictly two digital wallets based on their Country of Residence: (1) their country&apos;s official Local Currency Wallet and (2) a USD Foreign Currency Wallet (or GBP for residents of the United States and USD-based jurisdictions), along with a unique 10-digit PayNora Account Number and @tag.
        </p>

        <h3 style={{ color: '#00C853', marginTop: '24px' }}>3. Transparent Fee Schedule</h3>
        <ul style={{ color: '#CBD5E1', lineHeight: 1.8, fontSize: '14px' }}>
          <li><strong>PayNora-to-PayNora App Transfer (Same Currency):</strong> 0.0% fee</li>
          <li><strong>PayNora-to-PayNora App Transfer (Cross-Currency FX):</strong> 0.3% FX spread</li>
          <li><strong>International Bank &amp; Mobile Money Payout:</strong> 0.5% FX spread</li>
          <li><strong>Local Commercial Bank Transfer (Same Currency):</strong> 0.0% FX conversion fee</li>
          <li><strong>One-Tap Bill Reversal (Airtime / Data / Electricity):</strong> 100% full refund to Local Currency Wallet</li>
          <li><strong>Bill-to-Cash Converter (Airtime / Data / Electricity):</strong> 90% instant cash payout (10% conversion fee)</li>
        </ul>

        <h3 style={{ color: '#00C853', marginTop: '24px' }}>4. Support &amp; Dispute Resolution</h3>
        <p style={{ color: '#CBD5E1', lineHeight: 1.7, fontSize: '14px' }}>
          For transaction disputes, reversals, or customer support, contact our 24/7 compliance desk at <strong>support@paynora.com</strong>.
        </p>
      </div>
    </div>
  );
}
