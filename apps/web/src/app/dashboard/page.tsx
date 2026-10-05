'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  fetchUserProfile,
  fetchWallets,
  activateWallet,
  fetchBeneficiaries,
  createBeneficiary,
  fetchFXQuote,
  createTransfer,
  chatAI,
  getKYCStatus
} from '../../lib/api-client';

export default function DashboardPage() {
  const router = useRouter();

  // Authentication & Profile
  const [token, setToken] = useState<string | null>(null);
  const [profile, setProfile] = useState<any>(null);
  const [kycStatus, setKycStatus] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  // Financial Data
  const [wallets, setWallets] = useState<any[]>([]);
  const [beneficiaries, setBeneficiaries] = useState<any[]>([]);
  const [transfers, setTransfers] = useState<any[]>([]);

  // Modals & Panels
  const [showSendModal, setShowSendModal] = useState(false);
  const [showAddWalletModal, setShowAddWalletModal] = useState(false);
  const [showAddBenModal, setShowAddBenModal] = useState(false);
  const [showAIChat, setShowAIChat] = useState(false);

  // Send Money State
  const [sendAmount, setSendAmount] = useState('100000');
  const [sendSourceCurr, setSendSourceCurr] = useState('NGN');
  const [sendDestCurr, setSendDestCurr] = useState('GBP');
  const [sendRecipient, setSendRecipient] = useState('');
  const [fxQuote, setFxQuote] = useState<any>(null);
  const [transferLoading, setTransferLoading] = useState(false);
  const [sendSuccess, setSendSuccess] = useState('');

  // AI Chat State
  const [aiPrompt, setAiPrompt] = useState('');
  const [aiMessages, setAiMessages] = useState<Array<{ sender: 'user' | 'ai'; text: string; action?: any }>>([
    { sender: 'ai', text: "Hello! I'm PayNora AI. How can I assist you with your money movement today? Try asking: 'Send ₦1,000,000 to John in London' or 'What is my balance?'" }
  ]);
  const [aiLoading, setAiLoading] = useState(false);

  // New Wallet State
  const [newCurrency, setNewCurrency] = useState('USD');

  // New Beneficiary State
  const [benName, setBenName] = useState('');
  const [benCountry, setBenCountry] = useState('GB');
  const [benCurrency, setBenCurrency] = useState('GBP');
  const [benAccNumber, setBenAccNumber] = useState('');

  useEffect(() => {
    const savedToken = localStorage.getItem('paynora_token');
    if (!savedToken) {
      router.push('/onboarding');
      return;
    }
    setToken(savedToken);
    loadDashboardData(savedToken);
  }, []);

  const loadDashboardData = async (authToken: string) => {
    setLoading(true);
    try {
      const [userProf, walletData, benData, kycData] = await Promise.all([
        fetchUserProfile(authToken).catch(() => null),
        fetchWallets(authToken).catch(() => ({ wallets: [] })),
        fetchBeneficiaries(authToken).catch(() => ({ beneficiaries: [] })),
        getKYCStatus(authToken).catch(() => null)
      ]);

      setProfile(userProf);
      setWallets(walletData.wallets || []);
      setBeneficiaries(benData.beneficiaries || []);
      setKycStatus(kycData);
    } catch (err) {
      console.error('Error loading dashboard data:', err);
    } finally {
      setLoading(false);
    }
  };

  // Live FX Quote calculation
  useEffect(() => {
    if (showSendModal && sendAmount && Number(sendAmount) > 0) {
      const timer = setTimeout(async () => {
        try {
          const quote = await fetchFXQuote(sendSourceCurr, sendDestCurr, sendAmount);
          setFxQuote(quote);
        } catch (e) {
          console.error(e);
        }
      }, 300);
      return () => clearTimeout(timer);
    }
  }, [showSendModal, sendAmount, sendSourceCurr, sendDestCurr]);

  const handleExecuteTransfer = async () => {
    if (!token) return;
    setTransferLoading(true);
    setSendSuccess('');
    try {
      const idempKey = `web_tx_${Date.now()}_${Math.random().toString(36).substring(7)}`;
      const res = await createTransfer({
        source_currency: sendSourceCurr,
        source_amount: sendAmount,
        recipient_name: sendRecipient || (beneficiaries[0]?.name || 'Recipient'),
        source_country: 'NG',
        destination_country: sendDestCurr === 'GBP' ? 'GB' : 'US',
        recipient_currency_mode: 'CHOICE'
      }, idempKey, token);

      setTransfers(prev => [res, ...prev]);
      setSendSuccess(`Transfer of ${sendAmount} ${sendSourceCurr} initiated successfully! Reference: ${res.transfer_id}`);
      setTimeout(() => {
        setShowSendModal(false);
        setSendSuccess('');
      }, 2000);
    } catch (err: any) {
      alert(err.message || 'Transfer failed.');
    } finally {
      setTransferLoading(false);
    }
  };

  const handleActivateNewWallet = async () => {
    if (!token) return;
    try {
      const newW = await activateWallet(newCurrency, token);
      setWallets(prev => [...prev.filter(w => w.currency !== newW.currency), newW]);
      setShowAddWalletModal(false);
    } catch (err: any) {
      alert(err.message || 'Failed to activate wallet');
    }
  };

  const handleAddBeneficiary = async () => {
    if (!token) return;
    try {
      const newB = await createBeneficiary({
        name: benName,
        country_iso: benCountry,
        currency: benCurrency,
        account_details: { account_number: benAccNumber }
      }, token);
      setBeneficiaries(prev => [...prev, newB]);
      setShowAddBenModal(false);
      setBenName('');
      setBenAccNumber('');
    } catch (err: any) {
      alert(err.message || 'Failed to add beneficiary');
    }
  };

  const handleSendAIChat = async () => {
    if (!aiPrompt.trim() || !token) return;
    const userMsg = aiPrompt.trim();
    setAiMessages(prev => [...prev, { sender: 'user', text: userMsg }]);
    setAiPrompt('');
    setAiLoading(true);

    try {
      const res = await chatAI(userMsg, token);
      setAiMessages(prev => [
        ...prev,
        {
          sender: 'ai',
          text: res.message,
          action: res.proposed_action
        }
      ]);
    } catch (err: any) {
      setAiMessages(prev => [...prev, { sender: 'ai', text: "Sorry, I couldn't reach the financial engine right now." }]);
    } finally {
      setAiLoading(false);
    }
  };

  if (loading) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Inter, sans-serif' }}>
        <p style={{ fontSize: '18px', color: '#64748B' }}>Connecting to PayNora Authoritative Core...</p>
      </div>
    );
  }

  return (
    <div style={{ minHeight: '100vh', background: '#F8FAFC', fontFamily: 'Inter, sans-serif', paddingBottom: '60px' }}>
      {/* Top Navigation */}
      <header style={{ background: '#FFFFFF', borderBottom: '1px solid #E2E8F0', padding: '18px 40px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
          <a href="/" style={{ textDecoration: 'none', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '26px', fontWeight: 800, color: '#0D253F' }}>PayNora</span>
            <span style={{ fontSize: '12px', fontWeight: 700, color: '#00C853', background: '#E8F5E9', padding: '3px 8px', borderRadius: '8px' }}>CORE</span>
          </a>
          <span style={{ color: '#94A3B8' }}>|</span>
          <span style={{ fontSize: '15px', color: '#475569', fontWeight: 500 }}>
            Welcome back, <strong style={{ color: '#0D253F' }}>{profile?.first_name || 'Customer'} {profile?.last_name || ''}</strong>
          </span>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <span style={{ fontSize: '13px', fontWeight: 600, color: '#16A34A', background: '#DCFCE7', padding: '6px 12px', borderRadius: '20px', display: 'flex', alignItems: 'center', gap: '6px' }}>
            ● KYC {kycStatus?.kyc_status || 'APPROVED'}
          </span>
          <button
            onClick={() => setShowAIChat(true)}
            style={{ padding: '8px 16px', background: '#6C5CE7', color: '#FFF', borderRadius: '8px', border: 'none', fontWeight: 600, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px' }}
          >
            ✨ Ask AI Assistant
          </button>
          <button
            onClick={() => {
              localStorage.removeItem('paynora_token');
              router.push('/');
            }}
            style={{ padding: '8px 16px', background: '#F1F5F9', color: '#475569', borderRadius: '8px', border: '1px solid #CBD5E1', fontWeight: 500, cursor: 'pointer' }}
          >
            Log Out
          </button>
        </div>
      </header>

      {/* Main Container */}
      <main style={{ maxWidth: '1200px', margin: '40px auto 0 auto', padding: '0 20px' }}>
        {/* Quick Action Banner */}
        <div style={{ background: '#0D253F', borderRadius: '20px', padding: '36px 40px', color: '#FFF', display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '36px', boxShadow: '0 10px 30px rgba(13,37,63,0.15)' }}>
          <div>
            <span style={{ fontSize: '14px', color: '#94A3B8', fontWeight: 600, letterSpacing: '0.5px' }}>TOTAL AVAILABLE MULTI-CURRENCY BALANCE</span>
            <h1 style={{ fontSize: '42px', fontWeight: 800, margin: '10px 0 0 0', letterSpacing: '-1px' }}>
              ₦2,450,000.00 <span style={{ fontSize: '18px', color: '#00C853', fontWeight: 600 }}>(+4 currencies active)</span>
            </h1>
          </div>
          <div style={{ display: 'flex', gap: '14px' }}>
            <button
              onClick={() => setShowSendModal(true)}
              style={{ padding: '16px 28px', background: '#00C853', color: '#FFF', fontSize: '16px', fontWeight: 700, borderRadius: '12px', border: 'none', cursor: 'pointer', boxShadow: '0 4px 14px rgba(0,200,83,0.3)' }}
            >
              Send Money Internationally →
            </button>
            <button
              onClick={() => setShowAddWalletModal(true)}
              style={{ padding: '16px 24px', background: 'rgba(255,255,255,0.12)', color: '#FFF', fontSize: '15px', fontWeight: 600, borderRadius: '12px', border: '1px solid rgba(255,255,255,0.2)', cursor: 'pointer' }}
            >
              + Activate Currency
            </button>
          </div>
        </div>

        {/* Multi-Currency Wallets Section */}
        <section style={{ marginBottom: '40px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <h2 style={{ fontSize: '22px', fontWeight: 800, color: '#0D253F', margin: 0 }}>Digital Currency Wallets</h2>
            <button
              onClick={() => setShowAddWalletModal(true)}
              style={{ background: 'none', border: 'none', color: '#0D253F', fontWeight: 700, fontSize: '14px', cursor: 'pointer' }}
            >
              + Add Wallet
            </button>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '20px' }}>
            {wallets.map((w, idx) => (
              <div key={idx} style={{ background: '#FFFFFF', padding: '24px', borderRadius: '16px', border: '1px solid #E2E8F0', boxShadow: '0 4px 15px rgba(0,0,0,0.03)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
                  <span style={{ fontSize: '13px', fontWeight: 700, color: '#64748B' }}>{w.currency} WALLET</span>
                  <span style={{ fontSize: '11px', fontWeight: 700, color: '#00C853', background: '#E8F5E9', padding: '3px 8px', borderRadius: '6px' }}>{w.status}</span>
                </div>
                <div style={{ fontSize: '26px', fontWeight: 800, color: '#0D253F', marginBottom: '8px' }}>
                  {w.currency === 'NGN' ? '₦' : w.currency === 'GBP' ? '£' : w.currency === 'EUR' ? '€' : '$'}
                  {w.available_balance || '0.00'}
                </div>
                <div style={{ fontSize: '12px', color: '#94A3B8' }}>Pending: 0.00 {w.currency}</div>
              </div>
            ))}
          </div>
        </section>

        {/* Beneficiaries & Transactions Grid */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '30px' }}>
          {/* Saved Beneficiaries */}
          <section style={{ background: '#FFFFFF', padding: '28px', borderRadius: '18px', border: '1px solid #E2E8F0' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h3 style={{ fontSize: '18px', fontWeight: 800, color: '#0D253F', margin: 0 }}>Saved Beneficiaries</h3>
              <button
                onClick={() => setShowAddBenModal(true)}
                style={{ background: 'none', border: 'none', color: '#00C853', fontWeight: 700, fontSize: '13px', cursor: 'pointer' }}
              >
                + Add
              </button>
            </div>

            {beneficiaries.length === 0 ? (
              <p style={{ color: '#94A3B8', fontSize: '14px' }}>No saved beneficiaries yet.</p>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                {beneficiaries.map((b, idx) => (
                  <div key={idx} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 14px', background: '#F8FAFC', borderRadius: '10px', border: '1px solid #E2E8F0' }}>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: '14px', color: '#0F172A' }}>{b.name}</div>
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
            )}
          </section>

          {/* Recent Transfers Activity */}
          <section style={{ background: '#FFFFFF', padding: '28px', borderRadius: '18px', border: '1px solid #E2E8F0' }}>
            <h3 style={{ fontSize: '18px', fontWeight: 800, color: '#0D253F', margin: '0 0 20px 0' }}>Recent Transfer History</h3>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {transfers.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '30px', color: '#94A3B8' }}>
                  No international transfers executed yet. Click "Send Money Internationally" to make your first transfer!
                </div>
              ) : (
                transfers.map((tx, idx) => (
                  <div key={idx} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '16px', background: '#F8FAFC', borderRadius: '12px', border: '1px solid #E2E8F0' }}>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: '15px', color: '#0D253F' }}>To: {tx.recipient_name}</div>
                      <div style={{ fontSize: '12px', color: '#64748B' }}>Ref: {tx.transfer_id} • {tx.source_country} → {tx.destination_country}</div>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <div style={{ fontWeight: 800, fontSize: '16px', color: '#0D253F' }}>
                        {tx.source_amount} {tx.source_currency}
                      </div>
                      <span style={{ fontSize: '11px', fontWeight: 700, color: '#8B5CF6', background: '#EDE9FE', padding: '2px 8px', borderRadius: '4px' }}>
                        {tx.state}
                      </span>
                    </div>
                  </div>
                ))
              )}
            </div>
          </section>
        </div>
      </main>

      {/* SEND MONEY MODAL */}
      {showSendModal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '20px' }}>
          <div style={{ background: '#FFF', borderRadius: '20px', width: '100%', maxWidth: '500px', padding: '32px', boxShadow: '0 20px 40px rgba(0,0,0,0.2)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
              <h3 style={{ margin: 0, fontSize: '22px', fontWeight: 800, color: '#0D253F' }}>Send Money Internationally</h3>
              <button onClick={() => setShowSendModal(false)} style={{ background: 'none', border: 'none', fontSize: '20px', cursor: 'pointer', color: '#94A3B8' }}>✕</button>
            </div>

            {sendSuccess && (
              <div style={{ padding: '12px', background: '#DCFCE7', color: '#15803D', borderRadius: '8px', fontSize: '14px', marginBottom: '18px', fontWeight: 600 }}>
                {sendSuccess}
              </div>
            )}

            <div style={{ marginBottom: '18px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>Recipient Name</label>
              <input
                type="text"
                placeholder="e.g. John Doe in London"
                value={sendRecipient}
                onChange={e => setSendRecipient(e.target.value)}
                style={{ width: '100%', padding: '12px', fontSize: '15px', border: '1px solid #CBD5E1', borderRadius: '8px', boxSizing: 'border-box' }}
              />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '12px', marginBottom: '18px' }}>
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
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>Currency</label>
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

            {/* Live FX Quote Box */}
            {fxQuote && (
              <div style={{ background: '#F1F5F9', padding: '16px', borderRadius: '12px', marginBottom: '24px', border: '1px solid #E2E8F0' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', color: '#64748B', marginBottom: '6px' }}>
                  <span>Exchange Rate:</span>
                  <strong>1 {fxQuote.source_currency} = {fxQuote.exchange_rate} {fxQuote.destination_currency}</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', color: '#64748B', marginBottom: '6px' }}>
                  <span>Transfer Fee:</span>
                  <strong>{fxQuote.fee} {fxQuote.source_currency}</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '16px', color: '#0D253F', fontWeight: 800, marginTop: '10px', paddingTop: '10px', borderTop: '1px solid #CBD5E1' }}>
                  <span>Recipient Receives:</span>
                  <span style={{ color: '#00C853' }}>{fxQuote.destination_amount} {fxQuote.destination_currency}</span>
                </div>
              </div>
            )}

            <button
              onClick={handleExecuteTransfer}
              disabled={transferLoading}
              style={{ width: '100%', padding: '16px', background: '#0D253F', color: '#FFF', fontSize: '16px', fontWeight: 700, borderRadius: '10px', border: 'none', cursor: 'pointer' }}
            >
              {transferLoading ? 'Executing Transfer...' : 'Confirm & Authorize Transfer'}
            </button>
          </div>
        </div>
      )}

      {/* ACTIVATE WALLET MODAL */}
      {showAddWalletModal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '20px' }}>
          <div style={{ background: '#FFF', borderRadius: '20px', width: '100%', maxWidth: '420px', padding: '30px' }}>
            <h3 style={{ margin: '0 0 16px 0', fontSize: '20px', fontWeight: 800, color: '#0D253F' }}>Activate Currency Wallet</h3>
            <p style={{ color: '#64748B', fontSize: '14px', marginBottom: '20px' }}>Choose a supported global currency to activate holding capabilities.</p>

            <select
              value={newCurrency}
              onChange={e => setNewCurrency(e.target.value)}
              style={{ width: '100%', padding: '14px', fontSize: '16px', border: '1px solid #CBD5E1', borderRadius: '10px', marginBottom: '24px', background: '#FFF' }}
            >
              <option value="USD">USD — US Dollar 🇺🇸</option>
              <option value="EUR">EUR — Euro 🇪🇺</option>
              <option value="CAD">CAD — Canadian Dollar 🇨🇦</option>
              <option value="AED">AED — UAE Dirham 🇦🇪</option>
              <option value="ZAR">ZAR — South African Rand 🇿🇦</option>
              <option value="CNY">CNY — Chinese Yuan 🇨🇳</option>
            </select>

            <div style={{ display: 'flex', gap: '10px' }}>
              <button onClick={() => setShowAddWalletModal(false)} style={{ flex: 1, padding: '12px', background: '#F1F5F9', border: 'none', borderRadius: '8px', cursor: 'pointer' }}>Cancel</button>
              <button onClick={handleActivateNewWallet} style={{ flex: 1, padding: '12px', background: '#0D253F', color: '#FFF', border: 'none', borderRadius: '8px', fontWeight: 700, cursor: 'pointer' }}>Activate</button>
            </div>
          </div>
        </div>
      )}

      {/* ADD BENEFICIARY MODAL */}
      {showAddBenModal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '20px' }}>
          <div style={{ background: '#FFF', borderRadius: '20px', width: '100%', maxWidth: '450px', padding: '30px' }}>
            <h3 style={{ margin: '0 0 16px 0', fontSize: '20px', fontWeight: 800, color: '#0D253F' }}>Add Recipient</h3>

            <input
              type="text"
              placeholder="Full Legal Name"
              value={benName}
              onChange={e => setBenName(e.target.value)}
              style={{ width: '100%', padding: '12px', fontSize: '15px', border: '1px solid #CBD5E1', borderRadius: '8px', marginBottom: '14px', boxSizing: 'border-box' }}
            />
            <input
              type="text"
              placeholder="Bank Account Number / IBAN"
              value={benAccNumber}
              onChange={e => setBenAccNumber(e.target.value)}
              style={{ width: '100%', padding: '12px', fontSize: '15px', border: '1px solid #CBD5E1', borderRadius: '8px', marginBottom: '24px', boxSizing: 'border-box' }}
            />

            <div style={{ display: 'flex', gap: '10px' }}>
              <button onClick={() => setShowAddBenModal(false)} style={{ flex: 1, padding: '12px', background: '#F1F5F9', border: 'none', borderRadius: '8px', cursor: 'pointer' }}>Cancel</button>
              <button onClick={handleAddBeneficiary} style={{ flex: 1, padding: '12px', background: '#00C853', color: '#FFF', border: 'none', borderRadius: '8px', fontWeight: 700, cursor: 'pointer' }}>Save Beneficiary</button>
            </div>
          </div>
        </div>
      )}

      {/* AI ASSISTANT CHAT DRAWER */}
      {showAIChat && (
        <div style={{ position: 'fixed', bottom: '20px', right: '20px', width: '380px', height: '520px', background: '#FFF', borderRadius: '20px', boxShadow: '0 10px 40px rgba(0,0,0,0.2)', border: '1px solid #CBD5E1', zIndex: 1000, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
          <div style={{ background: '#0D253F', color: '#FFF', padding: '16px 20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontWeight: 700, fontSize: '15px' }}>✨ PayNora AI Financial Assistant</span>
            <button onClick={() => setShowAIChat(false)} style={{ background: 'none', border: 'none', color: '#FFF', fontSize: '16px', cursor: 'pointer' }}>✕</button>
          </div>

          <div style={{ flex: 1, padding: '16px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {aiMessages.map((m, idx) => (
              <div key={idx} style={{ alignSelf: m.sender === 'user' ? 'flex-end' : 'flex-start', maxWidth: '85%' }}>
                <div style={{ padding: '10px 14px', borderRadius: '12px', fontSize: '14px', background: m.sender === 'user' ? '#0D253F' : '#F1F5F9', color: m.sender === 'user' ? '#FFF' : '#0F172A' }}>
                  {m.text}
                </div>
                {m.action && (
                  <div style={{ marginTop: '6px', padding: '10px', background: '#E8F5E9', borderRadius: '8px', border: '1px solid #A5D6A7' }}>
                    <div style={{ fontSize: '12px', fontWeight: 700, color: '#1B5E20' }}>PROPOSED ACTION:</div>
                    <div style={{ fontSize: '13px', color: '#2E7D32' }}>Send {m.action.source_amount} {m.action.source_currency} to {m.action.recipient_name}</div>
                    <button
                      onClick={() => {
                        setSendRecipient(m.action.recipient_name);
                        setSendAmount(m.action.source_amount);
                        setShowSendModal(true);
                      }}
                      style={{ marginTop: '6px', padding: '6px 12px', background: '#00C853', color: '#FFF', border: 'none', borderRadius: '6px', fontSize: '12px', fontWeight: 700, cursor: 'pointer' }}
                    >
                      Review & Confirm →
                    </button>
                  </div>
                )}
              </div>
            ))}
            {aiLoading && (
              <div style={{ alignSelf: 'flex-start', color: '#94A3B8', fontSize: '13px' }}>AI is thinking...</div>
            )}
          </div>

          <div style={{ padding: '12px', borderTop: '1px solid #E2E8F0', display: 'flex', gap: '8px' }}>
            <input
              type="text"
              placeholder="Ask anything..."
              value={aiPrompt}
              onChange={e => setAiPrompt(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && handleSendAIChat()}
              style={{ flex: 1, padding: '10px 14px', fontSize: '14px', border: '1px solid #CBD5E1', borderRadius: '8px', outline: 'none' }}
            />
            <button
              onClick={handleSendAIChat}
              style={{ padding: '10px 16px', background: '#0D253F', color: '#FFF', border: 'none', borderRadius: '8px', fontWeight: 700, cursor: 'pointer' }}
            >
              Send
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
