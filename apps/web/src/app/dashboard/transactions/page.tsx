'use client';

import React, { useEffect, useState } from 'react';
import { fetchTransfers, confirmTransfer } from '../../../lib/api-client';

export default function TransactionsPage() {
  const [transfers, setTransfers] = useState<any[]>([]);
  const [filter, setFilter] = useState('ALL');
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [selectedTx, setSelectedTx] = useState<any>(null);

  useEffect(() => {
    loadTransactions();
  }, []);

  const loadTransactions = async () => {
    setLoading(true);
    try {
      const res = await fetchTransfers();
      setTransfers(res.transfers || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleConfirm = async (transferId: string) => {
    try {
      await confirmTransfer(transferId);
      await loadTransactions();
      if (selectedTx && selectedTx.transfer_id === transferId) {
        setSelectedTx({ ...selectedTx, state: 'COMPLETED' });
      }
    } catch (err: any) {
      alert(err.message || 'Confirmation failed');
    }
  };

  const filteredTransfers = transfers.filter(tx => {
    if (filter !== 'ALL' && tx.state !== filter) return false;
    if (search.trim()) {
      const query = search.toLowerCase();
      const matchName = tx.recipient_name?.toLowerCase().includes(query);
      const matchRef = tx.transfer_id?.toLowerCase().includes(query);
      return matchName || matchRef;
    }
    return true;
  });

  return (
    <div style={{ maxWidth: '1100px', margin: '0 auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
        <div>
          <h1 style={{ fontSize: '32px', fontWeight: 800, color: '#0D253F', margin: '0 0 6px 0' }}>Transactions & Settlement Ledger</h1>
          <p style={{ color: '#64748B', fontSize: '15px', margin: 0 }}>Cryptographically verifiable, immutable double-entry journal records.</p>
        </div>
        <button
          onClick={loadTransactions}
          style={{ padding: '10px 18px', background: '#F1F5F9', border: '1px solid #CBD5E1', borderRadius: '8px', fontSize: '13px', fontWeight: 600, color: '#0D253F', cursor: 'pointer' }}
        >
          ↻ Refresh Ledger
        </button>
      </div>

      {/* Filter and Search Bar */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px', gap: '16px' }}>
        <div style={{ display: 'flex', gap: '8px' }}>
          {['ALL', 'COMPLETED', 'PROCESSING', 'AWAITING_CONFIRMATION'].map(f => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              style={{
                padding: '8px 16px',
                borderRadius: '8px',
                fontSize: '13px',
                fontWeight: 600,
                border: 'none',
                cursor: 'pointer',
                background: filter === f ? '#0D253F' : '#FFF',
                color: filter === f ? '#FFF' : '#64748B',
                boxShadow: '0 2px 6px rgba(0,0,0,0.03)'
              }}
            >
              {f.replace('_', ' ')}
            </button>
          ))}
        </div>

        <input
          type="text"
          placeholder="Search by recipient or reference..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          style={{ width: '320px', padding: '10px 14px', fontSize: '14px', border: '1px solid #CBD5E1', borderRadius: '8px', outline: 'none' }}
        />
      </div>

      {/* Transactions Table */}
      <div style={{ background: '#FFF', borderRadius: '16px', border: '1px solid #E2E8F0', overflow: 'hidden', boxShadow: '0 4px 20px rgba(0,0,0,0.02)' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '14px' }}>
          <thead>
            <tr style={{ background: '#F8FAFC', borderBottom: '1px solid #E2E8F0', color: '#64748B', fontWeight: 600 }}>
              <th style={{ padding: '16px 20px' }}>Reference</th>
              <th style={{ padding: '16px 20px' }}>Recipient</th>
              <th style={{ padding: '16px 20px' }}>Corridor</th>
              <th style={{ padding: '16px 20px' }}>Amount</th>
              <th style={{ padding: '16px 20px' }}>State</th>
              <th style={{ padding: '16px 20px', textAlign: 'right' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredTransfers.length === 0 ? (
              <tr>
                <td colSpan={6} style={{ padding: '40px', textAlign: 'center', color: '#94A3B8' }}>
                  No transactions match the selected filter.
                </td>
              </tr>
            ) : (
              filteredTransfers.map((tx, idx) => (
                <tr key={idx} style={{ borderBottom: '1px solid #F1F5F9', transition: 'background 0.15s' }}>
                  <td style={{ padding: '16px 20px' }}>
                    <code style={{ fontSize: '13px', color: '#0D253F', fontWeight: 600 }}>{tx.transfer_id}</code>
                  </td>
                  <td style={{ padding: '16px 20px', fontWeight: 700, color: '#0D253F' }}>
                    {tx.recipient_name}
                  </td>
                  <td style={{ padding: '16px 20px', color: '#64748B' }}>
                    {tx.source_country} ➔ {tx.destination_country}
                  </td>
                  <td style={{ padding: '16px 20px', fontWeight: 800, color: '#0D253F' }}>
                    {tx.source_amount} {tx.source_currency}
                  </td>
                  <td style={{ padding: '16px 20px' }}>
                    <span style={{
                      fontSize: '11px',
                      fontWeight: 700,
                      padding: '3px 8px',
                      borderRadius: '6px',
                      color: tx.state === 'COMPLETED' ? '#16A34A' : '#7C3AED',
                      background: tx.state === 'COMPLETED' ? '#DCFCE7' : '#EDE9FE'
                    }}>
                      {tx.state}
                    </span>
                  </td>
                  <td style={{ padding: '16px 20px', textAlign: 'right' }}>
                    <div style={{ display: 'inline-flex', gap: '8px' }}>
                      {tx.state !== 'COMPLETED' && (
                        <button
                          onClick={() => handleConfirm(tx.transfer_id)}
                          style={{ padding: '6px 10px', background: '#00C853', color: '#FFF', border: 'none', borderRadius: '6px', fontSize: '12px', fontWeight: 700, cursor: 'pointer' }}
                        >
                          Settle
                        </button>
                      )}
                      <button
                        onClick={() => setSelectedTx(tx)}
                        style={{ padding: '6px 12px', background: '#F1F5F9', color: '#0D253F', border: '1px solid #CBD5E1', borderRadius: '6px', fontSize: '12px', fontWeight: 600, cursor: 'pointer' }}
                      >
                        Receipt
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* RECEIPT MODAL */}
      {selectedTx && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '20px' }}>
          <div style={{ background: '#FFF', borderRadius: '20px', width: '100%', maxWidth: '480px', padding: '32px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h3 style={{ margin: 0, fontSize: '20px', fontWeight: 800, color: '#0D253F' }}>Settlement Receipt</h3>
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
                <span>Transfer Reference:</span>
                <code style={{ color: '#0D253F' }}>{selectedTx.transfer_id}</code>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', color: '#64748B' }}>
                <span>Recipient:</span>
                <strong style={{ color: '#0D253F' }}>{selectedTx.recipient_name}</strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', color: '#64748B' }}>
                <span>Corridor:</span>
                <strong>{selectedTx.source_country} ➔ {selectedTx.destination_country}</strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', color: '#64748B' }}>
                <span>Estimated Clearing Fee:</span>
                <strong>{selectedTx.estimated_fee || '500.00'} {selectedTx.source_currency}</strong>
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
