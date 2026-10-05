'use client';

import React, { useState, useEffect } from 'react';
import { fetchBeneficiaries, fetchFXQuote, createTransfer } from '../../../lib/api-client';

export default function SendMoneyPage() {
  const [token, setToken] = useState<string | null>(null);
  const [beneficiaries, setBeneficiaries] = useState<any[]>([]);
  const [recipient, setRecipient] = useState('');
  const [amount, setAmount] = useState('250000');
  const [sourceCurrency, setSourceCurrency] = useState('NGN');
  const [destCurrency, setDestCurrency] = useState('GBP');
  const [fxQuote, setFxQuote] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [successTx, setSuccessTx] = useState<any>(null);

  useEffect(() => {
    const t = localStorage.getItem('paynora_token');
    if (t) {
      setToken(t);
      fetchBeneficiaries(t).then(res => setBeneficiaries(res.beneficiaries || []));
    }
  }, []);

  useEffect(() => {
    if (amount && Number(amount) > 0) {
      const timer = setTimeout(async () => {
        try {
          const q = await fetchFXQuote(sourceCurrency, destCurrency, amount);
          setFxQuote(q);
        } catch (e) {
          console.error(e);
        }
      }, 300);
      return () => clearTimeout(timer);
    }
  }, [amount, sourceCurrency, destCurrency]);

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!token) return;
    setLoading(true);
    try {
      const idemp = `send_${Date.now()}_${Math.random().toString(36).substring(7)}`;
      const res = await createTransfer({
        source_currency: sourceCurrency,
        source_amount: amount,
        recipient_name: recipient || (beneficiaries[0]?.name || 'John Doe'),
        source_country: 'NG',
        destination_country: destCurrency === 'GBP' ? 'GB' : 'US',
        recipient_currency_mode: 'CHOICE'
      }, idemp, token);
      setSuccessTx(res);
    } catch (err: any) {
      alert(err.message || 'Transfer failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: '800px', margin: '0 auto' }}>
      <div style={{ marginBottom: '32px' }}>
        <h1 style={{ fontSize: '32px', fontWeight: 800, color: '#0D253F', margin: '0 0 8px 0' }}>Send Money Internationally</h1>
        <p style={{ color: '#64748B', fontSize: '16px', margin: 0 }}>Instant cross-border payment rails with guaranteed FX locked rates and zero hidden fees.</p>
      </div>

      {successTx ? (
        <div style={{ background: '#FFF', borderRadius: '20px', padding: '40px', border: '1px solid #E2E8F0', textAlign: 'center' }}>
          <div style={{ width: '64px', height: '64px', background: '#DCFCE7', color: '#16A34A', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '32px', margin: '0 auto 20px auto' }}>
            ✓
          </div>
          <h2 style={{ fontSize: '24px', fontWeight: 800, color: '#0D253F', marginBottom: '8px' }}>Transfer Dispatched Successfully!</h2>
          <p style={{ color: '#64748B', marginBottom: '24px' }}>
            Your transfer of <strong>{successTx.source_amount} {successTx.source_currency}</strong> to <strong>{successTx.recipient_name}</strong> is currently processing through the clearing network.
          </p>

          <div style={{ background: '#F8FAFC', padding: '20px', borderRadius: '12px', textAlign: 'left', marginBottom: '30px', fontSize: '14px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
              <span style={{ color: '#64748B' }}>Reference ID:</span>
              <strong style={{ color: '#0D253F' }}>{successTx.transfer_id}</strong>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
              <span style={{ color: '#64748B' }}>Settlement State:</span>
              <span style={{ color: '#7C3AED', fontWeight: 700 }}>{successTx.state}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: '#64748B' }}>Corridor:</span>
              <strong>{successTx.source_country} ➔ {successTx.destination_country}</strong>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '14px', justifyContent: 'center' }}>
            <button
              onClick={() => setSuccessTx(null)}
              style={{ padding: '14px 28px', background: '#0D253F', color: '#FFF', borderRadius: '10px', border: 'none', fontWeight: 700, cursor: 'pointer' }}
            >
              Send Another Transfer
            </button>
            <a
              href="/dashboard/transactions"
              style={{ padding: '14px 28px', background: '#F1F5F9', color: '#0D253F', borderRadius: '10px', textDecoration: 'none', fontWeight: 700, border: '1px solid #CBD5E1' }}
            >
              View In Ledger
            </a>
          </div>
        </div>
      ) : (
        <form onSubmit={handleSend} style={{ background: '#FFF', borderRadius: '20px', padding: '36px', border: '1px solid #E2E8F0', boxShadow: '0 4px 20px rgba(0,0,0,0.03)' }}>
          {/* Recipient Selection */}
          <div style={{ marginBottom: '24px' }}>
            <label style={{ display: 'block', fontSize: '14px', fontWeight: 700, color: '#334155', marginBottom: '8px' }}>Select or Enter Recipient</label>
            <input
              type="text"
              placeholder="Recipient Legal Name"
              value={recipient}
              onChange={e => setRecipient(e.target.value)}
              list="beneficiaries-list"
              style={{ width: '100%', padding: '14px 16px', fontSize: '16px', border: '1.5px solid #CBD5E1', borderRadius: '10px', boxSizing: 'border-box' }}
              required
            />
            <datalist id="beneficiaries-list">
              {beneficiaries.map((b, i) => (
                <option key={i} value={b.name} />
              ))}
            </datalist>
          </div>

          {/* Amount Inputs */}
          <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '16px', marginBottom: '24px' }}>
            <div>
              <label style={{ display: 'block', fontSize: '14px', fontWeight: 700, color: '#334155', marginBottom: '8px' }}>Sending Amount</label>
              <input
                type="number"
                value={amount}
                onChange={e => setAmount(e.target.value)}
                style={{ width: '100%', padding: '14px 16px', fontSize: '16px', border: '1.5px solid #CBD5E1', borderRadius: '10px', boxSizing: 'border-box' }}
                required
              />
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '14px', fontWeight: 700, color: '#334155', marginBottom: '8px' }}>Source Currency</label>
              <select
                value={sourceCurrency}
                onChange={e => setSourceCurrency(e.target.value)}
                style={{ width: '100%', padding: '14px 16px', fontSize: '16px', border: '1.5px solid #CBD5E1', borderRadius: '10px', background: '#FFF' }}
              >
                <option value="NGN">NGN (₦)</option>
                <option value="GBP">GBP (£)</option>
                <option value="USD">USD ($)</option>
                <option value="EUR">EUR (€)</option>
              </select>
            </div>
          </div>

          <div style={{ marginBottom: '28px' }}>
            <label style={{ display: 'block', fontSize: '14px', fontWeight: 700, color: '#334155', marginBottom: '8px' }}>Recipient Currency</label>
            <select
              value={destCurrency}
              onChange={e => setDestCurrency(e.target.value)}
              style={{ width: '100%', padding: '14px 16px', fontSize: '16px', border: '1.5px solid #CBD5E1', borderRadius: '10px', background: '#FFF' }}
            >
              <option value="GBP">GBP — British Pound (£) 🇬🇧</option>
              <option value="USD">USD — US Dollar ($) 🇺🇸</option>
              <option value="EUR">EUR — Euro (€) 🇪🇺</option>
              <option value="CAD">CAD — Canadian Dollar ($) 🇨🇦</option>
              <option value="AED">AED — UAE Dirham 🇦🇪</option>
              <option value="NGN">NGN — Nigerian Naira (₦) 🇳🇬</option>
            </select>
          </div>

          {/* Guaranteed Rate Box */}
          {fxQuote && (
            <div style={{ background: '#F8FAFC', padding: '24px', borderRadius: '14px', border: '1px solid #E2E8F0', marginBottom: '32px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px', color: '#64748B', marginBottom: '8px' }}>
                <span>Locked Exchange Rate:</span>
                <strong style={{ color: '#0D253F' }}>1 {fxQuote.source_currency} = {fxQuote.exchange_rate} {fxQuote.destination_currency}</strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px', color: '#64748B', marginBottom: '8px' }}>
                <span>Transparent Network Fee:</span>
                <strong style={{ color: '#0D253F' }}>{fxQuote.fee} {fxQuote.source_currency}</strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '18px', color: '#0D253F', fontWeight: 800, marginTop: '14px', paddingTop: '14px', borderTop: '1px solid #CBD5E1' }}>
                <span>Recipient Gets Exactly:</span>
                <span style={{ color: '#00C853' }}>{fxQuote.destination_amount} {fxQuote.destination_currency}</span>
              </div>
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            style={{ width: '100%', padding: '18px', background: '#00C853', color: '#FFF', fontSize: '16px', fontWeight: 700, borderRadius: '12px', border: 'none', cursor: 'pointer', boxShadow: '0 4px 15px rgba(0,200,83,0.3)' }}
          >
            {loading ? 'Dispatched to Clearing House...' : 'Authorize & Send Transfer Now →'}
          </button>
        </form>
      )}
    </div>
  );
}
