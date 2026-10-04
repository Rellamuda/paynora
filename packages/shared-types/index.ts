export type CountryISO = 'NG' | 'GB' | 'US' | 'CA' | 'AE' | 'GH' | 'ZA' | 'DE' | 'FR' | 'SA' | 'CN';
export type ISO4217Currency = 'NGN' | 'GBP' | 'USD' | 'CAD' | 'AED' | 'GHS' | 'ZAR' | 'EUR' | 'SAR' | 'CNY';

export type RecipientCurrencyMode = 'FIXED' | 'CHOICE';

export type KYCStatus =
  | 'NOT_STARTED'
  | 'PROFILE_INCOMPLETE'
  | 'READY_FOR_VERIFICATION'
  | 'VERIFICATION_STARTED'
  | 'DOCUMENT_REQUIRED'
  | 'DOCUMENT_SUBMITTED'
  | 'LIVENESS_REQUIRED'
  | 'SCREENING_IN_PROGRESS'
  | 'PENDING_REVIEW'
  | 'APPROVED'
  | 'REJECTED'
  | 'MORE_INFORMATION_REQUIRED'
  | 'RETRY_REQUIRED';

export type TransferState =
  | 'DRAFT'
  | 'AWAITING_CONFIRMATION'
  | 'AWAITING_COMPLIANCE'
  | 'AWAITING_FUNDING'
  | 'PROCESSING'
  | 'PAYMENT_INITIATED'
  | 'FX_PENDING'
  | 'SETTLEMENT_PENDING'
  | 'AWAITING_RECIPIENT'
  | 'RECIPIENT_CURRENCY_SELECTED'
  | 'PAYOUT_PROCESSING'
  | 'COMPLETED'
  | 'FAILED'
  | 'CANCELLED'
  | 'REFUNDED';

export interface CountryConfig {
  isoCode: CountryISO;
  name: string;
  primaryCurrency: ISO4217Currency;
  supportedCurrencies: ISO4217Currency[];
  isSendingSupported: boolean;
  isReceivingSupported: boolean;
  isActive: boolean;
}

export interface Wallet {
  id: string;
  userId: string;
  currency: ISO4217Currency;
  availableBalance: string; // Fixed precision Decimal string
  pendingBalance: string;
  createdAt: string;
}

export interface TransferIntent {
  transferId: string;
  sourceCurrency: ISO4217Currency;
  sourceAmount: string;
  recipientCurrencyMode: RecipientCurrencyMode;
  destinationCurrency?: ISO4217Currency;
  destinationAmount?: string;
  fxQuoteId?: string;
  sourceCountry: CountryISO;
  destinationCountry: CountryISO;
  fee: string;
  state: TransferState;
  recipientName: string;
  createdAt: string;
}
