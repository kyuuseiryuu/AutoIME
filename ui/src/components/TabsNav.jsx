import React from 'react';
import { useApp } from '../context/AppContext';

export function TabsNav() {
  const { systemImes, activeTabIdx, switchTab } = useApp();

  return (
    <nav className="tabs-nav" aria-label="输入法标签页">
      {systemImes.map((ime, idx) => {
        const isActive = idx === activeTabIdx;
        const count = ime.apps ? ime.apps.length : 0;
        return (
          <button
            key={ime.hklHex || idx}
            type="button"
            className={`tab-btn ${isActive ? 'active' : ''}`}
            onClick={() => switchTab(idx)}
          >
            <span>{ime.displayName}</span>
            <span className="tab-badge">{count}</span>
          </button>
        );
      })}
    </nav>
  );
}

