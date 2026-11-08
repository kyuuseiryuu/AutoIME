import React, { createContext, useContext, useState, useEffect } from 'react';

const ThemeContext = createContext();

export function ThemeProvider({ children }) {
  // 模式: 'system' | 'light' | 'dark'
  const [themeMode, setThemeModeState] = useState(() => {
    try {
      const saved = localStorage.getItem('autoime_theme');
      if (saved === 'light' || saved === 'dark' || saved === 'system') {
        return saved;
      }
    } catch {}
    return 'system';
  });

  const [systemIsDark, setSystemIsDark] = useState(() => {
    return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
  });

  // 监听系统深色模式实时改变
  useEffect(() => {
    if (!window.matchMedia) return;
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    const handler = (e) => setSystemIsDark(e.matches);

    if (mq.addEventListener) {
      mq.addEventListener('change', handler);
    } else {
      mq.addListener(handler);
    }

    return () => {
      if (mq.removeEventListener) {
        mq.removeEventListener('change', handler);
      } else {
        mq.removeListener(handler);
      }
    };
  }, []);

  // 计算当前实际生效的主题 ('light' | 'dark')
  const actualTheme = themeMode === 'system' ? (systemIsDark ? 'dark' : 'light') : themeMode;

  // 更新 DOM 属性以触发 CSS 变量切换
  useEffect(() => {
    const root = document.documentElement;
    root.setAttribute('data-theme', actualTheme);
    root.classList.toggle('dark', actualTheme === 'dark');
  }, [actualTheme]);

  // 修改主题模式
  const setThemeMode = (mode) => {
    setThemeModeState(mode);
    try {
      localStorage.setItem('autoime_theme', mode);
    } catch {}

    // 通知 AHK 宿主持久化保存至 INI 配置
    const ahk = window.chrome?.webview?.hostObjects?.sync?.ahk;
    if (ahk && typeof ahk.SetTheme === 'function') {
      try {
        ahk.SetTheme(mode);
      } catch (err) {
        console.warn('Failed to sync theme to AHK:', err);
      }
    }
  };

  return (
    <ThemeContext.Provider value={{ themeMode, actualTheme, setThemeMode, systemIsDark }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
}

