'use client';

import React, { useState, useEffect } from 'react';
import { fetchFXQuote } from '../../../lib/api-client';

const CORRIDORS = [
  { pair: 'NGN / GBP', rate: '0.00052', flag1: '🇳🇬', flag2: '🇬🇧', spread: '0.5%' },
  { pair: 'NGN / USD', rate: '0.00065', flag1: '🇳🇬', flag2: '🇺🇸', spread: '0.5%' },
  { pair: 'GBP / NGN', rate: '1923.08', flag1: '🇬🇧', flag2: '🇳🇬', spread: '0.5%' },
  { pair: 'USD / NGN', rate: '1538.46', flag1: '🇺🇸', flag2: '🇳🇬', spread: '0.5%' },
  { pair: 'EUR / NGN', rate: '1666.67', flag1: '🇪🇺', flag2: '🇳🇬', spread: '0.5%' },
  { pair: 'CAD / NGN', rate: '1120.50', flag1: '🇨🇦', flag2: '🇳🇬', spread: '0.5%' },
  { pair: 'AED / NGN', rate: '418.90', flag1: '🇦🇪', flag2: '🇳🇬', spread: '0.5%' },
  { pair: 'GHS / NGN', rate: '98.50', flag1: '🇬🇭', flag2: '🇳🇬', spread: '0.5%' },
  { pair: 'ZAR / NGN', rate: '85.20', flag1: '🇿🇦', flag2: '🇳🇬', spread: '0.5%' }
];

export default function ExchangePage() {
  const [sourceCurr, setSourceCurr] = useState('NGN');
  const [destCurr, setDestCurr] = useState('GBP');
  const [amount, setAmount] = useState('1000000');
  const [quote, setQuote] = useState<any>(null);

  useEffect(() => {
    if (amount && Number(amount) > 0) {
      const timer = setTimeout(async () => {
        try {
          const res = await fetchFXQuote(sourceCurr, destCurr, amount);
          setQuote(res);
        } catch (e) {
          console.error(e);
        }
      }, 300);
      return () => clearTimeout(timer);
    }
  }, [amount, sourceCurr, destCurr]);

  return (
    <div style={{ maxWidth: '1000px', margin: '0 auto' }}>
      <div style={{ marginBottom: '32px' }}>
        <h1 style={{ fontSize: '32px', fontWeight: 800, color: '#0D253F', margin: '0 0 6px 0' }}>Foreign Exchange (FX) Markets</h1>
        <p style={{ color: '#64748B', fontSize: '15px', margin: 0 }}>Mid-market real-time exchange rates with guaranteed 10-minute rate lock.</p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1.8fr', gap: '30px', marginBottom: '40px' }}>
        {/* Converter Card */}
        <div style={{ background: '#FFF', borderRadius: '20px', padding: '32px', border: '1px solid #E2E8F0', boxShadow: '0 4px 20px rgba(0,0,0,0.03)' }}>
          <h2 style={{ fontSize: '20px', fontWeight: 800, color: '#0D253F', margin: '0 0 20px 0' }}>Live Rate Calculator</h2>

          <div style={{ marginBottom: '16px' }}>
            <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>Amount</label>
            <input
              type="number"
              value={amount}
              onChange={e => setAmount(e.target.value)}
              style={{ width: '100%', padding: '12px', fontSize: '16px', border: '1px solid #CBD5E1', borderRadius: '8px', boxSizing: 'border-box' }}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '24px' }}>
            <div>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>From</label>
              <select value={sourceCurr} onChange={e => setSourceCurr(e.target.value)} style={{ width: '100%', padding: '12px', fontSize: '15px', border: '1px solid #CBD5E1', borderRadius: '8px', background: '#FFF' }}>
                <option value="NGN">NGN (₦)</option>
                <option value="GBP">GBP (£)</option>
                <option value="USD">USD ($)</option>
                <option value="EUR">EUR (€)</option>
              </select>
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>To</label>
              <select value={destCurr} onChange={e => setDestCurr(e.target.value)} style={{ width: '100%', padding: '12px', fontSize: '15px', border: '1px solid #CBD5E1', borderRadius: '8px', background: '#FFF' }}>
                <option value="GBP">GBP (£)</option>
                <option value="USD">USD ($)</option>
                <option value="EUR">EUR (€)</option>
                <option value="CAD">CAD (C$)</option>
                <option value="AED">AED (د.إ)</option>
                <option value="NGN">NGN (₦)</option>
              </select>
            </div>
          </div>

          {quote && (
            <div style={{ background: '#F8FAFC', padding: '20px', borderRadius: '12px', border: '1px solid #E2E8F0', marginBottom: '24px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', color: '#64748B', marginBottom: '8px' }}>
                <span>Guaranteed Rate:</span>
                <strong>1 {quote.source_currency} = {quote.exchange_rate} {quote.destination_currency}</strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', color: '#64748B', marginBottom: '8px' }}>
                <span>Spread Fee:</span>
                <strong>{quote.fee} {quote.source_currency} (0.5%)</strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '18px', color: '#0D253F', fontWeight: 800, marginTop: '10px', paddingTop: '10px', borderTop: '1px solid #CBD5E1' }}>
                <span>Converted Output:</span>
                <span style={{ color: '#00C853' }}>{quote.destination_amount} {quote.destination_currency}</span>
              </div>
            </div>
          )}

          <a
            href="/dashboard/send"
            style={{ display: 'block', textAlign: 'center', width: '100%', padding: '14px', background: '#0D253F', color: '#FFF', borderRadius: '10px', textDecoration: 'none', fontWeight: 700, boxSizing: 'border-box' }}
          >
            Lock Rate & Send Now →
          </a>
        </div>

        {/* Live Rates Board */}
        <div style={{ background: '#FFF', borderRadius: '20px', padding: '32px', border: '1px solid #E2E8F0', boxShadow: '0 4px 20px rgba(0,0,0,0.03)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <h2 style={{ fontSize: '20px', fontWeight: 800, color: '#0D253F', margin: 0 }}>Active Corridor Rates</h2>
            <span style={{ fontSize: '11px', fontWeight: 700, color: '#00C853', background: '#E8F5E9', padding: '3px 8px', borderRadius: '6px' }}>
              ● LIVE STREAMING
            </span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {CORRIDORS.map((c, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 18px', background: '#F8FAFC', borderRadius: '12px', border: '1px solid #E2E8F0' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <span style={{ fontSize: '22px' }}>{c.flag1} ➔ {c.flag2}</span>
                  <span style={{ fontWeight: 700, fontSize: '14px', color: '#0D253F' }}>{c.pair}</span>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontWeight: 800, fontSize: '15px', color: '#0D253F' }}>{c.rate}</div>
                  <div style={{ fontSize: '11px', color: '#64748B' }}>Spread: {c.spread}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
