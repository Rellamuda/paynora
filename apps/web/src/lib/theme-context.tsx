'use client';

import React, { createContext, useContext, useEffect, useState } from 'react';

type Theme = 'light' | 'dark';

interface ThemeContextType {
  theme: Theme;
  toggleTheme: () => void;
  isDark: boolean;
}

const ThemeContext = createContext<ThemeContextType>({
  theme: 'dark',
  toggleTheme: () => {},
  isDark: true,
});

export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [theme, setTheme] = useState<Theme>('dark');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    const saved = localStorage.getItem('paynora_theme') as Theme | null;
    if (saved === 'dark' || saved === 'light') {
      setTheme(saved);
      document.documentElement.setAttribute('data-theme', saved);
    } else {
      setTheme('dark');
      document.documentElement.setAttribute('data-theme', 'dark');
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
          --bg-sidebar: #050505;
          --border-color: #E2E8F0;
          --border-subtle: rgba(0, 0, 0, 0.06);
          --text-main: #0F172A;
          --text-muted: #64748B;
          --accent-blue: #00A3FF;
          --accent-blue-bg: rgba(0, 163, 255, 0.12);
          --accent-green: #00A3FF;
          --accent-green-bg: rgba(0, 163, 255, 0.12);
          --brand-navy: #00A3FF;
          --input-bg: #FFFFFF;
          --input-border: #CBD5E1;
        }

        [data-theme='dark'] {
          --bg-app: #000000;
          --bg-card: #0A0A0A;
          --bg-card-subtle: #141414;
          --bg-header: #050505;
          --bg-sidebar: #000000;
          --border-color: #222222;
          --border-subtle: rgba(255, 255, 255, 0.08);
          --text-main: #FFFFFF;
          --text-muted: #A3A3A3;
          --accent-blue: #00A3FF;
          --accent-blue-bg: rgba(0, 163, 255, 0.15);
          --accent-green: #00A3FF;
          --accent-green-bg: rgba(0, 163, 255, 0.15);
          --brand-navy: #00A3FF;
          --input-bg: #0A0A0A;
          --input-border: #262626;
        }

        body {
          background-color: var(--bg-app);
          color: var(--text-main);
          transition: background-color 0.2s ease, color 0.2s ease;
        }
      `}</style>
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = () => useContext(ThemeContext);
