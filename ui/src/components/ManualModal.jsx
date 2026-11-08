import React, { useState, useEffect, useRef } from 'react';
import { useApp } from '../context/AppContext';

export function ManualModal() {
  const { isManualModalOpen, setIsManualModalOpen, activeTabIdx, addExe, showToast, t } = useApp();
  const [exe, setExe] = useState('');
  const [remark, setRemark] = useState('');
  const inputRef = useRef(null);

  useEffect(() => {
    if (isManualModalOpen) {
      setExe('');
      setRemark('');
      setTimeout(() => inputRef.current?.focus(), 50);
    }
  }, [isManualModalOpen]);

  if (!isManualModalOpen) return null;

  const handleSubmit = (e) => {
    e?.preventDefault();
    let proc = exe.trim().toLowerCase();
    if (!proc) {
      showToast('请输入程序进程名', 'warning');
      inputRef.current?.focus();
      return;
    }
    if (!proc.endsWith('.exe')) {
      proc += '.exe';
    }
    const rem = remark.trim() || '手动添加';
    setIsManualModalOpen(false);
    addExe(activeTabIdx, proc, rem);
  };

  return (
    <div className="modal-backdrop" onClick={() => setIsManualModalOpen(false)}>
      <div className="modal-card" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2 className="modal-title">{t('manual_title')}</h2>
          <button type="button" className="modal-close" onClick={() => setIsManualModalOpen(false)}>
            &times;
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            <div className="form-group">
              <label htmlFor="inputManualExe">程序进程名 (EXE):</label>
              <input
                ref={inputRef}
                id="inputManualExe"
                type="text"
                placeholder="例如: notepad.exe 或 code.exe"
                value={exe}
                onChange={(e) => setExe(e.target.value)}
                spellCheck="false"
                autoComplete="off"
              />
              <span className="form-hint">支持自动补充 .exe 后缀</span>
            </div>

            <div className="form-group">
              <label htmlFor="inputManualRemark">程序描述 / 备注 (可选):</label>
              <input
                id="inputManualRemark"
                type="text"
                placeholder="例如: 文本编辑器 或 个人开发工具"
                value={remark}
                onChange={(e) => setRemark(e.target.value)}
                autoComplete="off"
              />
            </div>
          </div>

          <div className="modal-footer">
            <div className="modal-footer-right">
              <button
                type="button"
                className="btn btn-secondary"
                onClick={() => setIsManualModalOpen(false)}
              >
                取消
              </button>
              <button type="submit" className="btn btn-primary">
                确认添加
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
}

