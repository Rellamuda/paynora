'use client';

import React, { useEffect, useState } from 'react';
import {
  fetchWallets,
  activateWallet,
  fundWallet,
  fetchBeneficiaries,
  fetchTransfers,
  fetchFXQuote,
  createTransfer
} from '../../lib/api-client';

export default function DashboardOverviewPage() {
  const [token, setToken] = useState<string | null>(null);
  const [wallets, setWallets] = useState<any[]>([]);
  const [transfers, setTransfers] = useState<any[]>([]);
  const [beneficiaries, setBeneficiaries] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  // Quick Deposit Modal
  const [showFundModal, setShowFundModal] = useState(false);
  const [fundCurrency, setFundCurrency] = useState('NGN');
  const [fundAmount, setFundAmount] = useState('500000');
  const [fundLoading, setFundLoading] = useState(false);

  // Quick Send Modal
  const [showSendModal, setShowSendModal] = useState(false);
  const [sendRecipient, setSendRecipient] = useState('');
  const [sendAmount, setSendAmount] = useState('100000');
  const [sendSourceCurr, setSendSourceCurr] = useState('NGN');
  const [sendDestCurr, setSendDestCurr] = useState('GBP');
  const [fxQuote, setFxQuote] = useState<any>(null);
  const [sendLoading, setSendLoading] = useState(false);

  // Selected Transaction Receipt Modal
  const [selectedTx, setSelectedTx] = useState<any>(null);

  useEffect(() => {
    const savedToken = localStorage.getItem('paynora_token');
    if (savedToken) {
      setToken(savedToken);
      loadData(savedToken);
    }
  }, []);

  const loadData = async (authToken: string) => {
    setLoading(true);
    try {
      const [walletData, transferData, benData] = await Promise.all([
        fetchWallets(authToken).catch(() => ({ wallets: [] })),
        fetchTransfers().catch(() => ({ transfers: [] })),
        fetchBeneficiaries(authToken).catch(() => ({ beneficiaries: [] }))
      ]);
      setWallets(walletData.wallets || []);
      setTransfers(transferData.transfers || []);
      setBeneficiaries(benData.beneficiaries || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  // FX calculation
  useEffect(() => {
    if (showSendModal && sendAmount && Number(sendAmount) > 0) {
      const t = setTimeout(async () => {
        try {
          const q = await fetchFXQuote(sendSourceCurr, sendDestCurr, sendAmount);
          setFxQuote(q);
        } catch (e) {
          console.error(e);
        }
      }, 300);
      return () => clearTimeout(t);
    }
  }, [showSendModal, sendAmount, sendSourceCurr, sendDestCurr]);

  const handleDeposit = async () => {
    if (!token) return;
    setFundLoading(true);
    try {
      await fundWallet(fundCurrency, fundAmount, token);
      await loadData(token);
      setShowFundModal(false);
    } catch (err: any) {
      alert(err.message || 'Deposit failed');
    } finally {
      setFundLoading(false);
    }
  };

  const handleExecuteSend = async () => {
    if (!token) return;
    setSendLoading(true);
    try {
      const idemp = `tx_${Date.now()}_${Math.random().toString(36).substring(7)}`;
      const newTx = await createTransfer({
        source_currency: sendSourceCurr,
        source_amount: sendAmount,
        recipient_name: sendRecipient || (beneficiaries[0]?.name || 'Recipient'),
        source_country: 'NG',
        destination_country: sendDestCurr === 'GBP' ? 'GB' : 'US',
        recipient_currency_mode: 'CHOICE'
      }, idemp, token);

      setTransfers(prev => [newTx, ...prev]);
      setShowSendModal(false);
      setSelectedTx(newTx);
    } catch (err: any) {
      alert(err.message || 'Transfer failed');
    } finally {
      setSendLoading(false);
    }
  };

  return (
    <div>
      {/* Overview Metric Banner */}
      <div style={{ background: '#0D253F', borderRadius: '20px', padding: '36px 40px', color: '#FFF', display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '36px', boxShadow: '0 8px 30px rgba(13,37,63,0.12)' }}>
        <div>
          <div style={{ fontSize: '13px', color: '#94A3B8', fontWeight: 600, letterSpacing: '0.5px' }}>NET CONSOLIDATED MULTI-CURRENCY BALANCE</div>
          <div style={{ fontSize: '42px', fontWeight: 800, margin: '8px 0', letterSpacing: '-1px' }}>
            ₦2,450,000.00 <span style={{ fontSize: '18px', color: '#00C853', fontWeight: 600 }}>(+4 Currencies Active)</span>
          </div>
          <div style={{ fontSize: '13px', color: '#CBD5E1' }}>Real-time settlement • Double-entry immutable accounting engine</div>
        </div>

        <div style={{ display: 'flex', gap: '14px' }}>
          <button
            onClick={() => setShowFundModal(true)}
            style={{ padding: '16px 24px', background: 'rgba(255,255,255,0.12)', color: '#FFF', fontSize: '15px', fontWeight: 600, borderRadius: '12px', border: '1px solid rgba(255,255,255,0.2)', cursor: 'pointer' }}
          >
            + Deposit / Fund
          </button>
          <button
            onClick={() => setShowSendModal(true)}
            style={{ padding: '16px 30px', background: '#00C853', color: '#FFF', fontSize: '15px', fontWeight: 700, borderRadius: '12px', border: 'none', cursor: 'pointer', boxShadow: '0 4px 15px rgba(0,200,83,0.35)' }}
          >
            Send Money Now →
          </button>
        </div>
      </div>

      {/* Multi-Currency Balances Row */}
      <section style={{ marginBottom: '40px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '18px' }}>
          <h2 style={{ fontSize: '20px', fontWeight: 800, color: '#0D253F', margin: 0 }}>Active Currency Wallets</h2>
          <a href="/dashboard/wallets" style={{ fontSize: '13px', color: '#00C853', fontWeight: 700, textDecoration: 'none' }}>
            Manage All Wallets & Conversion →
          </a>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '20px' }}>
          {wallets.map((w, idx) => (
            <div key={idx} style={{ background: '#FFF', padding: '24px', borderRadius: '16px', border: '1px solid #E2E8F0', boxShadow: '0 4px 15px rgba(0,0,0,0.02)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                <span style={{ fontSize: '13px', fontWeight: 700, color: '#64748B' }}>{w.currency} WALLET</span>
                <span style={{ fontSize: '11px', fontWeight: 700, color: '#00C853', background: '#E8F5E9', padding: '2px 8px', borderRadius: '6px' }}>{w.status}</span>
              </div>
              <div style={{ fontSize: '28px', fontWeight: 800, color: '#0D253F', marginBottom: '12px' }}>
                {w.currency === 'NGN' ? '₦' : w.currency === 'GBP' ? '£' : w.currency === 'EUR' ? '€' : '$'}
                {w.available_balance || '0.00'}
              </div>
              <div style={{ display: 'flex', gap: '8px' }}>
                <button
                  onClick={() => {
                    setFundCurrency(w.currency);
                    setShowFundModal(true);
                  }}
                  style={{ flex: 1, padding: '8px', background: '#F1F5F9', border: 'none', borderRadius: '6px', fontSize: '12px', fontWeight: 600, color: '#0D253F', cursor: 'pointer' }}
                >
                  + Add Funds
                </button>
                <a
                  href="/dashboard/exchange"
                  style={{ flex: 1, padding: '8px', background: '#F1F5F9', border: 'none', borderRadius: '6px', fontSize: '12px', fontWeight: 600, color: '#0D253F', textDecoration: 'none', textAlign: 'center' }}
                >
                  Convert
                </a>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Grid: Beneficiaries & Transactions */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '30px' }}>
        {/* Saved Beneficiaries Card */}
        <div style={{ background: '#FFF', padding: '28px', borderRadius: '18px', border: '1px solid #E2E8F0' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <h3 style={{ margin: 0, fontSize: '18px', fontWeight: 800, color: '#0D253F' }}>Saved Recipients</h3>
            <a href="/dashboard/recipients" style={{ fontSize: '12px', color: '#00C853', fontWeight: 700, textDecoration: 'none' }}>
              View All →
            </a>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {beneficiaries.slice(0, 4).map((b, idx) => (
              <div key={idx} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 14px', background: '#F8FAFC', borderRadius: '10px', border: '1px solid #E2E8F0' }}>
                <div>
                  <div style={{ fontWeight: 700, fontSize: '14px', color: '#0D253F' }}>{b.name}</div>
                  <div style={{ fontSize: '12px', color: '#64748B' }}>{b.country_iso} • {b.currency}</div>
                </div>
                <button
                  onClick={() => {
                    setSendRecipient(b.name);
                    setSendDestCurr(b.currency || 'GBP');
                    setShowSendModal(true);
                  }}
                  style={{ padding: '6px 12px', background: '#0D253F', color: '#FFF', fontSize: '12px', fontWeight: 600, borderRadius: '6px', border: 'none', cursor: 'pointer' }}
                >
                  Send
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* Recent Transactions Card */}
        <div style={{ background: '#FFF', padding: '28px', borderRadius: '18px', border: '1px solid #E2E8F0' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <h3 style={{ margin: 0, fontSize: '18px', fontWeight: 800, color: '#0D253F' }}>Recent Transfers & Settlement</h3>
            <a href="/dashboard/transactions" style={{ fontSize: '12px', color: '#00C853', fontWeight: 700, textDecoration: 'none' }}>
              Full Ledger History →
            </a>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {transfers.slice(0, 5).map((tx, idx) => (
              <div
                key={idx}
                onClick={() => setSelectedTx(tx)}
                style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '16px', background: '#F8FAFC', borderRadius: '12px', border: '1px solid #E2E8F0', cursor: 'pointer', transition: 'border-color 0.2s' }}
              >
                <div>
                  <div style={{ fontWeight: 700, fontSize: '15px', color: '#0D253F' }}>To: {tx.recipient_name}</div>
                  <div style={{ fontSize: '12px', color: '#64748B' }}>
                    Ref: <code>{tx.transfer_id}</code> • {tx.source_country} → {tx.destination_country}
                  </div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontWeight: 800, fontSize: '16px', color: '#0D253F' }}>
                    {tx.source_amount} {tx.source_currency}
                  </div>
                  <span style={{ fontSize: '11px', fontWeight: 700, color: tx.state === 'COMPLETED' ? '#16A34A' : '#7C3AED', background: tx.state === 'COMPLETED' ? '#DCFCE7' : '#EDE9FE', padding: '3px 8px', borderRadius: '6px' }}>
                    {tx.state}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* QUICK DEPOSIT MODAL */}
      {showFundModal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '20px' }}>
          <div style={{ background: '#FFF', borderRadius: '20px', width: '100%', maxWidth: '440px', padding: '32px' }}>
            <h3 style={{ margin: '0 0 14px 0', fontSize: '22px', fontWeight: 800, color: '#0D253F' }}>Deposit / Fund Wallet</h3>
            <p style={{ color: '#64748B', fontSize: '14px', marginBottom: '24px' }}>Simulate incoming deposit via instant local payment rails.</p>

            <div style={{ marginBottom: '18px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>Target Wallet</label>
              <select
                value={fundCurrency}
                onChange={e => setFundCurrency(e.target.value)}
                style={{ width: '100%', padding: '12px', fontSize: '15px', border: '1px solid #CBD5E1', borderRadius: '8px', background: '#FFF' }}
              >
                <option value="NGN">NGN Wallet (₦)</option>
                <option value="GBP">GBP Wallet (£)</option>
                <option value="USD">USD Wallet ($)</option>
                <option value="EUR">EUR Wallet (€)</option>
              </select>
            </div>

            <div style={{ marginBottom: '24px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>Deposit Amount</label>
              <input
                type="number"
                value={fundAmount}
                onChange={e => setFundAmount(e.target.value)}
                style={{ width: '100%', padding: '12px', fontSize: '15px', border: '1px solid #CBD5E1', borderRadius: '8px', boxSizing: 'border-box' }}
              />
            </div>

            <div style={{ display: 'flex', gap: '12px' }}>
              <button onClick={() => setShowFundModal(false)} style={{ flex: 1, padding: '14px', background: '#F1F5F9', border: 'none', borderRadius: '8px', fontWeight: 600, cursor: 'pointer' }}>Cancel</button>
              <button onClick={handleDeposit} disabled={fundLoading} style={{ flex: 1, padding: '14px', background: '#0D253F', color: '#FFF', border: 'none', borderRadius: '8px', fontWeight: 700, cursor: 'pointer' }}>
                {fundLoading ? 'Processing...' : 'Confirm Deposit'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* QUICK SEND MODAL */}
      {showSendModal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '20px' }}>
          <div style={{ background: '#FFF', borderRadius: '20px', width: '100%', maxWidth: '500px', padding: '32px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h3 style={{ margin: 0, fontSize: '22px', fontWeight: 800, color: '#0D253F' }}>Send Money Internationally</h3>
              <button onClick={() => setShowSendModal(false)} style={{ background: 'none', border: 'none', fontSize: '20px', cursor: 'pointer', color: '#94A3B8' }}>✕</button>
            </div>

            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>Recipient Name</label>
              <input
                type="text"
                placeholder="e.g. Mike Okafor"
                value={sendRecipient}
                onChange={e => setSendRecipient(e.target.value)}
                style={{ width: '100%', padding: '12px', fontSize: '15px', border: '1px solid #CBD5E1', borderRadius: '8px', boxSizing: 'border-box' }}
              />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '12px', marginBottom: '16px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>You Send</label>
                <input
                  type="number"
                  value={sendAmount}
                  onChange={e => setSendAmount(e.target.value)}
                  style={{ width: '100%', padding: '12px', fontSize: '15px', border: '1px solid #CBD5E1', borderRadius: '8px', boxSizing: 'border-box' }}
                />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>From Currency</label>
                <select
                  value={sendSourceCurr}
                  onChange={e => setSendSourceCurr(e.target.value)}
                  style={{ width: '100%', padding: '12px', fontSize: '15px', border: '1px solid #CBD5E1', borderRadius: '8px', background: '#FFF' }}
                >
                  <option value="NGN">NGN (₦)</option>
                  <option value="USD">USD ($)</option>
                  <option value="GBP">GBP (£)</option>
                </select>
              </div>
            </div>

            {fxQuote && (
              <div style={{ background: '#F1F5F9', padding: '16px', borderRadius: '12px', marginBottom: '20px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', color: '#64748B', marginBottom: '4px' }}>
                  <span>Guaranteed FX Rate:</span>
                  <strong>1 {fxQuote.source_currency} = {fxQuote.exchange_rate} {fxQuote.destination_currency}</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', color: '#64748B', marginBottom: '4px' }}>
                  <span>Transfer Fee:</span>
                  <strong>{fxQuote.fee} {fxQuote.source_currency}</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '16px', color: '#0D253F', fontWeight: 800, marginTop: '8px', paddingTop: '8px', borderTop: '1px solid #CBD5E1' }}>
                  <span>Recipient Receives:</span>
                  <span style={{ color: '#00C853' }}>{fxQuote.destination_amount} {fxQuote.destination_currency}</span>
                </div>
              </div>
            )}

            <button
              onClick={handleExecuteSend}
              disabled={sendLoading}
              style={{ width: '100%', padding: '16px', background: '#0D253F', color: '#FFF', fontSize: '16px', fontWeight: 700, borderRadius: '10px', border: 'none', cursor: 'pointer' }}
            >
              {sendLoading ? 'Authorizing with Ledger...' : 'Confirm & Send Money'}
            </button>
          </div>
        </div>
      )}

      {/* TRANSACTION RECEIPT MODAL */}
      {selectedTx && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '20px' }}>
          <div style={{ background: '#FFF', borderRadius: '20px', width: '100%', maxWidth: '480px', padding: '32px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h3 style={{ margin: 0, fontSize: '20px', fontWeight: 800, color: '#0D253F' }}>Official Transaction Receipt</h3>
              <button onClick={() => setSelectedTx(null)} style={{ background: 'none', border: 'none', fontSize: '20px', cursor: 'pointer', color: '#94A3B8' }}>✕</button>
            </div>

            <div style={{ textAlign: 'center', padding: '20px 0', borderBottom: '1px dashed #CBD5E1', marginBottom: '20px' }}>
              <div style={{ fontSize: '32px', fontWeight: 800, color: '#0D253F' }}>
                {selectedTx.source_amount} {selectedTx.source_currency}
              </div>
              <div style={{ fontSize: '13px', color: '#00C853', fontWeight: 700, marginTop: '6px' }}>
                ● STATUS: {selectedTx.state}
              </div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', fontSize: '14px', marginBottom: '24px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', color: '#64748B' }}>
                <span>Transfer ID:</span>
                <code style={{ color: '#0D253F' }}>{selectedTx.transfer_id}</code>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', color: '#64748B' }}>
                <span>Recipient:</span>
                <strong style={{ color: '#0D253F' }}>{selectedTx.recipient_name}</strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', color: '#64748B' }}>
                <span>Corridor:</span>
                <strong style={{ color: '#0D253F' }}>{selectedTx.source_country} ➔ {selectedTx.destination_country}</strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', color: '#64748B' }}>
                <span>Settlement Protocol:</span>
                <strong style={{ color: '#0D253F' }}>Double-Entry Deterministic Ledger</strong>
              </div>
            </div>

            <button
              onClick={() => setSelectedTx(null)}
              style={{ width: '100%', padding: '14px', background: '#0D253F', color: '#FFF', borderRadius: '10px', border: 'none', fontWeight: 700, cursor: 'pointer' }}
            >
              Close Receipt
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
