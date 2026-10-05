import React from 'react';
import { ThemeProvider } from '../lib/theme-context';

export const metadata = {
  title: 'PayNora — Global Money Movement & Multi-Currency Platform',
  description: 'Send, receive, and hold money seamlessly across 11 active countries and currencies.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body style={{ margin: 0, fontFamily: 'Inter, sans-serif' }}>
        <ThemeProvider>
          {children}
        </ThemeProvider>
      </body>
    </html>
  );
}
