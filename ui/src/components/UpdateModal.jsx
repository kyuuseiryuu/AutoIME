import React from 'react';
import { useApp } from '../context/AppContext';

function formatDateTime(iso) {
  if (!iso) return '-';
  try {
    const d = new Date(iso);
    if (isNaN(d.getTime())) return iso;
    return d.toLocaleString(undefined, {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false
    });
  } catch {
    return iso;
  }
}

export function UpdateModal() {
  const { updateModal, closeUpdateModal, applyUpdate, currentVersion, currentCommit, currentBuildTime, t } = useApp();

  if (!updateModal.isOpen) return null;

  const targetVer = updateModal.latestVersion || currentVersion;
  const targetCommit = updateModal.latestCommit || '';

  return (
    <div className="modal-backdrop" onClick={closeUpdateModal}>
      <div className="modal-card modal-update-card" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2 className="modal-title">🚀 {t('update_title')}</h2>
          {!updateModal.isUpdating && (
            <button type="button" className="modal-close" onClick={closeUpdateModal}>
              &times;
            </button>
          )}
        </div>

        <div className="modal-body">
          {/* 版本与时间对比信息 */}
          <div className="update-version-card">
            <div className="update-version-col">
              <span className="update-version-label">当前本地版本</span>
              <span className="update-version-val">{currentVersion} <small>#{currentCommit}</small></span>
              {currentBuildTime && (
                <span className="update-time-tag" title="本地构建/提交时间">
                  🕒 {formatDateTime(currentBuildTime)}
                </span>
              )}
            </div>
            <div className="update-version-arrow">➔</div>
            <div className="update-version-col update-version-new">
              <span className="update-version-label">GitHub 最新发布</span>
              <span className="update-version-val">{targetVer} {targetCommit && <small>#{targetCommit}</small>}</span>
              {updateModal.latestTime && (
                <span className="update-time-tag update-time-new" title="GitHub Release 发布/Commit 提交时间">
                  ✨ {formatDateTime(updateModal.latestTime)}
                </span>
              )}
            </div>
          </div>

          {/* 更新日志/摘要说明 */}
          {updateModal.message && (
            <div className="update-changelog-box">
              <div className="update-changelog-title">📋 发布说明 / Commit Message:</div>
              <pre className="update-changelog-text">{updateModal.message}</pre>
            </div>
          )}

          {/* 更新进行状态 */}
          {updateModal.isUpdating && (
            <div className="update-progress-box">
              <div className="update-spinner"></div>
              <p className="update-progress-text">{t('update_downloading')}</p>
            </div>
          )}
        </div>

        <div className="modal-footer">
          {updateModal.htmlUrl && (
            <a
              href={updateModal.htmlUrl}
              target="_blank"
              rel="noreferrer"
              className="btn btn-ghost btn-sm"
              style={{ textDecoration: 'none', display: 'inline-flex', alignItems: 'center', gap: '4px' }}
            >
              🌐 {t('update_btn_view')}
            </a>
          )}
          <div className="modal-footer-right">
            {!updateModal.isUpdating ? (
              <>
                <button type="button" className="btn btn-secondary" onClick={closeUpdateModal}>
                  {t('update_btn_later')}
                </button>
                <button
                  type="button"
                  className="btn btn-primary btn-pulse"
                  onClick={() => applyUpdate(updateModal.downloadUrl)}
                >
                  ⚡ {t('update_btn_now')}
                </button>
              </>
            ) : (
              <span className="text-muted" style={{ fontSize: '13px' }}>请勿关闭窗口，正在自动更新并重启...</span>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
