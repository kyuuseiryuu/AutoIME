import React from 'react';
import { useApp } from '../context/AppContext';

export function ConfirmModal() {
  const { confirmModal, setConfirmModal } = useApp();

  if (!confirmModal.isOpen) return null;

  const handleClose = (confirmed) => {
    const callback = confirmModal.onConfirm;
    setConfirmModal((prev) => ({ ...prev, isOpen: false }));
    if (confirmed && typeof callback === 'function') {
      callback();
    }
  };

  return (
    <div className="modal-backdrop" onClick={() => handleClose(false)}>
      <div className="modal-card modal-confirm-card" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2 className="modal-title">{confirmModal.title || '确认操作'}</h2>
          <button type="button" className="modal-close" onClick={() => handleClose(false)}>
            &times;
          </button>
        </div>

        <div className="modal-body">
          <div className="confirm-content">
            <div className="confirm-icon">{confirmModal.icon || '⚠️'}</div>
            <p className="confirm-message">{confirmModal.message}</p>
          </div>
        </div>

        <div className="modal-footer modal-footer-right">
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => handleClose(false)}
          >
            取消
          </button>
          <button
            type="button"
            className="btn btn-primary"
            onClick={() => handleClose(true)}
          >
            确定
          </button>
        </div>
      </div>
    </div>
  );
}

