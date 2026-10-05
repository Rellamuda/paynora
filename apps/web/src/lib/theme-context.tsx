'use client';

import React, { createContext, useContext, useEffect, useState } from 'react';

type Theme = 'light' | 'dark';

interface ThemeContextType {
  theme: Theme;
  toggleTheme: () => void;
  isDark: boolean;
}

const ThemeContext = createContext<ThemeContextType>({
  theme: 'light',
  toggleTheme: () => {},
  isDark: false,
});

export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [theme, setTheme] = useState<Theme>('light');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    const saved = localStorage.getItem('paynora_theme') as Theme | null;
    if (saved === 'dark' || saved === 'light') {
      setTheme(saved);
      document.documentElement.setAttribute('data-theme', saved);
    } else {
      // Default to dark or light based on system
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      const initial = prefersDark ? 'dark' : 'light';
      setTheme(initial);
      document.documentElement.setAttribute('data-theme', initial);
    }
    setMounted(true);
  }, []);

  const toggleTheme = () => {
    const next = theme === 'light' ? 'dark' : 'light';
    setTheme(next);
    localStorage.setItem('paynora_theme', next);
    document.documentElement.setAttribute('data-theme', next);
  };

  return (
    <ThemeContext.Provider value={{ theme, toggleTheme, isDark: theme === 'dark' }}>
      <style jsx global>{`
        :root {
          --bg-app: #F8FAFC;
          --bg-card: #FFFFFF;
          --bg-card-subtle: #F1F5F9;
          --bg-header: #FFFFFF;
          --bg-sidebar: #0D253F;
          --border-color: #E2E8F0;
          --border-subtle: rgba(0, 0, 0, 0.06);
          --text-main: #0F172A;
          --text-muted: #64748B;
          --accent-green: #00C853;
          --accent-green-bg: rgba(0, 200, 83, 0.12);
          --brand-navy: #0D253F;
          --input-bg: #FFFFFF;
          --input-border: #CBD5E1;
        }

        [data-theme='dark'] {
          --bg-app: #0B132B;
          --bg-card: #131E3A;
          --bg-card-subtle: #1C2B4E;
          --bg-header: #0F1A36;
          --bg-sidebar: #070D1C;
          --border-color: #223456;
          --border-subtle: rgba(255, 255, 255, 0.08);
          --text-main: #F8FAFC;
          --text-muted: #94A3B8;
          --accent-green: #00E676;
          --accent-green-bg: rgba(0, 230, 118, 0.15);
          --brand-navy: #1C2B4E;
          --input-bg: #0F1A36;
          --input-border: #223456;
        }

        body {
          background-color: var(--bg-app);
          color: var(--text-main);
          transition: background-color 0.25s ease, color 0.25s ease;
        }
      `}</style>
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = () => useContext(ThemeContext);
