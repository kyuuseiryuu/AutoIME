import React from 'react';
import { useApp } from '../context/AppContext';

export function BatchBar() {
  const { selectedExes, deleteSelected, clearCurrentTab, t } = useApp();

  if (selectedExes.size === 0) return null;

  return (
    <div className="batch-bar">
      <span className="batch-text">
        已选中 <strong>{selectedExes.size}</strong> 项
      </span>
      <div className="batch-buttons">
        <button
          type="button"
          className="btn btn-danger btn-sm"
          onClick={deleteSelected}
        >
          <span>{t('btn_delete')}</span>
        </button>
        <button
          type="button"
          className="btn btn-ghost btn-sm"
          onClick={clearCurrentTab}
        >
          <span>{t('btn_clear')}</span>
        </button>
      </div>
    </div>
  );
}

