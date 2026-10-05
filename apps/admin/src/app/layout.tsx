import React from 'react';

export const metadata = {
  title: 'PayNora Operations & Compliance Admin Portal',
  description: 'Internal operations, risk review, ledger reconciliation, and corridor management',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body style={{ margin: 0, padding: 0, fontFamily: 'Inter, sans-serif', background: '#F8FAFC' }}>
        {children}
      </body>
    </html>
  );
}
