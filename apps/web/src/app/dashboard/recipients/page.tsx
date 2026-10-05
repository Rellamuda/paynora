'use client';

import React, { useEffect, useState } from 'react';
import { fetchBeneficiaries, createBeneficiary } from '../../../lib/api-client';

export default function RecipientsPage() {
  const [token, setToken] = useState<string | null>(null);
  const [beneficiaries, setBeneficiaries] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  // Add modal
  const [showAddModal, setShowAddModal] = useState(false);
  const [name, setName] = useState('');
  const [country, setCountry] = useState('GB');
  const [currency, setCurrency] = useState('GBP');
  const [accNumber, setAccNumber] = useState('');
  const [bankName, setBankName] = useState('');
  const [addLoading, setAddLoading] = useState(false);

  useEffect(() => {
    const t = localStorage.getItem('paynora_token');
    if (t) {
      setToken(t);
      loadBeneficiaries(t);
    }
  }, []);

  const loadBeneficiaries = async (t: string) => {
    setLoading(true);
    try {
      const res = await fetchBeneficiaries(t);
      setBeneficiaries(res.beneficiaries || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!token) return;
    setAddLoading(true);
    try {
      const newB = await createBeneficiary({
        name,
        country_iso: country,
        currency,
        account_details: {
          account_number: accNumber,
          bank_name: bankName || 'Standard Chartered'
        }
      }, token);
      setBeneficiaries(prev => [...prev, newB]);
      setShowAddModal(false);
      setName('');
      setAccNumber('');
      setBankName('');
    } catch (err: any) {
      alert(err.message || 'Failed to add recipient');
    } finally {
      setAddLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: '1000px', margin: '0 auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
        <div>
          <h1 style={{ fontSize: '32px', fontWeight: 800, color: '#0D253F', margin: '0 0 6px 0' }}>Saved Recipients Directory</h1>
          <p style={{ color: '#64748B', fontSize: '15px', margin: 0 }}>Verified individual and business bank payout accounts worldwide.</p>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          style={{ padding: '12px 24px', background: '#00C853', color: '#FFF', border: 'none', borderRadius: '10px', fontWeight: 700, cursor: 'pointer', boxShadow: '0 4px 15px rgba(0,200,83,0.3)' }}
        >
          + Add New Recipient
        </button>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '20px' }}>
        {beneficiaries.map((b, idx) => (
          <div key={idx} style={{ background: '#FFF', borderRadius: '16px', padding: '24px', border: '1px solid #E2E8F0', boxShadow: '0 4px 15px rgba(0,0,0,0.02)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
              <div style={{ fontWeight: 800, fontSize: '18px', color: '#0D253F' }}>{b.name}</div>
              <span style={{ fontSize: '12px', fontWeight: 700, color: '#0D253F', background: '#F1F5F9', padding: '3px 8px', borderRadius: '6px' }}>
                {b.country_iso} • {b.currency}
              </span>
            </div>

            <div style={{ fontSize: '13px', color: '#64748B', marginBottom: '20px' }}>
              Account: <code>{b.account_details?.account_number || '•••• 8921'}</code>
            </div>

            <a
              href={`/dashboard/send`}
              style={{ display: 'block', textAlign: 'center', width: '100%', padding: '10px', background: '#0D253F', color: '#FFF', textDecoration: 'none', borderRadius: '8px', fontSize: '13px', fontWeight: 700, boxSizing: 'border-box' }}
            >
              Send Money to {b.name.split(' ')[0]} →
            </a>
          </div>
        ))}
      </div>

      {/* ADD RECIPIENT MODAL */}
      {showAddModal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '20px' }}>
          <form onSubmit={handleAdd} style={{ background: '#FFF', borderRadius: '20px', width: '100%', maxWidth: '480px', padding: '32px' }}>
            <h3 style={{ margin: '0 0 14px 0', fontSize: '20px', fontWeight: 800, color: '#0D253F' }}>Add Verified Recipient</h3>
            <p style={{ color: '#64748B', fontSize: '14px', marginBottom: '20px' }}>Bank routing and account details for instant global payouts.</p>

            <div style={{ marginBottom: '14px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>Full Legal Name</label>
              <input
                type="text"
                placeholder="e.g. John Doe"
                value={name}
                onChange={e => setName(e.target.value)}
                style={{ width: '100%', padding: '12px', fontSize: '15px', border: '1px solid #CBD5E1', borderRadius: '8px', boxSizing: 'border-box' }}
                required
              />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '14px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>Country</label>
                <select value={country} onChange={e => setCountry(e.target.value)} style={{ width: '100%', padding: '12px', fontSize: '15px', border: '1px solid #CBD5E1', borderRadius: '8px', background: '#FFF' }}>
                  <option value="GB">United Kingdom 🇬🇧</option>
                  <option value="US">United States 🇺🇸</option>
                  <option value="CA">Canada 🇨🇦</option>
                  <option value="NG">Nigeria 🇳🇬</option>
                  <option value="AE">UAE 🇦🇪</option>
                </select>
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>Payout Currency</label>
                <select value={currency} onChange={e => setCurrency(e.target.value)} style={{ width: '100%', padding: '12px', fontSize: '15px', border: '1px solid #CBD5E1', borderRadius: '8px', background: '#FFF' }}>
                  <option value="GBP">GBP (£)</option>
                  <option value="USD">USD ($)</option>
                  <option value="CAD">CAD (C$)</option>
                  <option value="NGN">NGN (₦)</option>
                  <option value="AED">AED (د.إ)</option>
                </select>
              </div>
            </div>

            <div style={{ marginBottom: '24px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>Account Number / IBAN</label>
              <input
                type="text"
                placeholder="e.g. GB29NWBK60161331926819"
                value={accNumber}
                onChange={e => setAccNumber(e.target.value)}
                style={{ width: '100%', padding: '12px', fontSize: '15px', border: '1px solid #CBD5E1', borderRadius: '8px', boxSizing: 'border-box' }}
                required
              />
            </div>

            <div style={{ display: 'flex', gap: '10px' }}>
              <button type="button" onClick={() => setShowAddModal(false)} style={{ flex: 1, padding: '12px', background: '#F1F5F9', border: 'none', borderRadius: '8px', fontWeight: 600, cursor: 'pointer' }}>Cancel</button>
              <button type="submit" disabled={addLoading} style={{ flex: 1, padding: '12px', background: '#00C853', color: '#FFF', border: 'none', borderRadius: '8px', fontWeight: 700, cursor: 'pointer' }}>
                {addLoading ? 'Saving...' : 'Save Recipient'}
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
