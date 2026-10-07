'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { loginUser } from '../../lib/api-client';
import { useTheme } from '../../lib/theme-context';

export default function LoginPage() {
  const router = useRouter();
  const { isDark, toggleTheme } = useTheme();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!email.trim() || !password.trim()) {
      setError('Please enter your email and password.');
      return;
    }

    setLoading(true);
    setError('');
    try {
      const data = await loginUser({ email: email.trim(), password });
      if (data && data.access_token) {
        localStorage.setItem('paynora_token', data.access_token);
        localStorage.setItem('paynora_user_email', email.trim());
        router.push('/dashboard');
      } else {
        throw new Error('Authentication succeeded but token was missing.');
      }
    } catch (err: any) {
      setError(err.message || 'Invalid email or password.');
    } finally {
      setLoading(false);
    }
  };

  const handleDemoLogin = async () => {
    setEmail('customer@paynora.com');
    setPassword('PayNora#2026!');
    setLoading(true);
    setError('');
    try {
      const data = await loginUser({ email: 'customer@paynora.com', password: 'PayNora#2026!' });
      if (data && data.access_token) {
        localStorage.setItem('paynora_token', data.access_token);
        localStorage.setItem('paynora_user_email', 'customer@paynora.com');
        router.push('/dashboard');
      }
    } catch {
      // If demo account not registered yet in DB, simulate instant session
      localStorage.setItem('paynora_token', 'demo_jwt_session_token_2026');
      localStorage.setItem('paynora_user_email', 'customer@paynora.com');
      router.push('/dashboard');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'center',
      alignItems: 'center',
      padding: '24px',
      background: isDark ? '#050B17' : '#F8FAFC',
      fontFamily: 'Inter, sans-serif'
    }}>
      <div style={{ position: 'absolute', top: '24px', right: '24px' }}>
        <button
          onClick={toggleTheme}
          style={{
            padding: '8px 14px',
            background: isDark ? 'rgba(255,255,255,0.08)' : '#FFF',
            color: isDark ? '#FFF' : '#0F172A',
            border: '1px solid',
            borderColor: isDark ? '#1C2B4E' : '#E2E8F0',
            borderRadius: '10px',
            fontSize: '13px',
            fontWeight: 600,
            cursor: 'pointer'
          }}
        >
          {isDark ? '🌙 Dark' : '☀️ Light'}
        </button>
      </div>

      <div style={{
        width: '100%',
        maxWidth: '440px',
        background: isDark ? '#0D1A30' : '#FFFFFF',
        borderRadius: '20px',
        padding: '40px',
        boxShadow: '0 20px 40px -15px rgba(0,0,0,0.07)',
        border: '1px solid',
        borderColor: isDark ? '#1C2B4E' : '#E2E8F0'
      }}>
        {/* Brand */}
        <div style={{ textAlign: 'center', marginBottom: '32px' }}>
          <img src="/logo.png" alt="PayNora Logo" style={{ width: '48px', height: '48px', borderRadius: '12px', marginBottom: '12px' }} />
          <h1 style={{ fontSize: '26px', fontWeight: 800, color: isDark ? '#FFF' : '#0A1128', margin: '0 0 6px 0', letterSpacing: '-0.5px' }}>
            Welcome Back
          </h1>
          <p style={{ fontSize: '14px', color: isDark ? '#94A3B8' : '#64748B', margin: 0 }}>
            Sign in to access your Double Currency Wallets
          </p>
        </div>

        {error && (
          <div style={{
            padding: '12px 16px',
            background: 'rgba(239, 68, 68, 0.1)',
            border: '1px solid #EF4444',
            color: '#EF4444',
            borderRadius: '10px',
            fontSize: '13px',
            marginBottom: '20px'
          }}>
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '18px' }}>
          <div>
            <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: isDark ? '#CBD5E1' : '#334155', marginBottom: '6px' }}>
              Email Address
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="name@example.com"
              required
              style={{
                width: '100%',
                padding: '12px 16px',
                borderRadius: '10px',
                border: '1px solid',
                borderColor: isDark ? '#1E293B' : '#CBD5E1',
                background: isDark ? '#070D1C' : '#F8FAFC',
                color: isDark ? '#FFF' : '#0F172A',
                fontSize: '14px',
                outline: 'none',
                boxSizing: 'border-box'
              }}
            />
          </div>

          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
              <label style={{ fontSize: '13px', fontWeight: 600, color: isDark ? '#CBD5E1' : '#334155' }}>
                Password
              </label>
            </div>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••••••"
              required
              style={{
                width: '100%',
                padding: '12px 16px',
                borderRadius: '10px',
                border: '1px solid',
                borderColor: isDark ? '#1E293B' : '#CBD5E1',
                background: isDark ? '#070D1C' : '#F8FAFC',
                color: isDark ? '#FFF' : '#0F172A',
                fontSize: '14px',
                outline: 'none',
                boxSizing: 'border-box'
              }}
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            style={{
              padding: '14px',
              background: '#00C853',
              color: '#FFFFFF',
              border: 'none',
              borderRadius: '12px',
              fontSize: '15px',
              fontWeight: 700,
              cursor: loading ? 'not-allowed' : 'pointer',
              marginTop: '6px',
              boxShadow: '0 4px 14px rgba(0, 200, 83, 0.3)'
            }}
          >
            {loading ? 'Authenticating...' : 'Sign In →'}
          </button>
        </form>

        <div style={{ margin: '20px 0', textAlign: 'center', position: 'relative' }}>
          <div style={{ borderTop: '1px solid', borderColor: isDark ? '#1E293B' : '#E2E8F0' }}></div>
          <span style={{
            position: 'absolute',
            top: '-10px',
            left: '50%',
            transform: 'translateX(-50%)',
            background: isDark ? '#0D1A30' : '#FFFFFF',
            padding: '0 12px',
            fontSize: '12px',
            color: '#94A3B8'
          }}>
            OR
          </span>
        </div>

        <button
          type="button"
          onClick={handleDemoLogin}
          style={{
            width: '100%',
            padding: '12px',
            background: isDark ? 'rgba(255,255,255,0.06)' : '#F1F5F9',
            color: isDark ? '#FFF' : '#0F172A',
            border: '1px solid',
            borderColor: isDark ? '#1E293B' : '#E2E8F0',
            borderRadius: '10px',
            fontSize: '13px',
            fontWeight: 600,
            cursor: 'pointer'
          }}
        >
          ⚡ Fast Demo Sign-In
        </button>

        <p style={{ textAlign: 'center', marginTop: '24px', fontSize: '13px', color: isDark ? '#94A3B8' : '#64748B' }}>
          Don't have an account?{' '}
          <a href="/onboarding" style={{ color: '#00C853', fontWeight: 700, textDecoration: 'none' }}>
            Register here
          </a>
        </p>
      </div>
    </div>
  );
}
