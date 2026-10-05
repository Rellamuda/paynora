'use client';

import React, { useEffect, useState } from 'react';
import { fetchActiveCountries, checkHealth } from '../lib/api-client';

const FALLBACK_COUNTRIES = [
  { iso_code: 'NG', name: 'Nigeria', flag: '🇳🇬', primary_currency: 'NGN' },
  { iso_code: 'GB', name: 'United Kingdom', flag: '🇬🇧', primary_currency: 'GBP' },
  { iso_code: 'US', name: 'United States', flag: '🇺🇸', primary_currency: 'USD' },
  { iso_code: 'CA', name: 'Canada', flag: '🇨🇦', primary_currency: 'CAD' },
  { iso_code: 'AE', name: 'United Arab Emirates', flag: '🇦🇪', primary_currency: 'AED' },
  { iso_code: 'GH', name: 'Ghana', flag: '🇬🇭', primary_currency: 'GHS' },
  { iso_code: 'ZA', name: 'South Africa', flag: '🇿🇦', primary_currency: 'ZAR' },
  { iso_code: 'DE', name: 'Germany', flag: '🇩🇪', primary_currency: 'EUR' },
  { iso_code: 'FR', name: 'France', flag: '🇫🇷', primary_currency: 'EUR' },
  { iso_code: 'SA', name: 'Saudi Arabia', flag: '🇸🇦', primary_currency: 'SAR' },
  { iso_code: 'CN', name: 'China', flag: '🇨🇳', primary_currency: 'CNY' }
];

export default function LandingPage() {
  const [activeCountries, setActiveCountries] = useState<any[]>(FALLBACK_COUNTRIES);
  const [apiHealth, setApiHealth] = useState<any>(null);

  useEffect(() => {
    async function loadData() {
      try {
        const health = await checkHealth();
        setApiHealth(health);
        const countriesData = await fetchActiveCountries();
        if (countriesData.countries && countriesData.countries.length > 0) {
          setActiveCountries(countriesData.countries);
        }
      } catch (err) {
        console.warn('Using initial country catalog while connecting to API:', err);
      }
    }
    loadData();
  }, []);

  return (
    <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '40px 20px', fontFamily: 'Inter, sans-serif' }}>
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '60px' }}>
        <div style={{ fontSize: '28px', fontWeight: '800', color: '#0D253F', letterSpacing: '-0.5px' }}>
          PayNora <span style={{ fontSize: '12px', color: '#00C853', background: '#E8F5E9', padding: '4px 10px', borderRadius: '12px', fontWeight: '700' }}>GLOBAL FINTECH</span>
        </div>
        <nav style={{ display: 'flex', gap: '16px' }}>
          <a href="/onboarding" style={{ padding: '12px 24px', background: '#00C853', color: '#FFF', borderRadius: '10px', textDecoration: 'none', fontWeight: '700', boxShadow: '0 4px 14px rgba(0,200,83,0.3)' }}>
            Get Started →
          </a>
          <a href="/dashboard" style={{ padding: '12px 24px', background: '#0D253F', color: '#FFF', borderRadius: '10px', textDecoration: 'none', fontWeight: '700' }}>
            Open Dashboard
          </a>
        </nav>
      </header>

      <main style={{ textAlign: 'center', margin: '40px 0' }}>
        <h1 style={{ fontSize: '52px', fontWeight: '800', color: '#0D253F', marginBottom: '20px', letterSpacing: '-1.5px', lineHeight: 1.15 }}>
          Global Money Movement Engine & Multi-Currency Platform
        </h1>
        <p style={{ fontSize: '20px', color: '#475569', maxWidth: '820px', margin: '0 auto 40px', lineHeight: 1.6 }}>
          Instant, deterministic cross-border transfers and multi-currency wallets backed by double-entry accounting, real-time FX rate locking, and conversational AI financial intelligence.
        </p>

        <div style={{ display: 'flex', justifyContent: 'center', gap: '16px', marginBottom: '60px' }}>
          <a href="/onboarding" style={{ padding: '16px 36px', background: '#00C853', color: '#FFF', fontSize: '18px', fontWeight: '700', borderRadius: '12px', textDecoration: 'none' }}>
            Create Account & Verify ID →
          </a>
          <a href="/dashboard" style={{ padding: '16px 32px', background: '#F1F5F9', color: '#0D253F', fontSize: '18px', fontWeight: '700', borderRadius: '12px', textDecoration: 'none', border: '1px solid #CBD5E1' }}>
            Launch Dashboard
          </a>
        </div>

        {/* 11 Active Countries Grid */}
        <div style={{ background: '#FFF', padding: '36px', borderRadius: '20px', boxShadow: '0 8px 30px rgba(0,0,0,0.06)', border: '1px solid #E2E8F0', textAlign: 'left', maxWidth: '1000px', margin: '0 auto' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
            <div>
              <h3 style={{ margin: 0, fontSize: '22px', fontWeight: '800', color: '#0D253F' }}>Initial 11 Active Operating Corridors</h3>
              <p style={{ margin: '4px 0 0 0', color: '#64748B', fontSize: '14px' }}>Fully activated for cross-border sending, receiving, holding, and exchange.</p>
            </div>
            <span style={{ fontSize: '12px', fontWeight: '700', color: '#00C853', background: '#E8F5E9', padding: '6px 12px', borderRadius: '20px' }}>
              ● 11 ACTIVE CORRIDORS
            </span>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '16px' }}>
            {activeCountries.map((country) => (
              <div key={country.iso_code} style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '14px 18px', background: '#F8FAFC', borderRadius: '12px', border: '1px solid #E2E8F0' }}>
                <span style={{ fontSize: '28px' }}>{country.flag}</span>
                <div>
                  <div style={{ fontWeight: '700', fontSize: '15px', color: '#0F172A' }}>{country.name}</div>
                  <div style={{ fontSize: '12px', color: '#64748B', fontWeight: '500' }}>Currency: <strong>{country.primary_currency}</strong></div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {apiHealth && (
          <div style={{ marginTop: '36px', fontSize: '14px', color: '#10B981', fontWeight: '600' }}>
            ● System Status: {apiHealth.status.toUpperCase()} ({apiHealth.service})
          </div>
        )}
      </main>
    </div>
  );
}
