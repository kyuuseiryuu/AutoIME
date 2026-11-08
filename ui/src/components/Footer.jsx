import React from 'react';
import { useApp } from '../context/AppContext';

export function Footer() {
  const {
    debugMode,
    toggleDebug,
    autoStart,
    toggleStartup,
    refreshImes,
    saveConfig,
    minimizeWindow,
    t
  } = useApp();

  return (
    <footer className="app-footer">
      {/* 底部设置开关 */}
      <div className="footer-switches">
        <label className="switch-control" title="切换前台窗口时在右下角显示当前输入法提示">
          <input
            type="checkbox"
            checked={debugMode}
            onChange={(e) => toggleDebug(e.target.checked)}
          />
          <span className="switch-slider"></span>
          <span className="switch-label">{t('chk_debug')}</span>
        </label>

        <label className="switch-control" title="随 Windows 系统登录时自动后台静默启动">
          <input
            type="checkbox"
            checked={autoStart}
            onChange={(e) => toggleStartup(e.target.checked)}
          />
          <span className="switch-slider"></span>
          <span className="switch-label">{t('chk_startup')}</span>
        </label>
      </div>

      {/* 底部操作按钮 */}
      <div className="footer-actions">
        <button
          type="button"
          className="btn btn-ghost"
          onClick={refreshImes}
          title="检测系统新安装或移除的输入法语言"
        >
          <span>{t('btn_refresh_ime')}</span>
        </button>

        <button
          type="button"
          className="btn btn-primary btn-save"
          onClick={saveConfig}
          title="将所有规则立即保存并写入 INI 配置文件"
        >
          <span>{t('btn_save')}</span>
        </button>

        <button
          type="button"
          className="btn btn-secondary"
          onClick={minimizeWindow}
          title="隐藏主配置窗口，继续在托盘静默运行"
        >
          <span>{t('btn_minimize')}</span>
        </button>
      </div>
    </footer>
  );
}

