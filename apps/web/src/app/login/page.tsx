'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { loginUser, registerUser } from '../../lib/api-client';
import { useTheme } from '../../lib/theme-context';

const COUNTRIES = [
  { code: 'NG', name: 'Nigeria', flag: '🇳🇬', curr: 'NGN', dial: '+234' },
  { code: 'GB', name: 'United Kingdom', flag: '🇬🇧', curr: 'GBP', dial: '+44' },
  { code: 'US', name: 'United States', flag: '🇺🇸', curr: 'USD', dial: '+1' },
  { code: 'CA', name: 'Canada', flag: '🇨🇦', curr: 'CAD', dial: '+1' },
  { code: 'AE', name: 'United Arab Emirates', flag: '🇦🇪', curr: 'AED', dial: '+971' },
  { code: 'GH', name: 'Ghana', flag: '🇬🇭', curr: 'GHS', dial: '+233' },
  { code: 'ZA', name: 'South Africa', flag: '🇿🇦', curr: 'ZAR', dial: '+27' },
  { code: 'DE', name: 'Germany', flag: '🇩🇪', curr: 'EUR', dial: '+49' },
  { code: 'FR', name: 'France', flag: '🇫🇷', curr: 'EUR', dial: '+33' },
  { code: 'SA', name: 'Saudi Arabia', flag: '🇸🇦', curr: 'SAR', dial: '+966' },
  { code: 'CN', name: 'China', flag: '🇨🇳', curr: 'CNY', dial: '+86' }
];

export default function AuthPage() {
  const router = useRouter();
  const { isDark, toggleTheme } = useTheme();

  // Mode: 'signin' or 'signup'
  const [mode, setMode] = useState<'signin' | 'signup'>('signin');

  // Sign In State
  const [loginEmail, setLoginEmail] = useState('');
  const [loginPassword, setLoginPassword] = useState('');
  const [showLoginPassword, setShowLoginPassword] = useState(false);

  // Sign Up State
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [countryCode, setCountryCode] = useState('NG');
  const [phone, setPhone] = useState('');
  const [signUpEmail, setSignUpEmail] = useState('');
  const [signUpPassword, setSignUpPassword] = useState('');
  const [showSignUpPassword, setShowSignUpPassword] = useState(false);

  // Common UI State
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [showForgotModal, setShowForgotModal] = useState(false);
  const [forgotEmail, setForgotEmail] = useState('');
  const [forgotSent, setForgotSent] = useState(false);

  const selectedCountry = COUNTRIES.find(c => c.code === countryCode) || COUNTRIES[0];

  const handleSignIn = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!loginEmail.trim() || !loginPassword.trim()) {
      setError('Please provide your email address and password.');
      return;
    }

    setLoading(true);
    setError('');
    setSuccess('');

    try {
      const data = await loginUser({ email: loginEmail.trim().toLowerCase(), password: loginPassword });
      if (data && data.access_token) {
        localStorage.setItem('paynora_token', data.access_token);
        localStorage.setItem('paynora_user_email', loginEmail.trim().toLowerCase());
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

  const handleDemoSignIn = async () => {
    setLoading(true);
    setError('');
    setSuccess('');
    try {
      const data = await loginUser({ email: 'customer@paynora.com', password: 'PayNora#2026!' });
      if (data && data.access_token) {
        localStorage.setItem('paynora_token', data.access_token);
        localStorage.setItem('paynora_user_email', 'customer@paynora.com');
        router.push('/dashboard');
      }
    } catch {
      localStorage.setItem('paynora_token', 'demo_jwt_session_token_2026');
      localStorage.setItem('paynora_user_email', 'customer@paynora.com');
      router.push('/dashboard');
    } finally {
      setLoading(false);
    }
  };

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!firstName.trim() || !lastName.trim()) {
      setError('Please enter your legal first and last name.');
      return;
    }
    if (!signUpEmail.trim() || !signUpEmail.includes('@')) {
      setError('Please enter a valid email address.');
      return;
    }
    if (!phone.trim()) {
      setError('Please enter your phone number.');
      return;
    }
    if (signUpPassword.length < 8) {
      setError('Password must be at least 8 characters long.');
      return;
    }

    setLoading(true);
    setError('');
    setSuccess('');

    try {
      const cleanPhone = phone.trim().replace(/^0+/, '');
      const fullPhone = `${selectedCountry.dial}${cleanPhone}`;

      // 1. Register User
      await registerUser({
        first_name: firstName.trim(),
        last_name: lastName.trim(),
        email: signUpEmail.trim().toLowerCase(),
        phone: fullPhone,
        country_iso: countryCode,
        password: signUpPassword
      });

      // 2. Automatically Log In
      const loginRes = await loginUser({
        email: signUpEmail.trim().toLowerCase(),
        password: signUpPassword
      });

      if (loginRes && loginRes.access_token) {
        localStorage.setItem('paynora_token', loginRes.access_token);
        localStorage.setItem('paynora_user_email', signUpEmail.trim().toLowerCase());
        setSuccess(`Welcome to PayNora, ${firstName}! Your ${selectedCountry.curr} + USD Double Wallets are ready.`);
        setTimeout(() => {
          router.push('/dashboard');
        }, 1200);
      } else {
        setSuccess('Registration successful! Please sign in to your new account.');
        setMode('signin');
        setLoginEmail(signUpEmail.trim());
      }
    } catch (err: any) {
      setError(err.message || 'Registration failed. Please check your information.');
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
      padding: '32px 16px',
      background: isDark ? '#050B17' : '#F8FAFC',
      fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    }}>
      {/* Top Right Controls */}
      <div style={{ position: 'absolute', top: '24px', right: '24px', display: 'flex', gap: '10px' }}>
        <button
          onClick={toggleTheme}
          style={{
            padding: '8px 14px',
            background: isDark ? 'rgba(255,255,255,0.08)' : '#FFF',
            color: isDark ? '#FFF' : '#0F172A',
            border: `1px solid ${isDark ? '#1C2B4E' : '#E2E8F0'}`,
            borderRadius: '10px',
            fontSize: '13px',
            fontWeight: 600,
            cursor: 'pointer',
            display: 'inline-flex',
            alignItems: 'center',
            gap: '6px'
          }}
        >
          <span>{isDark ? '🌙' : '☀️'}</span>
          <span>{isDark ? 'Dark Theme' : 'Light Theme'}</span>
        </button>
      </div>

      {/* Main Card */}
      <div style={{
        width: '100%',
        maxWidth: '460px',
        background: isDark ? '#0D1A30' : '#FFFFFF',
        borderRadius: '24px',
        padding: '36px',
        boxShadow: isDark ? '0 20px 50px rgba(0,0,0,0.5)' : '0 20px 40px -15px rgba(0,0,0,0.07)',
        border: `1px solid ${isDark ? '#1C2B4E' : '#E2E8F0'}`
      }}>
        {/* Brand Header */}
        <div style={{ textAlign: 'center', marginBottom: '24px' }}>
          <a href="/" style={{ textDecoration: 'none', display: 'inline-block' }}>
            <div style={{
              width: '56px',
              height: '56px',
              borderRadius: '16px',
              background: '#0D253F',
              margin: '0 auto 14px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              boxShadow: '0 8px 24px rgba(13, 37, 63, 0.35)'
            }}>
              <img src="/logo.png" alt="PayNora" style={{ width: '38px', height: '38px', borderRadius: '10px' }} />
            </div>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
              <span style={{ fontSize: '26px', fontWeight: 800, color: isDark ? '#FFF' : '#0D253F', letterSpacing: '-0.5px' }}>
                PayNora
              </span>
              <span style={{ fontSize: '10px', fontWeight: 800, color: '#00C853', background: 'rgba(0, 200, 83, 0.15)', padding: '3px 7px', borderRadius: '6px' }}>
                GLOBAL
              </span>
            </div>
          </a>
          <p style={{ margin: '6px 0 0', fontSize: '13px', color: isDark ? '#94A3B8' : '#64748B', fontWeight: 500 }}>
            Double Currency Digital Wallets (Local Currency + USD)
          </p>
        </div>

        {/* Tab Switcher */}
        <div style={{
          display: 'flex',
          background: isDark ? '#070D1C' : '#F1F5F9',
          padding: '4px',
          borderRadius: '14px',
          marginBottom: '24px'
        }}>
          <button
            type="button"
            onClick={() => { setMode('signin'); setError(''); setSuccess(''); }}
            style={{
              flex: 1,
              padding: '10px',
              borderRadius: '10px',
              border: 'none',
              background: mode === 'signin' ? (isDark ? '#162444' : '#FFFFFF') : 'transparent',
              color: mode === 'signin' ? (isDark ? '#FFFFFF' : '#0D253F') : (isDark ? '#64748B' : '#64748B'),
              fontWeight: 700,
              fontSize: '14px',
              cursor: 'pointer',
              boxShadow: mode === 'signin' ? '0 2px 8px rgba(0,0,0,0.06)' : 'none',
              transition: 'all 0.2s'
            }}
          >
            Sign In
          </button>
          <button
            type="button"
            onClick={() => { setMode('signup'); setError(''); setSuccess(''); }}
            style={{
              flex: 1,
              padding: '10px',
              borderRadius: '10px',
              border: 'none',
              background: mode === 'signup' ? (isDark ? '#162444' : '#FFFFFF') : 'transparent',
              color: mode === 'signup' ? (isDark ? '#FFFFFF' : '#0D253F') : (isDark ? '#64748B' : '#64748B'),
              fontWeight: 700,
              fontSize: '14px',
              cursor: 'pointer',
              boxShadow: mode === 'signup' ? '0 2px 8px rgba(0,0,0,0.06)' : 'none',
              transition: 'all 0.2s'
            }}
          >
            Create Account
          </button>
        </div>

        {/* Error Alert */}
        {error && (
          <div style={{
            padding: '12px 14px',
            background: 'rgba(239, 68, 68, 0.12)',
            border: '1px solid rgba(239, 68, 68, 0.3)',
            borderRadius: '10px',
            color: '#EF4444',
            fontSize: '13px',
            marginBottom: '18px',
            fontWeight: 600,
            display: 'flex',
            alignItems: 'center',
            gap: '8px'
          }}>
            <span>⚠️</span>
            <span>{error}</span>
          </div>
        )}

        {/* Success Alert */}
        {success && (
          <div style={{
            padding: '12px 14px',
            background: 'rgba(0, 200, 83, 0.12)',
            border: '1px solid rgba(0, 200, 83, 0.3)',
            borderRadius: '10px',
            color: '#00C853',
            fontSize: '13px',
            marginBottom: '18px',
            fontWeight: 600,
            display: 'flex',
            alignItems: 'center',
            gap: '8px'
          }}>
            <span>✅</span>
            <span>{success}</span>
          </div>
        )}

        {/* MODE: SIGN IN */}
        {mode === 'signin' && (
          <form onSubmit={handleSignIn} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: isDark ? '#CBD5E1' : '#334155', marginBottom: '6px' }}>
                Email Address
              </label>
              <input
                type="email"
                placeholder="customer@paynora.com"
                value={loginEmail}
                onChange={(e) => setLoginEmail(e.target.value)}
                autoComplete="email"
                style={{
                  width: '100%',
                  padding: '12px 14px',
                  background: isDark ? '#070D1C' : '#F8FAFC',
                  border: `1.5px solid ${isDark ? '#1C2B4E' : '#CBD5E1'}`,
                  borderRadius: '10px',
                  color: isDark ? '#FFF' : '#0F172A',
                  fontSize: '15px',
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
                <button
                  type="button"
                  onClick={() => setShowForgotModal(true)}
                  style={{
                    background: 'none',
                    border: 'none',
                    padding: 0,
                    fontSize: '12px',
                    fontWeight: 600,
                    color: '#00C853',
                    cursor: 'pointer'
                  }}
                >
                  Forgot password?
                </button>
              </div>
              <div style={{ position: 'relative' }}>
                <input
                  type={showLoginPassword ? 'text' : 'password'}
                  placeholder="••••••••••••"
                  value={loginPassword}
                  onChange={(e) => setLoginPassword(e.target.value)}
                  autoComplete="current-password"
                  style={{
                    width: '100%',
                    padding: '12px 42px 12px 14px',
                    background: isDark ? '#070D1C' : '#F8FAFC',
                    border: `1.5px solid ${isDark ? '#1C2B4E' : '#CBD5E1'}`,
                    borderRadius: '10px',
                    color: isDark ? '#FFF' : '#0F172A',
                    fontSize: '15px',
                    outline: 'none',
                    boxSizing: 'border-box'
                  }}
                />
                <button
                  type="button"
                  onClick={() => setShowLoginPassword(!showLoginPassword)}
                  style={{
                    position: 'absolute',
                    right: '12px',
                    top: '50%',
                    transform: 'translateY(-50%)',
                    background: 'none',
                    border: 'none',
                    cursor: 'pointer',
                    fontSize: '15px',
                    color: '#94A3B8'
                  }}
                >
                  {showLoginPassword ? '🙈' : '👁️'}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              style={{
                width: '100%',
                padding: '14px',
                background: '#00C853',
                color: '#FFFFFF',
                border: 'none',
                borderRadius: '12px',
                fontSize: '15px',
                fontWeight: 700,
                cursor: loading ? 'not-allowed' : 'pointer',
                marginTop: '4px',
                boxShadow: '0 4px 14px rgba(0, 200, 83, 0.3)'
              }}
            >
              {loading ? 'Authenticating...' : 'Sign In to Account →'}
            </button>

            <div style={{ margin: '14px 0', textAlign: 'center', position: 'relative' }}>
              <div style={{ borderTop: `1px solid ${isDark ? '#1E293B' : '#E2E8F0'}` }}></div>
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
              onClick={handleDemoSignIn}
              style={{
                width: '100%',
                padding: '12px',
                background: isDark ? 'rgba(255,255,255,0.06)' : '#F1F5F9',
                color: isDark ? '#FFF' : '#0F172A',
                border: `1px solid ${isDark ? '#1E293B' : '#E2E8F0'}`,
                borderRadius: '10px',
                fontSize: '13px',
                fontWeight: 600,
                cursor: 'pointer',
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '8px'
              }}
            >
              <span>⚡</span>
              <span>Quick Demo Sign-In (Pre-filled)</span>
            </button>
          </form>
        )}

        {/* MODE: CREATE ACCOUNT (SIGN UP) */}
        {mode === 'signup' && (
          <form onSubmit={handleSignUp} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            {/* First & Last Name */}
            <div style={{ display: 'flex', gap: '10px' }}>
              <div style={{ flex: 1 }}>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: isDark ? '#CBD5E1' : '#334155', marginBottom: '6px' }}>
                  First Name
                </label>
                <input
                  type="text"
                  placeholder="e.g. Eric"
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '11px 12px',
                    background: isDark ? '#070D1C' : '#F8FAFC',
                    border: `1.5px solid ${isDark ? '#1C2B4E' : '#CBD5E1'}`,
                    borderRadius: '10px',
                    color: isDark ? '#FFF' : '#0F172A',
                    fontSize: '14px',
                    outline: 'none',
                    boxSizing: 'border-box'
                  }}
                />
              </div>
              <div style={{ flex: 1 }}>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: isDark ? '#CBD5E1' : '#334155', marginBottom: '6px' }}>
                  Last Name
                </label>
                <input
                  type="text"
                  placeholder="e.g. Adams"
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '11px 12px',
                    background: isDark ? '#070D1C' : '#F8FAFC',
                    border: `1.5px solid ${isDark ? '#1C2B4E' : '#CBD5E1'}`,
                    borderRadius: '10px',
                    color: isDark ? '#FFF' : '#0F172A',
                    fontSize: '14px',
                    outline: 'none',
                    boxSizing: 'border-box'
                  }}
                />
              </div>
            </div>

            {/* Country Dropdown */}
            <div>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: isDark ? '#CBD5E1' : '#334155', marginBottom: '6px' }}>
                Country of Residence & Primary Wallet
              </label>
              <select
                value={countryCode}
                onChange={(e) => setCountryCode(e.target.value)}
                style={{
                  width: '100%',
                  padding: '11px 12px',
                  background: isDark ? '#070D1C' : '#F8FAFC',
                  border: `1.5px solid ${isDark ? '#1C2B4E' : '#CBD5E1'}`,
                  borderRadius: '10px',
                  color: isDark ? '#FFF' : '#0F172A',
                  fontSize: '14px',
                  outline: 'none',
                  cursor: 'pointer',
                  boxSizing: 'border-box'
                }}
              >
                {COUNTRIES.map((c) => (
                  <option key={c.code} value={c.code} style={{ background: isDark ? '#0D1A30' : '#FFF', color: isDark ? '#FFF' : '#000' }}>
                    {c.flag} {c.name} ({c.curr})
                  </option>
                ))}
              </select>
            </div>

            {/* Phone Number with Dial Code */}
            <div>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: isDark ? '#CBD5E1' : '#334155', marginBottom: '6px' }}>
                Phone Number
              </label>
              <div style={{ display: 'flex', gap: '8px' }}>
                <span style={{
                  padding: '11px 12px',
                  background: isDark ? '#162444' : '#E2E8F0',
                  borderRadius: '10px',
                  fontSize: '14px',
                  fontWeight: 700,
                  color: isDark ? '#FFF' : '#0D253F',
                  display: 'flex',
                  alignItems: 'center'
                }}>
                  {selectedCountry.dial}
                </span>
                <input
                  type="tel"
                  placeholder="8012345678"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  style={{
                    flex: 1,
                    padding: '11px 12px',
                    background: isDark ? '#070D1C' : '#F8FAFC',
                    border: `1.5px solid ${isDark ? '#1C2B4E' : '#CBD5E1'}`,
                    borderRadius: '10px',
                    color: isDark ? '#FFF' : '#0F172A',
                    fontSize: '14px',
                    outline: 'none',
                    boxSizing: 'border-box'
                  }}
                />
              </div>
            </div>

            {/* Email */}
            <div>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: isDark ? '#CBD5E1' : '#334155', marginBottom: '6px' }}>
                Email Address
              </label>
              <input
                type="email"
                placeholder="you@example.com"
                value={signUpEmail}
                onChange={(e) => setSignUpEmail(e.target.value)}
                autoComplete="email"
                style={{
                  width: '100%',
                  padding: '11px 12px',
                  background: isDark ? '#070D1C' : '#F8FAFC',
                  border: `1.5px solid ${isDark ? '#1C2B4E' : '#CBD5E1'}`,
                  borderRadius: '10px',
                  color: isDark ? '#FFF' : '#0F172A',
                  fontSize: '14px',
                  outline: 'none',
                  boxSizing: 'border-box'
                }}
              />
            </div>

            {/* Password */}
            <div>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: isDark ? '#CBD5E1' : '#334155', marginBottom: '6px' }}>
                Create Password
              </label>
              <div style={{ position: 'relative' }}>
                <input
                  type={showSignUpPassword ? 'text' : 'password'}
                  placeholder="Minimum 8 characters"
                  value={signUpPassword}
                  onChange={(e) => setSignUpPassword(e.target.value)}
                  autoComplete="new-password"
                  style={{
                    width: '100%',
                    padding: '11px 40px 11px 12px',
                    background: isDark ? '#070D1C' : '#F8FAFC',
                    border: `1.5px solid ${isDark ? '#1C2B4E' : '#CBD5E1'}`,
                    borderRadius: '10px',
                    color: isDark ? '#FFF' : '#0F172A',
                    fontSize: '14px',
                    outline: 'none',
                    boxSizing: 'border-box'
                  }}
                />
                <button
                  type="button"
                  onClick={() => setShowSignUpPassword(!showSignUpPassword)}
                  style={{
                    position: 'absolute',
                    right: '12px',
                    top: '50%',
                    transform: 'translateY(-50%)',
                    background: 'none',
                    border: 'none',
                    cursor: 'pointer',
                    fontSize: '15px',
                    color: '#94A3B8'
                  }}
                >
                  {showSignUpPassword ? '🙈' : '👁️'}
                </button>
              </div>
            </div>

            {/* Double Currency Wallet Notice */}
            <div style={{
              padding: '10px 12px',
              background: 'rgba(0, 200, 83, 0.08)',
              border: '1px solid rgba(0, 200, 83, 0.25)',
              borderRadius: '10px',
              fontSize: '12px',
              color: isDark ? '#E2E8F0' : '#1E293B',
              display: 'flex',
              alignItems: 'center',
              gap: '8px'
            }}>
              <span style={{ fontSize: '16px' }}>👛</span>
              <span>
                Your account will be provisioned with strictly <strong>two wallets</strong>: {selectedCountry.curr} (Local) + USD (Global Reserve).
              </span>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={loading}
              style={{
                width: '100%',
                padding: '14px',
                background: '#00C853',
                color: '#FFFFFF',
                border: 'none',
                borderRadius: '12px',
                fontSize: '15px',
                fontWeight: 700,
                cursor: loading ? 'not-allowed' : 'pointer',
                marginTop: '4px',
                boxShadow: '0 4px 14px rgba(0, 200, 83, 0.3)'
              }}
            >
              {loading ? 'Creating Account...' : 'Create PayNora Account →'}
            </button>
          </form>
        )}
      </div>

      {/* Forgot Password Modal */}
      {showForgotModal && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(0,0,0,0.6)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '20px',
          zIndex: 1000
        }}>
          <div style={{
            background: isDark ? '#0D1A30' : '#FFFFFF',
            borderRadius: '20px',
            padding: '28px',
            maxWidth: '400px',
            width: '100%',
            border: `1px solid ${isDark ? '#1C2B4E' : '#E2E8F0'}`
          }}>
            <h3 style={{ margin: '0 0 8px', fontSize: '18px', fontWeight: 800, color: isDark ? '#FFF' : '#0D253F' }}>
              Reset Your Password
            </h3>
            <p style={{ margin: '0 0 18px', fontSize: '13px', color: isDark ? '#94A3B8' : '#64748B' }}>
              Enter your registered email address to receive password reset security instructions.
            </p>

            {forgotSent ? (
              <div style={{ padding: '12px', background: 'rgba(0,200,83,0.12)', border: '1px solid #00C853', color: '#00C853', borderRadius: '10px', fontSize: '13px', fontWeight: 600, marginBottom: '16px' }}>
                Instructions sent! Please check your inbox.
              </div>
            ) : (
              <input
                type="email"
                placeholder="your-email@example.com"
                value={forgotEmail}
                onChange={(e) => setForgotEmail(e.target.value)}
                style={{
                  width: '100%',
                  padding: '11px 12px',
                  background: isDark ? '#070D1C' : '#F8FAFC',
                  border: `1.5px solid ${isDark ? '#1C2B4E' : '#CBD5E1'}`,
                  borderRadius: '10px',
                  color: isDark ? '#FFF' : '#0F172A',
                  fontSize: '14px',
                  outline: 'none',
                  boxSizing: 'border-box',
                  marginBottom: '16px'
                }}
              />
            )}

            <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end' }}>
              <button
                type="button"
                onClick={() => { setShowForgotModal(false); setForgotSent(false); }}
                style={{
                  padding: '9px 16px',
                  background: isDark ? '#1C2B4E' : '#F1F5F9',
                  color: isDark ? '#FFF' : '#334155',
                  border: 'none',
                  borderRadius: '8px',
                  fontSize: '13px',
                  fontWeight: 600,
                  cursor: 'pointer'
                }}
              >
                Close
              </button>
              {!forgotSent && (
                <button
                  type="button"
                  onClick={() => setForgotSent(true)}
                  style={{
                    padding: '9px 16px',
                    background: '#00C853',
                    color: '#FFF',
                    border: 'none',
                    borderRadius: '8px',
                    fontSize: '13px',
                    fontWeight: 700,
                    cursor: 'pointer'
                  }}
                >
                  Send Instructions
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
