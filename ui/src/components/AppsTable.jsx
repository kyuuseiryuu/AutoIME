import React from 'react';
import { useApp } from '../context/AppContext';

export function AppsTable() {
  const {
    systemImes,
    activeTabIdx,
    searchQuery,
    selectedExes,
    toggleSelectExe,
    toggleSelectAll,
    deleteExe,
    startCapture,
    browseExe,
    t
  } = useApp();

  const curIme = systemImes[activeTabIdx];
  const allApps = curIme?.apps || [];

  // 根据搜索词过滤
  const filteredApps = searchQuery
    ? allApps.filter(
        (item) =>
          item.exe.toLowerCase().includes(searchQuery) ||
          (item.remark && item.remark.toLowerCase().includes(searchQuery))
      )
    : allApps;

  const totalCount = allApps.length;
  const isAllChecked = totalCount > 0 && selectedExes.size === totalCount;

  return (
    <section className="table-container">
      {filteredApps.length > 0 ? (
        <table className="apps-table">
          <thead>
            <tr>
              <th className="th-check">
                <input
                  type="checkbox"
                  checked={isAllChecked}
                  onChange={(e) => toggleSelectAll(e.target.checked)}
                  title="全选 / 取消全选"
                />
              </th>
              <th className="th-num">#</th>
              <th className="th-exe">{t('col_exe')}</th>
              <th className="th-desc">{t('col_desc')}</th>
              <th className="th-action">操作</th>
            </tr>
          </thead>
          <tbody>
            {filteredApps.map((item, index) => {
              const isSelected = selectedExes.has(item.exe);
              return (
                <tr key={item.exe} className={isSelected ? 'selected' : ''}>
                  <td className="td-check">
                    <input
                      type="checkbox"
                      checked={isSelected}
                      onChange={() => toggleSelectExe(item.exe)}
                    />
                  </td>
                  <td className="td-num">{index + 1}</td>
                  <td className="th-exe">
                    <div className="exe-cell">
                      <div className="exe-icon">⚙️</div>
                      <span className="exe-name">{item.exe}</span>
                    </div>
                  </td>
                  <td className="th-desc">
                    <div className="desc-text" title={item.remark || ''}>
                      {item.remark || '-'}
                    </div>
                  </td>
                  <td className="th-action">
                    <button
                      type="button"
                      className="btn-row-del"
                      title="删除此条规则"
                      onClick={(e) => {
                        e.stopPropagation();
                        deleteExe(activeTabIdx, item.exe);
                      }}
                    >
                      🗑️
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      ) : (
        /* 空数据或搜索无果占位提示 */
        <div className="empty-state">
          <div className="empty-icon-wrap">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
              <rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect>
              <line x1="8" y1="21" x2="16" y2="21"></line>
              <line x1="12" y1="17" x2="12" y2="21"></line>
            </svg>
          </div>
          {searchQuery ? (
            <>
              <h3 className="empty-title">未找到匹配的应用程序</h3>
              <p className="empty-desc">没有包含关键词 "{searchQuery}" 的规则</p>
            </>
          ) : (
            <>
              <h3 className="empty-title">当前输入法暂无绑定程序</h3>
              <p className="empty-desc">
                当切换至绑定的应用程序窗口时，AutoIME 会自动将其切换至此输入法。
              </p>
              <div className="empty-actions">
                <button type="button" className="btn btn-primary" onClick={startCapture}>
                  <span>🎯 捕获前台窗口</span>
                </button>
                <button type="button" className="btn btn-secondary" onClick={browseExe}>
                  <span>📁 浏览 EXE 添加</span>
                </button>
              </div>
            </>
          )}
        </div>
      )}
    </section>
  );
}

