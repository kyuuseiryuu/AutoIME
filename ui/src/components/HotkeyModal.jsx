import React from 'react';
import { useApp } from '../context/AppContext';

export function HotkeyModal() {
  const {
    isHotkeyModalOpen,
    closeHotkeyModal,
    tempHotkeyRaw,
    confirmHotkey,
    resetHotkeyDefault,
    t
  } = useApp();

  if (!isHotkeyModalOpen) return null;

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
    <div className="modal-backdrop" onClick={closeHotkeyModal}>
      <div className="modal-card" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2 className="modal-title">{t('hk_dialog_title')}</h2>
          <button type="button" className="modal-close" onClick={closeHotkeyModal}>
            &times;
          </button>
        </div>

        <div className="modal-body">
          <p className="modal-prompt">{t('hk_dialog_prompt')}</p>

          <div className="hotkey-recorder-box">
            <div className="hotkey-keys-large">
              {parseHotkey(tempHotkeyRaw).map((k, idx) => (
                <kbd key={idx}>{k}</kbd>
              ))}
            </div>
            <div className="listening-indicator">
              <span className="pulse-dot"></span>
              <span>正在监听按键输入 (按 Esc 退出，Enter 确认)...</span>
            </div>
          </div>

          <p className="modal-help">{t('hk_dialog_help')}</p>
        </div>

        <div className="modal-footer">
          <button
            type="button"
            className="btn btn-ghost"
            onClick={resetHotkeyDefault}
          >
            恢复默认 (Ctrl+Alt+I)
          </button>
          <div className="modal-footer-right">
            <button
              type="button"
              className="btn btn-secondary"
              onClick={closeHotkeyModal}
            >
              取消
            </button>
            <button
              type="button"
              className="btn btn-primary"
              onClick={confirmHotkey}
            >
              确定保存
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

