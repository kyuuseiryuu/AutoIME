import React from 'react';
import { useApp } from '../context/AppContext';

export function Toolbar() {
  const {
    systemImes,
    activeTabIdx,
    searchQuery,
    setSearchQuery,
    startCapture,
    browseExe,
    setIsManualModalOpen,
    t
  } = useApp();

  const curIme = systemImes[activeTabIdx];
  if (!curIme) return null;

  const count = curIme.apps ? curIme.apps.length : 0;
  const langIdHex = ((Number(curIme.hkl) >>> 0) & 0xffff).toString(16).toUpperCase().padStart(4, '0');

  return (
    <section className="toolbar">
      {/* 输入法标识信息 */}
      <div className="ime-meta-info">
        <div className="ime-name">{curIme.displayName}</div>
        <div className="ime-badges">
          <span className="meta-tag">HKL: {curIme.hklHex?.startsWith('0x') ? curIme.hklHex : `0x${curIme.hklHex}`}</span>
          <span className="meta-tag">LangID: 0x{langIdHex}</span>
          <span className="meta-tag meta-count">{count} 个应用</span>
        </div>
      </div>

      {/* 搜索框与操作按钮组 */}
      <div className="toolbar-actions">
        {/* 搜索框 */}
        <div className="search-box">
          <svg className="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="11" cy="11" r="8"></circle>
            <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
          </svg>
          <input
            type="text"
            placeholder="搜索已绑定的程序..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value.toLowerCase().trim())}
            autoComplete="off"
          />
          {searchQuery && (
            <button
              type="button"
              className="search-clear"
              onClick={() => setSearchQuery('')}
              title="清空搜索"
            >
              &times;
            </button>
          )}
        </div>

        {/* 功能按钮：单图标由多语言字典统一输出 */}
        <button
          type="button"
          className="btn btn-primary btn-pulse"
          onClick={startCapture}
          title="点击后将十字靶心移动到目标窗口即可绑定"
        >
          <span>{t('btn_capture')}</span>
        </button>

        <button
          type="button"
          className="btn btn-secondary"
          onClick={browseExe}
          title="从文件系统中选择可执行文件"
        >
          <span>{t('btn_browse')}</span>
        </button>

        <button
          type="button"
          className="btn btn-secondary"
          onClick={() => setIsManualModalOpen(true)}
          title="手动输入进程名称添加"
        >
          <span>{t('btn_manual')}</span>
        </button>
      </div>
    </section>
  );
}
