export function getApiBaseUrl(): string {
  if (typeof window !== 'undefined') {
    return `${window.location.protocol}//${window.location.hostname}:8000/api/v1`;
  }
  return process.env.NEXT_PUBLIC_API_URL || 'http://backend:8000/api/v1';
}

export async function checkHealth() {
  const url = `${getApiBaseUrl()}/health`;
  const res = await fetch(url, { cache: 'no-store' });
  if (!res.ok) throw new Error('Health check failed');
  return res.json();
}

export async function fetchActiveCountries() {
  const url = `${getApiBaseUrl()}/countries/active`;
  const res = await fetch(url, { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch active countries');
  return res.json();
}

export async function registerUser(payload: {
  first_name: string;
  last_name: string;
  email: string;
  phone: string;
  country_iso: string;
  password: string;
}) {
  const url = `${getApiBaseUrl()}/auth/register`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: 'Registration failed' }));
    throw new Error(err.detail || 'Registration failed');
  }
  return res.json();
}

export async function loginUser(payload: { email: string; password: string }) {
  const url = `${getApiBaseUrl()}/auth/login`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: 'Invalid credentials' }));
    throw new Error(err.detail || 'Invalid credentials');
  }
  return res.json();
}

export async function fetchUserProfile(token: string) {
  const url = `${getApiBaseUrl()}/users/me`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` }
  });
  if (!res.ok) throw new Error('Failed to fetch profile');
  return res.json();
}

export async function fetchWallets(token: string) {
  const url = `${getApiBaseUrl()}/wallets`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` }
  });
  if (!res.ok) throw new Error('Failed to fetch wallets');
  return res.json();
}

export async function activateWallet(currency: string, token: string) {
  const url = `${getApiBaseUrl()}/wallets`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`
    },
    body: JSON.stringify({ currency })
  });
  if (!res.ok) throw new Error('Failed to activate wallet');
  return res.json();
}

export async function fundWallet(currency: string, amount: string, token: string) {
  const url = `${getApiBaseUrl()}/wallets/fund`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`
    },
    body: JSON.stringify({ currency, amount })
  });
  if (!res.ok) throw new Error('Failed to deposit funds');
  return res.json();
}

export async function initializeDeposit(payload: {
  currency: string;
  amount: string;
  gateway?: string;
}, token: string) {
  const url = `${getApiBaseUrl()}/wallets/deposit/initialize`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`
    },
    body: JSON.stringify(payload)
  });
  if (!res.ok) throw new Error('Payment gateway initialization failed');
  return res.json();
}

export async function verifyDeposit(payload: {
  reference: string;
  gateway: string;
  currency: string;
}, token: string) {
  const url = `${getApiBaseUrl()}/wallets/deposit/verify`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`
    },
    body: JSON.stringify(payload)
  });
  if (!res.ok) throw new Error('Verification failed');
  return res.json();
}

export async function convertWallet(
  fromCurrency: string,
  toCurrency: string,
  fromAmount: string,
  toAmount: string,
  token: string
) {
  const url = `${getApiBaseUrl()}/wallets/convert`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`
    },
    body: JSON.stringify({
      from_currency: fromCurrency,
      to_currency: toCurrency,
      from_amount: fromAmount,
      to_amount: toAmount
    })
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: 'Currency conversion failed' }));
    throw new Error(err.detail || 'Currency conversion failed');
  }
  return res.json();
}

export async function fetchFXQuote(sourceCurrency: string, destCurrency: string, amount: string) {
  const url = `${getApiBaseUrl()}/fx/quote?source_currency=${encodeURIComponent(sourceCurrency)}&destination_currency=${encodeURIComponent(destCurrency)}&source_amount=${encodeURIComponent(amount)}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error('Failed to get FX quote');
  return res.json();
}

export async function fetchBeneficiaries(token: string) {
  const url = `${getApiBaseUrl()}/beneficiaries`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` }
  });
  if (!res.ok) throw new Error('Failed to fetch beneficiaries');
  return res.json();
}

export async function createBeneficiary(payload: any, token: string) {
  const url = `${getApiBaseUrl()}/beneficiaries`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`
    },
    body: JSON.stringify(payload)
  });
  if (!res.ok) throw new Error('Failed to add beneficiary');
  return res.json();
}

export async function fetchTransfers() {
  const url = `${getApiBaseUrl()}/transfers`;
  const res = await fetch(url, { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch transfers');
  return res.json();
}

export async function createTransfer(payload: any, idempotencyKey: string, token: string) {
  const url = `${getApiBaseUrl()}/transfers`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Idempotency-Key': idempotencyKey,
      Authorization: `Bearer ${token}`
    },
    body: JSON.stringify(payload)
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: 'Transfer failed' }));
    throw new Error(err.detail || 'Transfer failed');
  }
  return res.json();
}

export async function confirmTransfer(transferId: string) {
  const url = `${getApiBaseUrl()}/transfers/${transferId}/confirm`;
  const res = await fetch(url, { method: 'POST' });
  if (!res.ok) throw new Error('Failed to confirm transfer');
  return res.json();
}

export async function chatAI(prompt: string, token: string) {
  const url = `${getApiBaseUrl()}/ai/chat`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`
    },
    body: JSON.stringify({ prompt })
  });
  if (!res.ok) throw new Error('AI assistant request failed');
  return res.json();
}

export async function verifyKYC(payload: { document_type: string; document_number: string }, token: string) {
  const url = `${getApiBaseUrl()}/kyc/verify`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`
    },
    body: JSON.stringify(payload)
  });
  if (!res.ok) throw new Error('KYC verification failed');
  return res.json();
}

export async function getKYCStatus(token: string) {
  const url = `${getApiBaseUrl()}/kyc/status`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` }
  });
  if (!res.ok) throw new Error('Failed to get KYC status');
  return res.json();
}
