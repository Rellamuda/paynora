'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { chatAI } from '../../../lib/api-client';

export default function AIPage() {
  const router = useRouter();
  const [prompt, setPrompt] = useState('');
  const [loading, setLoading] = useState(false);
  const [messages, setMessages] = useState<Array<{ sender: 'user' | 'ai'; text: string; action?: any }>>([
    {
      sender: 'ai',
      text: "Hello! I am PayNora's AI Financial Intelligence Assistant. I can help you check real-time FX rates, draft cross-border transfers, check your wallet balances, or guide your currency strategy."
    }
  ]);

  const handleSend = async (textToSend?: string) => {
    const query = textToSend || prompt;
    if (!query.trim()) return;

    const token = localStorage.getItem('paynora_token') || '';
    setMessages(prev => [...prev, { sender: 'user', text: query.trim() }]);
    if (!textToSend) setPrompt('');
    setLoading(true);

    try {
      const res = await chatAI(query.trim(), token);
      setMessages(prev => [
        ...prev,
        {
          sender: 'ai',
          text: res.message,
          action: res.proposed_action
        }
      ]);
    } catch (e: any) {
      setMessages(prev => [
        ...prev,
        {
          sender: 'ai',
          text: "I couldn't reach the AI execution engine at the moment. Please ensure the backend is online."
        }
      ]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: '900px', margin: '0 auto', display: 'flex', flexDirection: 'column', height: 'calc(100vh - 160px)' }}>
      <div style={{ marginBottom: '24px' }}>
        <h1 style={{ fontSize: '32px', fontWeight: 800, color: '#0D253F', margin: '0 0 6px 0' }}>✨ PayNora AI Financial Assistant</h1>
        <p style={{ color: '#64748B', fontSize: '15px', margin: 0 }}>Natural language financial operations, corridor analytics, and intent-driven payments.</p>
      </div>

      {/* Suggested Prompts */}
      <div style={{ display: 'flex', gap: '10px', marginBottom: '20px', flexWrap: 'wrap' }}>
        {[
          "Send ₦1,000,000 to John in London",
          "What is the current NGN to GBP rate?",
          "Check my active wallet balances",
          "What countries are supported for instant transfers?"
        ].map((s, i) => (
          <button
            key={i}
            onClick={() => handleSend(s)}
            style={{ padding: '8px 14px', background: '#EDE9FE', color: '#6C5CE7', border: 'none', borderRadius: '20px', fontSize: '13px', fontWeight: 600, cursor: 'pointer' }}
          >
            {s}
          </button>
        ))}
      </div>

      {/* Chat Window */}
      <div style={{ flex: 1, background: '#FFF', borderRadius: '20px', border: '1px solid #E2E8F0', padding: '24px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '16px', boxShadow: '0 4px 20px rgba(0,0,0,0.02)' }}>
        {messages.map((m, idx) => (
          <div key={idx} style={{ alignSelf: m.sender === 'user' ? 'flex-end' : 'flex-start', maxWidth: '80%' }}>
            <div style={{
              padding: '14px 18px',
              borderRadius: '16px',
              fontSize: '15px',
              lineHeight: 1.5,
              background: m.sender === 'user' ? '#0D253F' : '#F8FAFC',
              color: m.sender === 'user' ? '#FFF' : '#0F172A',
              border: m.sender === 'user' ? 'none' : '1px solid #E2E8F0'
            }}>
              {m.text}
            </div>

            {m.action && (
              <div style={{ marginTop: '10px', padding: '16px', background: '#E8F5E9', borderRadius: '12px', border: '1.5px solid #81C784' }}>
                <div style={{ fontSize: '12px', fontWeight: 800, color: '#1B5E20', letterSpacing: '0.5px' }}>STRUCTURED PAYMENT PROPOSAL</div>
                <div style={{ fontSize: '16px', fontWeight: 700, color: '#2E7D32', margin: '6px 0' }}>
                  Send {m.action.source_amount} {m.action.source_currency} ➔ {m.action.recipient_name}
                </div>
                <p style={{ margin: '0 0 12px 0', fontSize: '13px', color: '#388E3C' }}>Requires explicit authorization from customer to trigger ledger entries.</p>
                <button
                  onClick={() => router.push('/dashboard/send')}
                  style={{ padding: '8px 16px', background: '#00C853', color: '#FFF', border: 'none', borderRadius: '8px', fontSize: '13px', fontWeight: 700, cursor: 'pointer' }}
                >
                  Confirm & Dispatch in Send Hub →
                </button>
              </div>
            )}
          </div>
        ))}
        {loading && (
          <div style={{ alignSelf: 'flex-start', color: '#94A3B8', fontSize: '14px' }}>PayNora AI is analyzing intent...</div>
        )}
      </div>

      {/* Input Bar */}
      <div style={{ display: 'flex', gap: '12px', marginTop: '16px' }}>
        <input
          type="text"
          placeholder="Ask PayNora AI anything about your money, transfers, or rates..."
          value={prompt}
          onChange={e => setPrompt(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && handleSend()}
          style={{ flex: 1, padding: '16px 20px', fontSize: '15px', border: '1.5px solid #CBD5E1', borderRadius: '12px', outline: 'none' }}
        />
        <button
          onClick={() => handleSend()}
          disabled={loading}
          style={{ padding: '16px 28px', background: '#0D253F', color: '#FFF', border: 'none', borderRadius: '12px', fontWeight: 700, fontSize: '15px', cursor: 'pointer' }}
        >
          Send
        </button>
      </div>
    </div>
  );
}
