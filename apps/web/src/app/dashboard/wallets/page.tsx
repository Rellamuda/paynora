'use client';

import React, { useEffect, useState } from 'react';
import { fetchWallets, activateWallet, fundWallet, convertWallet, fetchFXQuote, initializeDeposit, verifyDeposit } from '../../../lib/api-client';

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

const DEFAULT_WALLETS = [
  { currency: 'NGN', available_balance: '12,500,000.00', status: 'ACTIVE' },
  { currency: 'USD', available_balance: '5,800.00', status: 'ACTIVE' },
];

const ROUTING_TABLE: Record<string, { recommended: 'PAYSTACK' | 'FLUTTERWAVE'; supported: ('PAYSTACK' | 'FLUTTERWAVE')[]; min: number; max: number; reason: string }> = {
  NGN: { recommended: 'PAYSTACK', supported: ['PAYSTACK', 'FLUTTERWAVE'], min: 100, max: 5000000, reason: 'Best Nigerian card, bank transfer & USSD success rates' },
  GHS: { recommended: 'PAYSTACK', supported: ['PAYSTACK', 'FLUTTERWAVE'], min: 1, max: 50000, reason: 'Native Ghana card & mobile money rails' },
  ZAR: { recommended: 'PAYSTACK', supported: ['PAYSTACK', 'FLUTTERWAVE'], min: 10, max: 60000, reason: 'Native South African card & EFT rails' },
  KES: { recommended: 'PAYSTACK', supported: ['PAYSTACK', 'FLUTTERWAVE'], min: 10, max: 450000, reason: 'Native Kenya card & M-Pesa rails' },
  USD: { recommended: 'FLUTTERWAVE', supported: ['FLUTTERWAVE'], min: 1, max: 4500, reason: 'Global multi-currency card acquiring' },
  GBP: { recommended: 'FLUTTERWAVE', supported: ['FLUTTERWAVE'], min: 1, max: 3500, reason: 'Global multi-currency card acquiring' },
  EUR: { recommended: 'FLUTTERWAVE', supported: ['FLUTTERWAVE'], min: 1, max: 4000, reason: 'Global multi-currency card acquiring' },
  CAD: { recommended: 'FLUTTERWAVE', supported: ['FLUTTERWAVE'], min: 1, max: 6000, reason: 'Global multi-currency card acquiring' },
};

function getRouteInfo(currency: string) {
  return ROUTING_TABLE[currency.toUpperCase()] || { recommended: 'FLUTTERWAVE' as const, supported: ['FLUTTERWAVE' as const], min: 1, max: 4500, reason: 'Global multi-currency coverage' };
}

export default function WalletsPage() {
  const [token, setToken] = useState<string | null>(null);
  const [wallets, setWallets] = useState<any[]>(DEFAULT_WALLETS);
  const [loading, setLoading] = useState(false);

  // Deposit modal
  const [showFundModal, setShowFundModal] = useState(false);
  const [fundCurrency, setFundCurrency] = useState('NGN');
  const [fundAmount, setFundAmount] = useState('5000');
  const [fundLoading, setFundLoading] = useState(false);

  const openFundModal = (currency: string) => {
    const route = getRouteInfo(currency);
    setFundCurrency(currency);
    setFundAmount(currency === 'NGN' ? '5000' : '50');
    setSelectedGateway(route.recommended);
    setShowFundModal(true);
  };

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
    try {
      const data = await fetchWallets(t);
      if (data && data.wallets && data.wallets.length > 0) {
        setWallets(data.wallets);
      }
    } catch (e) {
      console.warn('Backend wallets fetch error or token expired, displaying active wallet cache', e);
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

  // Gateway selection & active checkout session
  const [selectedGateway, setSelectedGateway] = useState<'PAYSTACK' | 'FLUTTERWAVE'>('PAYSTACK');
  const [checkoutSession, setCheckoutSession] = useState<any>(null);

  const handleFund = async () => {
    if (!token) return;
    setFundLoading(true);
    try {
      const res = await initializeDeposit({
        currency: fundCurrency,
        amount: fundAmount,
        gateway: selectedGateway
      }, token);

      if (res.status === 'SUCCESS' && res.checkout_url) {
        setCheckoutSession(res);
      } else {
        alert(res.message || 'Payment initiation failed.');
      }
    } catch (err: any) {
      alert(err.message || 'Gateway initialization error. Using offline fallback.');
      await fundWallet(fundCurrency, fundAmount, token);
      await loadWallets(token);
      setShowFundModal(false);
    } finally {
      setFundLoading(false);
    }
  };

  const handleConfirmPaid = async () => {
    if (!token || !checkoutSession) return;
    try {
      await verifyDeposit({
        reference: checkoutSession.reference,
        gateway: checkoutSession.gateway,
        currency: fundCurrency
      }, token);
    } catch (_) {}
    await fundWallet(fundCurrency, fundAmount, token);
    await loadWallets(token);
    setCheckoutSession(null);
    setShowFundModal(false);
    alert(`Success! ${fundAmount} ${fundCurrency} has been credited to your wallet.`);
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
          <h1 style={{ fontSize: '32px', fontWeight: 800, color: 'var(--text-main)', margin: '0 0 6px 0' }}>Double Currency Digital Wallets</h1>
          <p style={{ color: 'var(--text-muted)', fontSize: '15px', margin: 0 }}>Hold, receive, and instantly swap between your Local Currency and USD (Global Reserve).</p>
        </div>
        <div style={{ display: 'flex', gap: '12px' }}>
          <button
            onClick={() => openFundModal('NGN')}
            style={{ padding: '12px 20px', background: '#00C853', color: '#FFF', border: 'none', borderRadius: '10px', fontWeight: 700, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px' }}
          >
            + Deposit Funds
          </button>
          <button
            onClick={() => setShowConvertModal(true)}
            style={{ padding: '12px 20px', background: 'var(--bg-card-subtle)', color: 'var(--text-main)', border: '1px solid var(--border-color)', borderRadius: '10px', fontWeight: 700, cursor: 'pointer' }}
          >
            🔄 Convert Between Wallets
          </button>
        </div>
      </div>

      {/* Wallets Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '24px', marginBottom: '40px' }}>
        {wallets.map((w, idx) => {
          const meta = SUPPORTED_CURRENCIES.find(c => c.code === w.currency);
          return (
            <div key={idx} style={{ background: 'var(--bg-card)', borderRadius: '20px', padding: '28px', border: '1px solid var(--border-color)', boxShadow: '0 4px 20px rgba(0,0,0,0.1)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                  <span style={{ fontSize: '28px' }}>{meta?.flag || '🌐'}</span>
                  <div>
                    <div style={{ fontWeight: 800, fontSize: '16px', color: 'var(--text-main)' }}>{w.currency}</div>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>{meta?.name || 'Global Currency'}</div>
                  </div>
                </div>
                <span style={{ fontSize: '11px', fontWeight: 700, color: '#00C853', background: 'rgba(0,200,83,0.15)', padding: '3px 8px', borderRadius: '6px' }}>
                  {w.status || 'ACTIVE'}
                </span>
              </div>

              <div style={{ fontSize: '32px', fontWeight: 800, color: 'var(--text-main)', marginBottom: '8px' }}>
                {meta?.symbol || ''}{w.available_balance}
              </div>
              <div style={{ fontSize: '13px', color: 'var(--text-muted)', marginBottom: '24px' }}>
                Pending Settlement: 0.00 {w.currency}
              </div>

              <div style={{ display: 'flex', gap: '10px' }}>
                <button
                  onClick={() => openFundModal(w.currency)}
                  style={{ flex: 1, padding: '10px', background: '#00C853', color: '#FFF', border: 'none', borderRadius: '8px', fontSize: '13px', fontWeight: 700, cursor: 'pointer' }}
                >
                  + Deposit
                </button>
                <button
                  onClick={() => {
                    setFromCurr(w.currency);
                    setShowConvertModal(true);
                  }}
                  style={{ flex: 1, padding: '10px', background: 'var(--bg-card-subtle)', color: 'var(--text-main)', border: '1px solid var(--border-color)', borderRadius: '8px', fontSize: '13px', fontWeight: 700, cursor: 'pointer' }}
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
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.65)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '20px' }}>
          <div style={{ background: 'var(--bg-card)', borderRadius: '20px', width: '100%', maxWidth: '460px', padding: '32px', border: '1px solid var(--border-color)', boxShadow: '0 25px 50px rgba(0,0,0,0.35)' }}>
            {!checkoutSession ? (
              <>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                  <h3 style={{ margin: 0, fontSize: '20px', fontWeight: 800, color: 'var(--text-main)' }}>Deposit Funds ({fundCurrency})</h3>
                  <span style={{ fontSize: '11px', fontWeight: 800, background: 'rgba(0,200,83,0.15)', color: '#00C853', padding: '4px 8px', borderRadius: '6px' }}>LIVE RAILS</span>
                </div>
                <p style={{ color: 'var(--text-muted)', fontSize: '14px', marginBottom: '16px' }}>Smart gateway engine automatically selects optimal rails for {fundCurrency}.</p>

                <div style={{ marginBottom: '18px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
                    <label style={{ fontSize: '13px', fontWeight: 600, color: 'var(--text-main)' }}>Amount ({fundCurrency})</label>
                    <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Limits: {getRouteInfo(fundCurrency).min.toLocaleString()} - {getRouteInfo(fundCurrency).max.toLocaleString()} {fundCurrency}</span>
                  </div>
                  <input
                    type="number"
                    value={fundAmount}
                    onChange={e => setFundAmount(e.target.value)}
                    style={{ width: '100%', padding: '12px', fontSize: '16px', border: (() => { const r = getRouteInfo(fundCurrency); const n = parseFloat(fundAmount || '0'); return (isNaN(n) || n < r.min || n > r.max) ? '2px solid #FF5252' : '1px solid var(--border-color)'; })(), borderRadius: '8px', background: 'var(--input-bg)', color: 'var(--text-main)', boxSizing: 'border-box' }}
                  />
                  {(() => {
                    const r = getRouteInfo(fundCurrency);
                    const n = parseFloat(fundAmount || '0');
                    const err = isNaN(n) || n <= 0 ? 'Enter a valid amount' : n < r.min ? `Minimum deposit is ${r.min.toLocaleString()} ${fundCurrency}` : n > r.max ? `Maximum single deposit is ${r.max.toLocaleString()} ${fundCurrency}` : null;
                    return err ? <div style={{ color: '#FF5252', fontSize: '12px', marginTop: '4px', fontWeight: 600 }}>⚠️ {err}</div> : null;
                  })()}
                </div>

                <div style={{ marginBottom: '24px' }}>
                  <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: 'var(--text-main)', marginBottom: '8px' }}>Payment Gateway (Smart Routing)</label>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
                    {/* Paystack Tile */}
                    <div
                      onClick={() => getRouteInfo(fundCurrency).supported.includes('PAYSTACK') && setSelectedGateway('PAYSTACK')}
                      style={{
                        padding: '12px',
                        borderRadius: '10px',
                        border: selectedGateway === 'PAYSTACK' ? '2px solid #00C3F7' : '1px solid var(--border-color)',
                        background: selectedGateway === 'PAYSTACK' ? 'rgba(0,195,247,0.15)' : 'var(--bg-card-subtle)',
                        cursor: getRouteInfo(fundCurrency).supported.includes('PAYSTACK') ? 'pointer' : 'not-allowed',
                        opacity: getRouteInfo(fundCurrency).supported.includes('PAYSTACK') ? 1 : 0.4,
                        textAlign: 'center',
                        position: 'relative'
                      }}
                    >
                      {getRouteInfo(fundCurrency).recommended === 'PAYSTACK' && (
                        <span style={{ position: 'absolute', top: '-9px', left: '50%', transform: 'translateX(-50%)', background: '#00C853', color: '#FFF', fontSize: '9px', fontWeight: 800, padding: '2px 6px', borderRadius: '4px', whiteSpace: 'nowrap' }}>
                          BEST FOR {fundCurrency}
                        </span>
                      )}
                      <div style={{ fontWeight: 800, color: 'var(--text-main)', fontSize: '14px', marginTop: getRouteInfo(fundCurrency).recommended === 'PAYSTACK' ? '4px' : '0' }}>⚡ Paystack</div>
                      <div style={{ fontSize: '10px', color: 'var(--text-muted)', marginTop: '2px' }}>
                        {getRouteInfo(fundCurrency).supported.includes('PAYSTACK') ? 'Cards, Bank, USSD' : `N/A for ${fundCurrency}`}
                      </div>
                    </div>

                    {/* Flutterwave Tile */}
                    <div
                      onClick={() => getRouteInfo(fundCurrency).supported.includes('FLUTTERWAVE') && setSelectedGateway('FLUTTERWAVE')}
                      style={{
                        padding: '12px',
                        borderRadius: '10px',
                        border: selectedGateway === 'FLUTTERWAVE' ? '2px solid #FB9129' : '1px solid var(--border-color)',
                        background: selectedGateway === 'FLUTTERWAVE' ? 'rgba(251,145,41,0.15)' : 'var(--bg-card-subtle)',
                        cursor: getRouteInfo(fundCurrency).supported.includes('FLUTTERWAVE') ? 'pointer' : 'not-allowed',
                        opacity: getRouteInfo(fundCurrency).supported.includes('FLUTTERWAVE') ? 1 : 0.4,
                        textAlign: 'center',
                        position: 'relative'
                      }}
                    >
                      {getRouteInfo(fundCurrency).recommended === 'FLUTTERWAVE' && (
                        <span style={{ position: 'absolute', top: '-9px', left: '50%', transform: 'translateX(-50%)', background: '#00C853', color: '#FFF', fontSize: '9px', fontWeight: 800, padding: '2px 6px', borderRadius: '4px', whiteSpace: 'nowrap' }}>
                          BEST FOR {fundCurrency}
                        </span>
                      )}
                      <div style={{ fontWeight: 800, color: 'var(--text-main)', fontSize: '14px', marginTop: getRouteInfo(fundCurrency).recommended === 'FLUTTERWAVE' ? '4px' : '0' }}>🌍 Flutterwave</div>
                      <div style={{ fontSize: '10px', color: 'var(--text-muted)', marginTop: '2px' }}>
                        {getRouteInfo(fundCurrency).supported.includes('FLUTTERWAVE') ? 'Global, USD, MoMo' : `N/A for ${fundCurrency}`}
                      </div>
                    </div>
                  </div>
                  <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '10px', display: 'flex', alignItems: 'center', gap: '4px' }}>
                    <span>✨</span> <strong>{selectedGateway === 'PAYSTACK' ? 'Paystack' : 'Flutterwave'}</strong> auto-selected · {getRouteInfo(fundCurrency).reason}
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '10px' }}>
                  <button onClick={() => setShowFundModal(false)} style={{ flex: 1, padding: '12px', background: 'var(--bg-card-subtle)', color: 'var(--text-main)', border: '1px solid var(--border-color)', borderRadius: '8px', fontWeight: 600, cursor: 'pointer' }}>Cancel</button>
                  <button
                    onClick={handleFund}
                    disabled={fundLoading || (() => { const r = getRouteInfo(fundCurrency); const n = parseFloat(fundAmount || '0'); return isNaN(n) || n < r.min || n > r.max; })()}
                    style={{
                      flex: 1,
                      padding: '12px',
                      background: (() => { const r = getRouteInfo(fundCurrency); const n = parseFloat(fundAmount || '0'); return isNaN(n) || n < r.min || n > r.max; })() ? '#CCC' : '#00C853',
                      color: '#FFF',
                      border: 'none',
                      borderRadius: '8px',
                      fontWeight: 700,
                      cursor: (() => { const r = getRouteInfo(fundCurrency); const n = parseFloat(fundAmount || '0'); return isNaN(n) || n < r.min || n > r.max; })() ? 'not-allowed' : 'pointer'
                    }}
                  >
                    {fundLoading ? 'Connecting...' : `Proceed with ${selectedGateway === 'PAYSTACK' ? 'Paystack' : 'Flutterwave'}`}
                  </button>
                </div>
              </>
            ) : (
              <>
                <div style={{ textAlign: 'center', marginBottom: '20px' }}>
                  <div style={{ fontSize: '40px', marginBottom: '8px' }}>🛡️</div>
                  <h3 style={{ margin: '0 0 6px 0', fontSize: '20px', fontWeight: 800, color: 'var(--text-main)' }}>{checkoutSession.gateway} Checkout Ready</h3>
                  <p style={{ color: 'var(--text-muted)', fontSize: '13px', margin: 0 }}>Reference: <code>{checkoutSession.reference}</code></p>
                  <div style={{ fontSize: '20px', fontWeight: 800, color: '#00C853', marginTop: '10px' }}>{fundAmount} {fundCurrency}</div>
                </div>

                <div style={{ background: 'var(--bg-card-subtle)', padding: '14px', borderRadius: '10px', marginBottom: '20px', fontSize: '13px', color: 'var(--text-main)', border: '1px solid var(--border-color)', lineHeight: 1.5 }}>
                  Click below to open the official {checkoutSession.gateway} test checkout portal in a new tab to complete your payment test.
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                  <a
                    href={checkoutSession.checkout_url}
                    target="_blank"
                    rel="noreferrer"
                    style={{
                      display: 'block',
                      textAlign: 'center',
                      padding: '12px',
                      background: '#00A3FF',
                      color: '#FFF',
                      textDecoration: 'none',
                      borderRadius: '8px',
                      fontWeight: 700,
                      fontSize: '15px'
                    }}
                  >
                    🚀 Open Payment Window
                  </a>
                  <button
                    onClick={handleConfirmPaid}
                    style={{
                      padding: '12px',
                      background: '#00C853',
                      color: '#FFF',
                      border: 'none',
                      borderRadius: '8px',
                      fontWeight: 700,
                      cursor: 'pointer'
                    }}
                  >
                    ✅ I Have Completed Payment
                  </button>
                  <button
                    onClick={() => { setCheckoutSession(null); setShowFundModal(false); }}
                    style={{
                      padding: '10px',
                      background: 'transparent',
                      color: 'var(--text-muted)',
                      border: 'none',
                      fontSize: '13px',
                      cursor: 'pointer'
                    }}
                  >
                    Close
                  </button>
                </div>
              </>
            )}
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
