'use client';

import React, { useEffect, useState } from 'react';
import { fetchActiveCountries, checkHealth } from '../lib/api-client';

export default function LandingPage() {
  const [activeCountries, setActiveCountries] = useState<any[]>([]);
  const [apiHealth, setApiHealth] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadData() {
      try {
        const health = await checkHealth();
        setApiHealth(health);
        const countriesData = await fetchActiveCountries();
        setActiveCountries(countriesData.countries || []);
      } catch (err) {
        console.error("API connection error:", err);
      } finally {
        setLoading(false);
      }
    }
    loadData();
  }, []);

  return (
    <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '40px 20px' }}>
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '60px' }}>
        <div style={{ fontSize: '28px', fontWeight: 'bold', color: '#0D253F' }}>
          PayNora <span style={{ fontSize: '14px', color: '#00C853', background: '#E8F5E9', padding: '4px 8px', borderRadius: '4px' }}>GLOBAL FINTECH</span>
        </div>
        <nav style={{ display: 'flex', gap: '20px' }}>
          <a href="/onboarding" style={{ padding: '10px 20px', background: '#0D253F', color: '#FFF', borderRadius: '8px', textDecoration: 'none', fontWeight: '500' }}>Get Started</a>
          <a href="/dashboard" style={{ padding: '10px 20px', border: '1px solid #CBD5E1', borderRadius: '8px', textDecoration: 'none', color: '#0F172A' }}>Dashboard</a>
        </nav>
      </header>

      <main style={{ textAlign: 'center', margin: '60px 0' }}>
        <h1 style={{ fontSize: '48px', fontWeight: '800', color: '#0D253F', marginBottom: '20px' }}>
          Global Money Movement Engine & Multi-Currency Platform
        </h1>
        <p style={{ fontSize: '20px', color: '#475569', maxWidth: '800px', margin: '0 auto 40px' }}>
          Instant, auditable cross-border transfers and wallets powered by deterministic double-entry accounting and AI financial intelligence.
        </p>

        <div style={{ display: 'inline-block', background: '#FFF', padding: '24px 32px', borderRadius: '12px', boxShadow: '0 4px 20px rgba(0,0,0,0.06)', textAlign: 'left' }}>
          <h3 style={{ margin: '0 0 16px 0', fontSize: '18px', color: '#0D253F' }}>Initial 11 Active Operational Countries</h3>
          {loading ? (
            <p style={{ color: '#94A3B8' }}>Connecting to PayNora FastAPI Core...</p>
          ) : (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '16px' }}>
              {activeCountries.map((country) => (
                <div key={country.iso_code} style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '10px 14px', background: '#F8FAFC', borderRadius: '8px', border: '1px solid #E2E8F0' }}>
                  <span style={{ fontSize: '24px' }}>{country.flag}</span>
                  <div>
                    <div style={{ fontWeight: '600', fontSize: '14px' }}>{country.name}</div>
                    <div style={{ fontSize: '12px', color: '#64748B' }}>{country.primary_currency}</div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {apiHealth && (
          <div style={{ marginTop: '40px', fontSize: '14px', color: '#10B981' }}>
            ● System Status: {apiHealth.status.toUpperCase()} ({apiHealth.service})
          </div>
        )}
      </main>
    </div>
  );
}
