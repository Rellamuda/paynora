'use client';

import React, { useEffect, useState } from 'react';
import { fetchWallets, activateWallet, fundWallet, convertWallet, fetchFXQuote } from '../../../lib/api-client';

const SUPPORTED_CURRENCIES = [
  { code: 'NGN', name: 'Nigerian Naira', flag: '🇳🇬', symbol: '₦' },
  { code: 'GBP', name: 'British Pound', flag: '🇬🇧', symbol: '£' },
  { code: 'USD', name: 'US Dollar', flag: '🇺🇸', symbol: '$' },
  { code: 'EUR', name: 'Euro', flag: '🇪🇺', symbol: '€' },
  { code: 'CAD', name: 'Canadian Dollar', flag: '🇨🇦', symbol: 'C$' },
  { code: 'AED', name: 'UAE Dirham', flag: '🇦🇪', symbol: 'د.إ' },
  { code: 'GHS', name: 'Ghanaian Cedi', flag: '🇬🇭', symbol: '₵' },
  { code: 'ZAR', name: 'South African Rand', flag: '🇿🇦', symbol: 'R' },
  { code: 'CNY', name: 'Chinese Yuan', flag: '🇨🇳', symbol: '¥' },
  { code: 'SAR', name: 'Saudi Riyal', flag: '🇸🇦', symbol: '﷼' }
];

export default function WalletsPage() {
  const [token, setToken] = useState<string | null>(null);
  const [wallets, setWallets] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  // Deposit modal
  const [showFundModal, setShowFundModal] = useState(false);
  const [fundCurrency, setFundCurrency] = useState('NGN');
  const [fundAmount, setFundAmount] = useState('100000');
  const [fundLoading, setFundLoading] = useState(false);

  // Convert modal
  const [showConvertModal, setShowConvertModal] = useState(false);
  const [fromCurr, setFromCurr] = useState('NGN');
  const [toCurr, setToCurr] = useState('GBP');
  const [convertAmount, setConvertAmount] = useState('100000');
  const [convertedQuote, setConvertedQuote] = useState<any>(null);
  const [convertLoading, setConvertLoading] = useState(false);

  // Activate wallet modal
  const [showActivateModal, setShowActivateModal] = useState(false);
  const [activateCurrency, setActivateCurrency] = useState('CAD');

  useEffect(() => {
    const t = localStorage.getItem('paynora_token');
    if (t) {
      setToken(t);
      loadWallets(t);
    }
  }, []);

  const loadWallets = async (t: string) => {
    setLoading(true);
    try {
      const data = await fetchWallets(t);
      setWallets(data.wallets || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (convertAmount && Number(convertAmount) > 0) {
      const timer = setTimeout(async () => {
        try {
          const q = await fetchFXQuote(fromCurr, toCurr, convertAmount);
          setConvertedQuote(q);
        } catch (e) {
          console.error(e);
        }
      }, 300);
      return () => clearTimeout(timer);
    }
  }, [convertAmount, fromCurr, toCurr]);

  const handleFund = async () => {
    if (!token) return;
    setFundLoading(true);
    try {
      await fundWallet(fundCurrency, fundAmount, token);
      await loadWallets(token);
      setShowFundModal(false);
    } catch (err: any) {
      alert(err.message || 'Deposit failed');
    } finally {
      setFundLoading(false);
    }
  };

  const handleConvert = async () => {
    if (!token || !convertedQuote) return;
    setConvertLoading(true);
    try {
      await convertWallet(
        fromCurr,
        toCurr,
        convertAmount,
        convertedQuote.destination_amount,
        token
      );
      await loadWallets(token);
      setShowConvertModal(false);
    } catch (err: any) {
      alert(err.message || 'Conversion failed');
    } finally {
      setConvertLoading(false);
    }
  };

  const handleActivate = async () => {
    if (!token) return;
    try {
      await activateWallet(activateCurrency, token);
      await loadWallets(token);
      setShowActivateModal(false);
    } catch (err: any) {
      alert(err.message || 'Activation failed');
    }
  };

  return (
    <div style={{ maxWidth: '1000px', margin: '0 auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
        <div>
          <h1 style={{ fontSize: '32px', fontWeight: 800, color: '#0D253F', margin: '0 0 6px 0' }}>Multi-Currency Digital Wallets</h1>
          <p style={{ color: '#64748B', fontSize: '15px', margin: 0 }}>Hold, receive, convert, and manage balances across global fiat currencies.</p>
        </div>
        <div style={{ display: 'flex', gap: '12px' }}>
          <button
            onClick={() => setShowConvertModal(true)}
            style={{ padding: '12px 20px', background: '#F1F5F9', color: '#0D253F', border: '1px solid #CBD5E1', borderRadius: '10px', fontWeight: 700, cursor: 'pointer' }}
          >
            🔄 Convert Between Wallets
          </button>
          <button
            onClick={() => setShowActivateModal(true)}
            style={{ padding: '12px 20px', background: '#0D253F', color: '#FFF', border: 'none', borderRadius: '10px', fontWeight: 700, cursor: 'pointer' }}
          >
            + Activate New Currency
          </button>
        </div>
      </div>

      {/* Wallets Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '24px', marginBottom: '40px' }}>
        {wallets.map((w, idx) => {
          const meta = SUPPORTED_CURRENCIES.find(c => c.code === w.currency);
          return (
            <div key={idx} style={{ background: '#FFF', borderRadius: '20px', padding: '28px', border: '1px solid #E2E8F0', boxShadow: '0 4px 20px rgba(0,0,0,0.03)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                  <span style={{ fontSize: '28px' }}>{meta?.flag || '🌐'}</span>
                  <div>
                    <div style={{ fontWeight: 800, fontSize: '16px', color: '#0D253F' }}>{w.currency}</div>
                    <div style={{ fontSize: '12px', color: '#64748B' }}>{meta?.name || 'Global Currency'}</div>
                  </div>
                </div>
                <span style={{ fontSize: '11px', fontWeight: 700, color: '#00C853', background: '#E8F5E9', padding: '3px 8px', borderRadius: '6px' }}>
                  {w.status}
                </span>
              </div>

              <div style={{ fontSize: '32px', fontWeight: 800, color: '#0D253F', marginBottom: '8px' }}>
                {meta?.symbol || ''}{w.available_balance}
              </div>
              <div style={{ fontSize: '13px', color: '#94A3B8', marginBottom: '24px' }}>
                Pending Settlement: 0.00 {w.currency}
              </div>

              <div style={{ display: 'flex', gap: '10px' }}>
                <button
                  onClick={() => {
                    setFundCurrency(w.currency);
                    setShowFundModal(true);
                  }}
                  style={{ flex: 1, padding: '10px', background: '#00C853', color: '#FFF', border: 'none', borderRadius: '8px', fontSize: '13px', fontWeight: 700, cursor: 'pointer' }}
                >
                  + Deposit
                </button>
                <button
                  onClick={() => {
                    setFromCurr(w.currency);
                    setShowConvertModal(true);
                  }}
                  style={{ flex: 1, padding: '10px', background: '#F1F5F9', color: '#0D253F', border: '1px solid #CBD5E1', borderRadius: '8px', fontSize: '13px', fontWeight: 700, cursor: 'pointer' }}
                >
                  Convert
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* FUND MODAL */}
      {showFundModal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '20px' }}>
          <div style={{ background: '#FFF', borderRadius: '20px', width: '100%', maxWidth: '440px', padding: '32px' }}>
            <h3 style={{ margin: '0 0 12px 0', fontSize: '20px', fontWeight: 800, color: '#0D253F' }}>Deposit Funds into {fundCurrency} Wallet</h3>
            <p style={{ color: '#64748B', fontSize: '14px', marginBottom: '20px' }}>Simulate incoming top-up via local banking rail or card.</p>

            <div style={{ marginBottom: '20px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>Amount to Deposit</label>
              <input
                type="number"
                value={fundAmount}
                onChange={e => setFundAmount(e.target.value)}
                style={{ width: '100%', padding: '12px', fontSize: '16px', border: '1px solid #CBD5E1', borderRadius: '8px', boxSizing: 'border-box' }}
              />
            </div>

            <div style={{ display: 'flex', gap: '10px' }}>
              <button onClick={() => setShowFundModal(false)} style={{ flex: 1, padding: '12px', background: '#F1F5F9', border: 'none', borderRadius: '8px', fontWeight: 600, cursor: 'pointer' }}>Cancel</button>
              <button onClick={handleFund} disabled={fundLoading} style={{ flex: 1, padding: '12px', background: '#00C853', color: '#FFF', border: 'none', borderRadius: '8px', fontWeight: 700, cursor: 'pointer' }}>
                {fundLoading ? 'Crediting...' : 'Confirm Deposit'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* CONVERT MODAL */}
      {showConvertModal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '20px' }}>
          <div style={{ background: '#FFF', borderRadius: '20px', width: '100%', maxWidth: '480px', padding: '32px' }}>
            <h3 style={{ margin: '0 0 12px 0', fontSize: '20px', fontWeight: 800, color: '#0D253F' }}>Instant Currency Conversion</h3>
            <p style={{ color: '#64748B', fontSize: '14px', marginBottom: '20px' }}>Exchange balances instantly between your wallets at guaranteed rates.</p>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '16px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>From Currency</label>
                <select value={fromCurr} onChange={e => setFromCurr(e.target.value)} style={{ width: '100%', padding: '12px', fontSize: '15px', border: '1px solid #CBD5E1', borderRadius: '8px', background: '#FFF' }}>
                  {wallets.map(w => (
                    <option key={w.currency} value={w.currency}>{w.currency}</option>
                  ))}
                </select>
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>To Currency</label>
                <select value={toCurr} onChange={e => setToCurr(e.target.value)} style={{ width: '100%', padding: '12px', fontSize: '15px', border: '1px solid #CBD5E1', borderRadius: '8px', background: '#FFF' }}>
                  {SUPPORTED_CURRENCIES.map(c => (
                    <option key={c.code} value={c.code}>{c.code} ({c.name})</option>
                  ))}
                </select>
              </div>
            </div>

            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>Amount to Convert</label>
              <input
                type="number"
                value={convertAmount}
                onChange={e => setConvertAmount(e.target.value)}
                style={{ width: '100%', padding: '12px', fontSize: '15px', border: '1px solid #CBD5E1', borderRadius: '8px', boxSizing: 'border-box' }}
              />
            </div>

            {convertedQuote && (
              <div style={{ background: '#F8FAFC', padding: '16px', borderRadius: '10px', marginBottom: '20px', border: '1px solid #E2E8F0' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', color: '#64748B', marginBottom: '6px' }}>
                  <span>Exchange Rate:</span>
                  <strong>1 {fromCurr} = {convertedQuote.exchange_rate} {toCurr}</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '16px', color: '#0D253F', fontWeight: 800, marginTop: '8px', paddingTop: '8px', borderTop: '1px solid #E2E8F0' }}>
                  <span>You Receive:</span>
                  <span style={{ color: '#00C853' }}>{convertedQuote.destination_amount} {toCurr}</span>
                </div>
              </div>
            )}

            <div style={{ display: 'flex', gap: '10px' }}>
              <button onClick={() => setShowConvertModal(false)} style={{ flex: 1, padding: '12px', background: '#F1F5F9', border: 'none', borderRadius: '8px', fontWeight: 600, cursor: 'pointer' }}>Cancel</button>
              <button onClick={handleConvert} disabled={convertLoading} style={{ flex: 1, padding: '12px', background: '#0D253F', color: '#FFF', border: 'none', borderRadius: '8px', fontWeight: 700, cursor: 'pointer' }}>
                {convertLoading ? 'Converting...' : 'Confirm Conversion'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ACTIVATE WALLET MODAL */}
      {showActivateModal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '20px' }}>
          <div style={{ background: '#FFF', borderRadius: '20px', width: '100%', maxWidth: '420px', padding: '30px' }}>
            <h3 style={{ margin: '0 0 14px 0', fontSize: '20px', fontWeight: 800, color: '#0D253F' }}>Activate Currency Wallet</h3>
            <p style={{ color: '#64748B', fontSize: '14px', marginBottom: '20px' }}>Select an international currency to enable immediate holding and receiving.</p>

            <select
              value={activateCurrency}
              onChange={e => setActivateCurrency(e.target.value)}
              style={{ width: '100%', padding: '12px', fontSize: '15px', border: '1px solid #CBD5E1', borderRadius: '8px', marginBottom: '24px', background: '#FFF' }}
            >
              {SUPPORTED_CURRENCIES.map(c => (
                <option key={c.code} value={c.code}>{c.flag} {c.code} — {c.name}</option>
              ))}
            </select>

            <div style={{ display: 'flex', gap: '10px' }}>
              <button onClick={() => setShowActivateModal(false)} style={{ flex: 1, padding: '12px', background: '#F1F5F9', border: 'none', borderRadius: '8px', cursor: 'pointer' }}>Cancel</button>
              <button onClick={handleActivate} style={{ flex: 1, padding: '12px', background: '#0D253F', color: '#FFF', border: 'none', borderRadius: '8px', fontWeight: 700, cursor: 'pointer' }}>Activate Wallet</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
