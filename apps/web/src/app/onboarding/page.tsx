'use client';

import React, { useState } from 'react';

export default function OnboardingPage() {
  const [stepIndex, setStepIndex] = useState(0);
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const [currentInput, setCurrentInput] = useState('');

  const questions = [
    { id: 'first_name', question: "What's your first name?", placeholder: "Rella" },
    { id: 'last_name', question: "What's your last name?", placeholder: "Muda" },
    { id: 'country', question: "Where do you live?", placeholder: "Nigeria 🇳🇬" },
    { id: 'id_type', question: "What ID document would you like to use?", placeholder: "Passport or National ID" }
  ];

  const currentQ = questions[stepIndex];

  const handleNext = () => {
    if (!currentInput.trim()) return;
    setAnswers({ ...answers, [currentQ.id]: currentInput });
    setCurrentInput('');
    if (stepIndex < questions.length - 1) {
      setStepIndex(stepIndex + 1);
    }
  };

  return (
    <div style={{ maxWidth: '600px', margin: '80px auto', padding: '0 20px', fontFamily: 'Inter, sans-serif' }}>
      <div style={{ background: '#E2E8F0', height: '6px', borderRadius: '3px', marginBottom: '40px', overflow: 'hidden' }}>
        <div style={{ background: '#00C853', height: '100%', width: `${((stepIndex + 1) / questions.length) * 100}%`, transition: 'width 0.3s ease' }} />
      </div>

      <div style={{ background: '#FFFFFF', padding: '40px', borderRadius: '16px', boxShadow: '0 10px 30px rgba(0,0,0,0.05)' }}>
        {stepIndex < questions.length ? (
          <div>
            <span style={{ fontSize: '14px', color: '#64748B', fontWeight: '600' }}>QUESTION {stepIndex + 1} OF {questions.length}</span>
            <h2 style={{ fontSize: '28px', color: '#0D253F', marginTop: '10px', marginBottom: '24px' }}>{currentQ.question}</h2>
            
            <input
              type="text"
              value={currentInput}
              onChange={(e) => setCurrentInput(e.target.value)}
              placeholder={currentQ.placeholder}
              style={{ width: '100%', padding: '16px', fontSize: '18px', borderRadius: '8px', border: '1px solid #CBD5E1', marginBottom: '24px', boxSizing: 'border-box' }}
              onKeyDown={(e) => e.key === 'Enter' && handleNext()}
            />

            <button
              onClick={handleNext}
              style={{ width: '100%', padding: '16px', background: '#0D253F', color: '#FFF', fontSize: '16px', fontWeight: 'bold', borderRadius: '8px', border: 'none', cursor: 'pointer' }}
            >
              Continue →
            </button>
          </div>
        ) : (
          <div style={{ textAlign: 'center' }}>
            <h2 style={{ color: '#00C853', fontSize: '28px' }}>🎉 Onboarding Profile Complete!</h2>
            <p style={{ color: '#475569' }}>Your details have been securely saved and submitted for identity verification.</p>
            <a href="/dashboard" style={{ display: 'inline-block', marginTop: '20px', padding: '14px 28px', background: '#0D253F', color: '#FFF', textDecoration: 'none', borderRadius: '8px', fontWeight: 'bold' }}>
              Go to Dashboard
            </a>
          </div>
        )}
      </div>
    </div>
  );
}
