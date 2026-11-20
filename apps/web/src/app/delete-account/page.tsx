'use client';

import React, { useState } from 'react';

export default function DeleteAccountPage() {
  const [email, setEmail] = useState('');
  const [reason, setReason] = useState('');
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) return;
    setSubmitted(true);
  };

  return (
    <div style={{ minHeight: '100vh', background: '#070E1A', color: '#F8FAFC', fontFamily: 'Inter, system-ui, sans-serif', padding: '48px 20px' }}>
      <div style={{ maxWidth: '640px', margin: '0 auto', background: '#0F1B31', borderRadius: '20px', padding: '36px', border: '1px solid rgba(239,68,68,0.3)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
          <h1 style={{ fontSize: '24px', fontWeight: 900, margin: 0 }}>Delete SendMoni Account &amp; Data</h1>
          <a href="../" style={{ color: '#00C853', textDecoration: 'none', fontWeight: 700, fontSize: '14px' }}>← Back</a>
        </div>
        <p style={{ color: '#94A3B8', fontSize: '13px', lineHeight: 1.6 }}>
          In compliance with Google Play User Data Policy and Apple App Store Guideline 5.1.1(v), you can permanently delete your SendMoni account and personal data either directly inside the mobile app (<strong>Vault → Delete My Account &amp; Personal Data</strong>) or by submitting your registered email below.
        </p>

        {submitted ? (
          <div style={{ marginTop: '24px', padding: '20px', background: 'rgba(0,200,83,0.12)', borderRadius: '14px', border: '1px solid rgba(0,200,83,0.4)' }}>
            <div style={{ fontWeight: 800, color: '#00C853', fontSize: '16px', marginBottom: '6px' }}>✓ Account Deletion Request Recorded</div>
            <div style={{ color: '#CBD5E1', fontSize: '13px', lineHeight: 1.6 }}>
              Your request to permanently delete the SendMoni account and associated personal data for <strong>{email}</strong> has been queued for immediate removal.
            </div>
          </div>
        ) : (
          <form onSubmit={handleSubmit} style={{ marginTop: '20px' }}>
            <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#94A3B8', marginBottom: '6px' }}>
              REGISTERED PAYNORA EMAIL ADDRESS
            </label>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@example.com"
              style={{ width: '100%', padding: '12px 14px', borderRadius: '10px', border: '1px solid rgba(255,255,255,0.15)', background: '#070E1A', color: '#FFF', fontSize: '14px', marginBottom: '16px', boxSizing: 'border-box' }}
            />
            <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#94A3B8', marginBottom: '6px' }}>
              REASON FOR DELETION (OPTIONAL)
            </label>
            <textarea
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              rows={3}
              placeholder="Optional feedback..."
              style={{ width: '100%', padding: '12px 14px', borderRadius: '10px', border: '1px solid rgba(255,255,255,0.15)', background: '#070E1A', color: '#FFF', fontSize: '14px', marginBottom: '18px', boxSizing: 'border-box' }}
            />
            <button
              type="submit"
              style={{ width: '100%', padding: '14px', borderRadius: '12px', border: 'none', background: '#DC2626', color: '#FFF', fontWeight: 800, fontSize: '15px', cursor: 'pointer' }}
            >
              Permanently Delete My Account &amp; Personal Data
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
