import React from 'react';

export default function AdminDashboard() {
  return (
    <html lang="en">
      <body style={{ margin: 0, fontFamily: 'Inter, sans-serif', backgroundColor: '#0A0F1D', color: '#F1F5F9' }}>
        <div style={{ padding: '30px' }}>
          <header style={{ borderBottom: '1px solid #1E293B', paddingBottom: '20px', marginBottom: '30px' }}>
            <h1 style={{ margin: 0, fontSize: '24px', color: '#00C853' }}>PayNora — Operational & Compliance Admin Control Center</h1>
            <p style={{ margin: '5px 0 0 0', color: '#94A3B8', fontSize: '14px' }}>Role-Based Access Control • Ledger Audit • Corridor Management</p>
          </header>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '20px' }}>
            <div style={{ background: '#121A2D', padding: '20px', borderRadius: '8px', border: '1px solid #1E293B' }}>
              <h3 style={{ marginTop: 0, color: '#94A3B8' }}>Active Corridors</h3>
              <p style={{ fontSize: '28px', fontWeight: 'bold', margin: 0 }}>11 Corridors Active</p>
            </div>
            <div style={{ background: '#121A2D', padding: '20px', borderRadius: '8px', border: '1px solid #1E293B' }}>
              <h3 style={{ marginTop: 0, color: '#94A3B8' }}>System Ledger Status</h3>
              <p style={{ fontSize: '28px', fontWeight: 'bold', margin: 0, color: '#10B981' }}>BALANCED (0 Discrepancies)</p>
            </div>
            <div style={{ background: '#121A2D', padding: '20px', borderRadius: '8px', border: '1px solid #1E293B' }}>
              <h3 style={{ marginTop: 0, color: '#94A3B8' }}>Compliance & KYC Queue</h3>
              <p style={{ fontSize: '28px', fontWeight: 'bold', margin: 0 }}>0 Review Pending</p>
            </div>
          </div>
        </div>
      </body>
    </html>
  );
}
