'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { registerUser, verifyKYC, loginUser } from '../../lib/api-client';

const ACTIVE_COUNTRIES = [
  { code: 'NG', name: 'Nigeria', flag: '🇳🇬', currency: 'NGN', dial: '+234' },
  { code: 'GB', name: 'United Kingdom', flag: '🇬🇧', currency: 'GBP', dial: '+44' },
  { code: 'US', name: 'United States', flag: '🇺🇸', currency: 'USD', dial: '+1' },
  { code: 'CA', name: 'Canada', flag: '🇨🇦', currency: 'CAD', dial: '+1' },
  { code: 'AE', name: 'United Arab Emirates', flag: '🇦🇪', currency: 'AED', dial: '+971' },
  { code: 'GH', name: 'Ghana', flag: '🇬🇭', currency: 'GHS', dial: '+233' },
  { code: 'ZA', name: 'South Africa', flag: '🇿🇦', currency: 'ZAR', dial: '+27' },
  { code: 'DE', name: 'Germany', flag: '🇩🇪', currency: 'EUR', dial: '+49' },
  { code: 'FR', name: 'France', flag: '🇫🇷', currency: 'EUR', dial: '+33' },
  { code: 'SA', name: 'Saudi Arabia', flag: '🇸🇦', currency: 'SAR', dial: '+966' },
  { code: 'CN', name: 'China', flag: '🇨🇳', currency: 'CNY', dial: '+86' }
];

export default function OnboardingPage() {
  const router = useRouter();
  const [step, setStep] = useState(1);
  const totalSteps = 5;

  // Form State
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [country, setCountry] = useState('NG');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [docType, setDocType] = useState('NATIONAL_ID');
  const [docNumber, setDocNumber] = useState('');

  // Status & UI
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');

  const selectedCountryObj = ACTIVE_COUNTRIES.find(c => c.code === country) || ACTIVE_COUNTRIES[0];

  const handleNextStep = () => {
    setError('');
    if (step === 1) {
      if (!firstName.trim() || !lastName.trim()) {
        setError('Please provide both first and last name.');
        return;
      }
      setStep(2);
    } else if (step === 2) {
      if (!country) {
        setError('Please select your country of residence.');
        return;
      }
      setStep(3);
    } else if (step === 3) {
      if (!email.trim() || !phone.trim()) {
        setError('Please provide a valid email and phone number.');
        return;
      }
      if (!email.includes('@')) {
        setError('Please enter a valid email address.');
        return;
      }
      setStep(4);
    } else if (step === 4) {
      if (!password || password.length < 8) {
        setError('Password must be at least 8 characters long.');
        return;
      }
      setStep(5);
    }
  };

  const handleCompleteRegistration = async () => {
    setError('');
    if (!docNumber.trim()) {
      setError('Please enter your document ID number.');
      return;
    }

    setLoading(true);
    try {
      // 1. Register user
      const fullPhone = `${selectedCountryObj.dial}${phone.replace(/^0+/, '')}`;
      await registerUser({
        first_name: firstName.trim(),
        last_name: lastName.trim(),
        email: email.trim().toLowerCase(),
        phone: fullPhone,
        country_iso: country,
        password: password
      });

      // 2. Automatically log in to get access token
      const loginRes = await loginUser({
        email: email.trim().toLowerCase(),
        password: password
      });

      const token = loginRes.access_token;
      localStorage.setItem('paynora_token', token);
      localStorage.setItem('paynora_user_email', loginRes.email);

      // 3. Perform automated KYC Document Verification
      await verifyKYC({
        document_type: docType,
        document_number: docNumber.trim()
      }, token);

      setSuccessMessage('Account verified & created successfully! Redirecting to your dashboard...');
      setTimeout(() => {
        router.push('/dashboard');
      }, 1500);
    } catch (err: any) {
      setError(err.message || 'An error occurred during onboarding.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ minHeight: '100vh', background: '#F8FAFC', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '24px' }}>
      {/* Brand Header */}
      <div style={{ marginBottom: '32px', textAlign: 'center' }}>
        <a href="/" style={{ textDecoration: 'none' }}>
          <span style={{ fontSize: '32px', fontWeight: 800, color: '#0D253F', letterSpacing: '-0.5px' }}>PayNora</span>
          <span style={{ marginLeft: '10px', fontSize: '13px', fontWeight: 700, color: '#00C853', background: '#E8F5E9', padding: '4px 10px', borderRadius: '12px' }}>GLOBAL FINTECH</span>
        </a>
      </div>

      {/* Card Container */}
      <div style={{ width: '100%', maxWidth: '540px', background: '#FFFFFF', borderRadius: '20px', padding: '40px', boxShadow: '0 8px 30px rgba(0,0,0,0.06)', border: '1px solid #E2E8F0' }}>
        {/* Progress Bar */}
        <div style={{ marginBottom: '32px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', fontWeight: 600, color: '#64748B', marginBottom: '8px' }}>
            <span>STEP {step} OF {totalSteps}</span>
            <span>{Math.round((step / totalSteps) * 100)}% COMPLETED</span>
          </div>
          <div style={{ height: '6px', width: '100%', background: '#E2E8F0', borderRadius: '999px', overflow: 'hidden' }}>
            <div style={{ height: '100%', width: `${(step / totalSteps) * 100}%`, background: '#00C853', transition: 'width 0.4s ease' }} />
          </div>
        </div>

        {error && (
          <div style={{ padding: '14px 18px', background: '#FEE2E2', border: '1px solid #FCA5A5', color: '#B91C1C', borderRadius: '10px', fontSize: '14px', marginBottom: '24px', fontWeight: 500 }}>
            {error}
          </div>
        )}

        {successMessage && (
          <div style={{ padding: '14px 18px', background: '#DCFCE7', border: '1px solid #86EFAC', color: '#15803D', borderRadius: '10px', fontSize: '14px', marginBottom: '24px', fontWeight: 600 }}>
            {successMessage}
          </div>
        )}

        {/* STEP 1: Name */}
        {step === 1 && (
          <div>
            <h2 style={{ fontSize: '26px', fontWeight: 800, color: '#0D253F', marginBottom: '8px' }}>What's your name?</h2>
            <p style={{ color: '#64748B', fontSize: '15px', marginBottom: '28px' }}>Please provide your legal name as it appears on official government identity documents.</p>

            <div style={{ marginBottom: '18px' }}>
              <label style={{ display: 'block', fontSize: '14px', fontWeight: 600, color: '#334155', marginBottom: '8px' }}>First Name</label>
              <input
                type="text"
                placeholder="e.g. John"
                value={firstName}
                onChange={e => setFirstName(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && handleNextStep()}
                style={{ width: '100%', padding: '14px 16px', fontSize: '16px', border: '1.5px solid #CBD5E1', borderRadius: '10px', outline: 'none', boxSizing: 'border-box' }}
                autoFocus
              />
            </div>

            <div style={{ marginBottom: '32px' }}>
              <label style={{ display: 'block', fontSize: '14px', fontWeight: 600, color: '#334155', marginBottom: '8px' }}>Last Name</label>
              <input
                type="text"
                placeholder="e.g. Doe"
                value={lastName}
                onChange={e => setLastName(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && handleNextStep()}
                style={{ width: '100%', padding: '14px 16px', fontSize: '16px', border: '1.5px solid #CBD5E1', borderRadius: '10px', outline: 'none', boxSizing: 'border-box' }}
              />
            </div>

            <button
              onClick={handleNextStep}
              style={{ width: '100%', padding: '15px', background: '#0D253F', color: '#FFF', fontSize: '16px', fontWeight: 700, borderRadius: '10px', border: 'none', cursor: 'pointer' }}
            >
              Continue →
            </button>
          </div>
        )}

        {/* STEP 2: Country Selection */}
        {step === 2 && (
          <div>
            <h2 style={{ fontSize: '26px', fontWeight: 800, color: '#0D253F', marginBottom: '8px' }}>Where do you live?</h2>
            <p style={{ color: '#64748B', fontSize: '15px', marginBottom: '28px' }}>Select your country of residence among our 11 active launch corridors.</p>

            <div style={{ marginBottom: '32px' }}>
              <label style={{ display: 'block', fontSize: '14px', fontWeight: 600, color: '#334155', marginBottom: '8px' }}>Country of Residence</label>
              <select
                value={country}
                onChange={e => setCountry(e.target.value)}
                style={{ width: '100%', padding: '14px 16px', fontSize: '16px', border: '1.5px solid #CBD5E1', borderRadius: '10px', outline: 'none', background: '#FFF', boxSizing: 'border-box' }}
              >
                {ACTIVE_COUNTRIES.map(c => (
                  <option key={c.code} value={c.code}>
                    {c.flag} {c.name} ({c.currency})
                  </option>
                ))}
              </select>
            </div>

            <div style={{ display: 'flex', gap: '14px' }}>
              <button
                onClick={() => setStep(1)}
                style={{ flex: 1, padding: '15px', background: '#F1F5F9', color: '#334155', fontSize: '15px', fontWeight: 600, borderRadius: '10px', border: 'none', cursor: 'pointer' }}
              >
                Back
              </button>
              <button
                onClick={handleNextStep}
                style={{ flex: 2, padding: '15px', background: '#0D253F', color: '#FFF', fontSize: '16px', fontWeight: 700, borderRadius: '10px', border: 'none', cursor: 'pointer' }}
              >
                Continue →
              </button>
            </div>
          </div>
        )}

        {/* STEP 3: Email and Phone */}
        {step === 3 && (
          <div>
            <h2 style={{ fontSize: '26px', fontWeight: 800, color: '#0D253F', marginBottom: '8px' }}>Contact information</h2>
            <p style={{ color: '#64748B', fontSize: '15px', marginBottom: '28px' }}>We'll send verification codes and real-time transaction updates here.</p>

            <div style={{ marginBottom: '18px' }}>
              <label style={{ display: 'block', fontSize: '14px', fontWeight: 600, color: '#334155', marginBottom: '8px' }}>Email Address</label>
              <input
                type="email"
                placeholder="e.g. name@example.com"
                value={email}
                onChange={e => setEmail(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && handleNextStep()}
                style={{ width: '100%', padding: '14px 16px', fontSize: '16px', border: '1.5px solid #CBD5E1', borderRadius: '10px', outline: 'none', boxSizing: 'border-box' }}
                autoFocus
              />
            </div>

            <div style={{ marginBottom: '32px' }}>
              <label style={{ display: 'block', fontSize: '14px', fontWeight: 600, color: '#334155', marginBottom: '8px' }}>Mobile Phone Number</label>
              <div style={{ display: 'flex', gap: '10px' }}>
                <div style={{ padding: '14px 16px', background: '#F1F5F9', border: '1.5px solid #CBD5E1', borderRadius: '10px', fontWeight: 600, color: '#334155' }}>
                  {selectedCountryObj.flag} {selectedCountryObj.dial}
                </div>
                <input
                  type="tel"
                  placeholder="8012345678"
                  value={phone}
                  onChange={e => setPhone(e.target.value)}
                  onKeyDown={e => e.key === 'Enter' && handleNextStep()}
                  style={{ flex: 1, padding: '14px 16px', fontSize: '16px', border: '1.5px solid #CBD5E1', borderRadius: '10px', outline: 'none', boxSizing: 'border-box' }}
                />
              </div>
            </div>

            <div style={{ display: 'flex', gap: '14px' }}>
              <button
                onClick={() => setStep(2)}
                style={{ flex: 1, padding: '15px', background: '#F1F5F9', color: '#334155', fontSize: '15px', fontWeight: 600, borderRadius: '10px', border: 'none', cursor: 'pointer' }}
              >
                Back
              </button>
              <button
                onClick={handleNextStep}
                style={{ flex: 2, padding: '15px', background: '#0D253F', color: '#FFF', fontSize: '16px', fontWeight: 700, borderRadius: '10px', border: 'none', cursor: 'pointer' }}
              >
                Continue →
              </button>
            </div>
          </div>
        )}

        {/* STEP 4: Password Security */}
        {step === 4 && (
          <div>
            <h2 style={{ fontSize: '26px', fontWeight: 800, color: '#0D253F', marginBottom: '8px' }}>Create a secure password</h2>
            <p style={{ color: '#64748B', fontSize: '15px', marginBottom: '28px' }}>Protect your PayNora multi-currency wallet with at least 8 characters.</p>

            <div style={{ marginBottom: '32px' }}>
              <label style={{ display: 'block', fontSize: '14px', fontWeight: 600, color: '#334155', marginBottom: '8px' }}>Password</label>
              <input
                type="password"
                placeholder="••••••••••••"
                value={password}
                onChange={e => setPassword(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && handleNextStep()}
                style={{ width: '100%', padding: '14px 16px', fontSize: '16px', border: '1.5px solid #CBD5E1', borderRadius: '10px', outline: 'none', boxSizing: 'border-box' }}
                autoFocus
              />
            </div>

            <div style={{ display: 'flex', gap: '14px' }}>
              <button
                onClick={() => setStep(3)}
                style={{ flex: 1, padding: '15px', background: '#F1F5F9', color: '#334155', fontSize: '15px', fontWeight: 600, borderRadius: '10px', border: 'none', cursor: 'pointer' }}
              >
                Back
              </button>
              <button
                onClick={handleNextStep}
                style={{ flex: 2, padding: '15px', background: '#0D253F', color: '#FFF', fontSize: '16px', fontWeight: 700, borderRadius: '10px', border: 'none', cursor: 'pointer' }}
              >
                Continue →
              </button>
            </div>
          </div>
        )}

        {/* STEP 5: Identity Document Verification */}
        {step === 5 && (
          <div>
            <h2 style={{ fontSize: '26px', fontWeight: 800, color: '#0D253F', marginBottom: '8px' }}>Verify your identity</h2>
            <p style={{ color: '#64748B', fontSize: '15px', marginBottom: '28px' }}>Global regulatory compliance requires verification to activate money movement.</p>

            <div style={{ marginBottom: '18px' }}>
              <label style={{ display: 'block', fontSize: '14px', fontWeight: 600, color: '#334155', marginBottom: '8px' }}>Document Type</label>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '10px' }}>
                {[
                  { id: 'NATIONAL_ID', label: 'National ID', icon: '🪪' },
                  { id: 'PASSPORT', label: 'Passport', icon: '🛂' },
                  { id: 'DRIVERS_LICENSE', label: 'Driver License', icon: '🚗' }
                ].map(d => (
                  <button
                    key={d.id}
                    type="button"
                    onClick={() => setDocType(d.id)}
                    style={{
                      padding: '16px 8px',
                      borderRadius: '12px',
                      border: docType === d.id ? '2px solid #00C853' : '1px solid #CBD5E1',
                      background: docType === d.id ? '#E8F5E9' : '#FFF',
                      cursor: 'pointer',
                      textAlign: 'center'
                    }}
                  >
                    <div style={{ fontSize: '24px', marginBottom: '4px' }}>{d.icon}</div>
                    <div style={{ fontSize: '12px', fontWeight: 700, color: '#0D253F' }}>{d.label}</div>
                  </button>
                ))}
              </div>
            </div>

            <div style={{ marginBottom: '32px' }}>
              <label style={{ display: 'block', fontSize: '14px', fontWeight: 600, color: '#334155', marginBottom: '8px' }}>ID Document Number</label>
              <input
                type="text"
                placeholder="e.g. A123456789"
                value={docNumber}
                onChange={e => setDocNumber(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && handleCompleteRegistration()}
                style={{ width: '100%', padding: '14px 16px', fontSize: '16px', border: '1.5px solid #CBD5E1', borderRadius: '10px', outline: 'none', boxSizing: 'border-box' }}
                autoFocus
              />
            </div>

            <div style={{ display: 'flex', gap: '14px' }}>
              <button
                onClick={() => setStep(4)}
                disabled={loading}
                style={{ flex: 1, padding: '15px', background: '#F1F5F9', color: '#334155', fontSize: '15px', fontWeight: 600, borderRadius: '10px', border: 'none', cursor: 'pointer' }}
              >
                Back
              </button>
              <button
                onClick={handleCompleteRegistration}
                disabled={loading}
                style={{ flex: 2, padding: '15px', background: '#00C853', color: '#FFF', fontSize: '16px', fontWeight: 700, borderRadius: '10px', border: 'none', cursor: 'pointer' }}
              >
                {loading ? 'Verifying & Activating...' : 'Complete Verification & Start'}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
