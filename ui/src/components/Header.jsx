import React from 'react';
import { useApp } from '../context/AppContext';
import { useTheme } from '../context/ThemeContext';

export function Header() {
  const { currentHotkey, openHotkeyModal, currentLang, availableLangs, changeLanguage, currentVersion, currentCommit, checkUpdate, t } = useApp();
  const { themeMode, setThemeMode } = useTheme();

  // 解析快捷键字符串转换为按键数组
  const parseHotkey = (hk) => {
    const list = [];
    if (!hk) return ['None'];
    let remaining = hk;

    if (remaining.includes('#')) { list.push('Win'); remaining = remaining.replace('#', ''); }
    if (remaining.includes('^')) { list.push('Ctrl'); remaining = remaining.replace('^', ''); }
    if (remaining.includes('!')) { list.push('Alt'); remaining = remaining.replace('!', ''); }
    if (remaining.includes('+')) { list.push('Shift'); remaining = remaining.replace('+', ''); }

    if (remaining.trim()) {
      let key = remaining.trim().toUpperCase();
      if (key === 'ESCAPE') key = 'Esc';
      if (key === 'RETURN') key = 'Enter';
      list.push(key);
    }
    return list.length ? list : ['None'];
  };

  return (
    <header className="app-header">
      {/* 品牌 Logo 与标题 */}
      <div className="brand">
        <div className="brand-icon">
          <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
            <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon>
          </svg>
        </div>
        <div className="brand-text">
          <div className="brand-title-row">
            <h1 className="brand-title">AutoIME</h1>
            <button
              type="button"
              className="version-badge version-pill-btn"
              onClick={() => checkUpdate(true)}
              title={`当前版本: ${currentVersion} #${currentCommit} (点击检查在线更新)`}
            >
              <span>{currentVersion}</span>
              <span className="commit-tag">#{currentCommit}</span>
            </button>
          </div>
          <p className="brand-subtitle">{t('header_desc')}</p>
        </div>
      </div>

      {/* 头部右侧操作组 */}
      <div className="header-actions">
        {/* 主题模式切换 (浅色 / 深色 / 跟随系统) */}
        <div className="theme-segmented-group" title="切换界面外观主题">
          <button
            type="button"
            className={`theme-segmented-btn ${themeMode === 'light' ? 'active' : ''}`}
            onClick={() => setThemeMode('light')}
            title="浅色模式"
          >
            ☀️
          </button>
          <button
            type="button"
            className={`theme-segmented-btn ${themeMode === 'dark' ? 'active' : ''}`}
            onClick={() => setThemeMode('dark')}
            title="深色模式"
          >
            🌙
          </button>
          <button
            type="button"
            className={`theme-segmented-btn ${themeMode === 'system' ? 'active' : ''}`}
            onClick={() => setThemeMode('system')}
            title="跟随系统"
          >
            💻
          </button>
        </div>

        {/* 激活快捷键设置药丸 */}
        <button className="hotkey-pill" onClick={openHotkeyModal} title="点击更改唤醒快捷键">
          <span className="hotkey-icon">⌨️</span>
          <span className="hotkey-label">{t('hotkey_label')}</span>
          <div className="hotkey-keys">
            {parseHotkey(currentHotkey).map((k, idx) => (
              <kbd key={idx}>{k}</kbd>
            ))}
          </div>
        </button>

        {/* 界面语言选择器 */}
        <div className="language-select-wrapper">
          <span className="lang-icon">🌐</span>
          <select
            className="lang-select"
            value={currentLang}
            onChange={(e) => changeLanguage(e.target.value)}
            title="选择界面语言"
          >
            {availableLangs.map((item) => (
              <option key={item.code} value={item.code}>
                {item.name}
              </option>
            ))}
          </select>
        </div>
      </div>
    </header>
  );
}

