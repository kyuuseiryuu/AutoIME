import React, { createContext, useContext, useState, useEffect, useCallback, useMemo } from 'react';
import { useTheme } from './ThemeContext';

const AppContext = createContext();

export function AppProvider({ children }) {
  const { setThemeMode } = useTheme();
  const ahk = useMemo(() => window.chrome?.webview?.hostObjects?.sync?.ahk, []);

  // 核心状态
  const [currentVersion, setCurrentVersion] = useState(process.env.APP_VERSION || 'v2.0.0');
  const [currentCommit, setCurrentCommit] = useState(process.env.COMMIT_HASH || 'dev');
  const [currentBuildTime, setCurrentBuildTime] = useState(process.env.BUILD_TIME || '');
  const [systemImes, setSystemImes] = useState([]);
  const [activeTabIdx, setActiveTabIdx] = useState(0);
  const [currentLang, setCurrentLang] = useState('zh');
  const [availableLangs, setAvailableLangs] = useState([]);
  const [currentHotkey, setCurrentHotkey] = useState('^!i');
  const [debugMode, setDebugMode] = useState(true);
  const [autoStart, setAutoStart] = useState(false);
  const [translations, setTranslations] = useState({});

  // 搜索与多选状态
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedExes, setSelectedExes] = useState(new Set());

  // 弹窗状态
  const [isHotkeyModalOpen, setIsHotkeyModalOpen] = useState(false);
  const [tempHotkeyRaw, setTempHotkeyRaw] = useState('^!i');

  const [isManualModalOpen, setIsManualModalOpen] = useState(false);

  const [confirmModal, setConfirmModal] = useState({
    isOpen: false,
    title: '',
    message: '',
    icon: '⚠️',
    onConfirm: null
  });

  // 在线更新弹窗状态
  const [updateModal, setUpdateModal] = useState({
    isOpen: false,
    hasUpdate: false,
    latestVersion: '',
    latestCommit: '',
    message: '',
    downloadUrl: '',
    htmlUrl: '',
    isUpdating: false
  });

  // 全局 Toast 提示列表
  const [toasts, setToasts] = useState([]);

  // Toast 发送函数
  const showToast = useCallback((message, type = 'info', duration = 2400) => {
    const id = Date.now() + Math.random().toString(36).substring(2, 6);
    setToasts((prev) => [...prev, { id, message, type }]);

    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, duration);
  }, []);

  // 获取多语言文本
  const t = useCallback((key, ...args) => {
    let str = translations[key] || key;
    if (args.length > 0) {
      args.forEach((arg, i) => {
        str = str.replace(new RegExp(`\\{${i + 1}\\}`, 'g'), arg);
      });
    }
    return str;
  }, [translations]);

  // 从 AHK 宿主全量读取初始状态
  const loadDataFromAhk = useCallback(() => {
    if (!ahk) {
      console.warn('AHK host object not found, using mock data.');
      initMockData();
      return;
    }

    try {
      const rawJson = ahk.GetInitialDataJson();
      const data = JSON.parse(rawJson);

      setSystemImes(data.systemImes || []);
      setCurrentLang(data.currentLang || 'zh');
      setAvailableLangs(data.availableLangs || []);
      setCurrentHotkey(data.currentHotkey || '^!i');
      setTempHotkeyRaw(data.currentHotkey || '^!i');
      setDebugMode(!!data.debugMode);
      setAutoStart(!!data.autoStart);
      setTranslations(data.translations || {});

      if (data.currentVersion) {
        setCurrentVersion(data.currentVersion);
      }
      if (data.currentCommit) {
        setCurrentCommit(data.currentCommit);
      }
      if (data.currentBuildTime) {
        setCurrentBuildTime(data.currentBuildTime);
      }

      // 同步主题设置
      if (data.theme) {
        setThemeMode(data.theme);
      }
    } catch (err) {
      console.error('Failed to load initial data from AHK:', err);
      showToast('加载配置数据失败: ' + err.message, 'danger');
    }
  }, [ahk, showToast, setThemeMode]);

  // 初始挂载加载
  useEffect(() => {
    loadDataFromAhk();
  }, [loadDataFromAhk]);

  // 当切换 Tab 时清空勾选
  const switchTab = useCallback((idx) => {
    setActiveTabIdx(idx);
    setSelectedExes(new Set());
  }, []);

  // 勾选单项
  const toggleSelectExe = useCallback((exe) => {
    setSelectedExes((prev) => {
      const next = new Set(prev);
      if (next.has(exe)) {
        next.delete(exe);
      } else {
        next.add(exe);
      }
      return next;
    });
  }, []);

  // 全选 / 取消全选
  const toggleSelectAll = useCallback((checked) => {
    const curIme = systemImes[activeTabIdx];
    if (!curIme || !curIme.apps) return;

    if (checked) {
      setSelectedExes(new Set(curIme.apps.map((a) => a.exe)));
    } else {
      setSelectedExes(new Set());
    }
  }, [systemImes, activeTabIdx]);

  // 增量同步状态至 AHK
  const syncToAhk = useCallback((imes) => {
    if (ahk && typeof ahk.SyncStateToAhk === 'function') {
      try {
        ahk.SyncStateToAhk(JSON.stringify(imes));
      } catch (err) {
        console.error('Failed to sync state to AHK:', err);
      }
    }
  }, [ahk]);

  // 检查冲突并添加 EXE
  const addExe = useCallback((tabIdx, proc, remark = '') => {
    proc = proc.toLowerCase().trim();
    if (!proc.endsWith('.exe')) proc += '.exe';

    setSystemImes((prevImes) => {
      const curIme = prevImes[tabIdx];
      if (!curIme) return prevImes;

      // 检查当前输入法是否已存在
      if (curIme.apps && curIme.apps.some((a) => a.exe === proc)) {
        showToast(`程序 [${proc}] 已经在 [${curIme.displayName}] 中`, 'warning');
        return prevImes;
      }

      // 检查其他输入法是否有冲突
      let conflictTabIdx = -1;
      for (let i = 0; i < prevImes.length; i++) {
        if (i === tabIdx) continue;
        if (prevImes[i].apps && prevImes[i].apps.some((a) => a.exe === proc)) {
          conflictTabIdx = i;
          break;
        }
      }

      if (conflictTabIdx !== -1) {
        const otherIme = prevImes[conflictTabIdx];
        const msg = `程序 [${proc}] 当前已绑定至 [${otherIme.displayName}]。\n\n是否确认将其移动到 [${curIme.displayName}]？`;

        setConfirmModal({
          isOpen: true,
          title: '规则冲突',
          message: msg,
          icon: '⚠️',
          onConfirm: () => {
            setSystemImes((oldImes) => {
              const updated = oldImes.map((ime, idx) => {
                if (idx === conflictTabIdx) {
                  return { ...ime, apps: ime.apps.filter((a) => a.exe !== proc) };
                }
                if (idx === tabIdx) {
                  return { ...ime, apps: [...(ime.apps || []), { exe: proc, remark }] };
                }
                return ime;
              });
              syncToAhk(updated);
              showToast(`✅ 已将 [${proc}] 转移至 [${curIme.displayName}]`, 'success');
              return updated;
            });
          }
        });
        return prevImes;
      }

      // 无冲突正常添加
      const nextImes = prevImes.map((ime, idx) => {
        if (idx === tabIdx) {
          return { ...ime, apps: [...(ime.apps || []), { exe: proc, remark }] };
        }
        return ime;
      });

      syncToAhk(nextImes);
      showToast(`✅ 成功绑定: ${proc}`, 'success');
      return nextImes;
    });
  }, [syncToAhk, showToast]);

  // 删除单项规则
  const deleteExe = useCallback((tabIdx, exe) => {
    setSystemImes((prevImes) => {
      const nextImes = prevImes.map((ime, idx) => {
        if (idx === tabIdx) {
          return { ...ime, apps: ime.apps.filter((a) => a.exe !== exe) };
        }
        return ime;
      });
      syncToAhk(nextImes);
      return nextImes;
    });

    setSelectedExes((prev) => {
      const next = new Set(prev);
      next.delete(exe);
      return next;
    });

    showToast(`已移除规则: ${exe}`, 'info');
  }, [syncToAhk, showToast]);

  // 批量删除选中的规则
  const deleteSelected = useCallback(() => {
    if (selectedExes.size === 0) return;
    const count = selectedExes.size;

    setSystemImes((prevImes) => {
      const nextImes = prevImes.map((ime, idx) => {
        if (idx === activeTabIdx) {
          return { ...ime, apps: ime.apps.filter((a) => !selectedExes.has(a.exe)) };
        }
        return ime;
      });
      syncToAhk(nextImes);
      return nextImes;
    });

    setSelectedExes(new Set());
    showToast(`已删除 ${count} 条规则`, 'info');
  }, [selectedExes, activeTabIdx, syncToAhk, showToast]);

  // 清空当前 Tab 规则
  const clearCurrentTab = useCallback(() => {
    const curIme = systemImes[activeTabIdx];
    if (!curIme || !curIme.apps || curIme.apps.length === 0) return;

    setConfirmModal({
      isOpen: true,
      title: '清空确认',
      message: `确定要清空 [${curIme.displayName}] 下绑定的全部 ${curIme.apps.length} 个程序吗？`,
      icon: '🗑️',
      onConfirm: () => {
        setSystemImes((prevImes) => {
          const nextImes = prevImes.map((ime, idx) => {
            if (idx === activeTabIdx) {
              return { ...ime, apps: [] };
            }
            return ime;
          });
          syncToAhk(nextImes);
          return nextImes;
        });
        setSelectedExes(new Set());
        showToast('已清空当前列表', 'info');
      }
    });
  }, [systemImes, activeTabIdx, syncToAhk, showToast]);

  // 靶心窗口捕获
  const startCapture = useCallback(() => {
    if (ahk && typeof ahk.StartWindowCapture === 'function') {
      ahk.StartWindowCapture(activeTabIdx + 1);
    } else {
      showToast('模拟捕获: chrome.exe', 'info');
      setTimeout(() => addExe(activeTabIdx, 'chrome.exe', 'Google Chrome'), 600);
    }
  }, [ahk, activeTabIdx, addExe, showToast]);

  // 浏览 EXE
  const browseExe = useCallback(() => {
    if (ahk && typeof ahk.BrowseExe === 'function') {
      const resJson = ahk.BrowseExe(activeTabIdx + 1);
      if (resJson) {
        try {
          const res = JSON.parse(resJson);
          if (res && res.exe) {
            addExe(activeTabIdx, res.exe, res.remark);
          }
        } catch {}
      }
    } else {
      showToast('模拟添加: notepad.exe', 'info');
      addExe(activeTabIdx, 'notepad.exe', '记事本');
    }
  }, [ahk, activeTabIdx, addExe, showToast]);

  // 快捷键设置弹窗控制
  const openHotkeyModal = useCallback(() => {
    setTempHotkeyRaw(currentHotkey);
    setIsHotkeyModalOpen(true);
    if (ahk && typeof ahk.StartHotkeyCapture === 'function') {
      ahk.StartHotkeyCapture();
    }
  }, [currentHotkey, ahk]);

  const closeHotkeyModal = useCallback(() => {
    setIsHotkeyModalOpen(false);
    if (ahk && typeof ahk.StopHotkeyCapture === 'function') {
      ahk.StopHotkeyCapture();
    }
  }, [ahk]);

  const confirmHotkey = useCallback(() => {
    if (!tempHotkeyRaw) {
      showToast('请先在键盘上按下有效组合按键', 'warning');
      return;
    }
    const success = ahk && typeof ahk.ConfirmHotkey === 'function' ? ahk.ConfirmHotkey(tempHotkeyRaw) : 1;
    if (success) {
      setCurrentHotkey(tempHotkeyRaw);
      closeHotkeyModal();
      showToast(`快捷键已更新为: ${tempHotkeyRaw}`, 'success');
    } else {
      showToast('快捷键注册失败，可能被其他软件占用', 'danger');
    }
  }, [tempHotkeyRaw, ahk, closeHotkeyModal, showToast]);

  const resetHotkeyDefault = useCallback(() => {
    setTempHotkeyRaw('^!i');
  }, []);

  // 切换界面语言
  const changeLanguage = useCallback((code) => {
    if (ahk && typeof ahk.ChangeLanguage === 'function') {
      ahk.ChangeLanguage(code);
      loadDataFromAhk();
    } else {
      setCurrentLang(code);
      showToast(`切换语言至: ${code}`, 'info');
    }
  }, [ahk, loadDataFromAhk, showToast]);

  // 悬浮提示开关
  const toggleDebug = useCallback((val) => {
    setDebugMode(val);
    if (ahk && typeof ahk.ToggleDebug === 'function') {
      ahk.ToggleDebug(val);
    }
    showToast(val ? '悬浮提示通知已开启' : '悬浮提示通知已关闭', 'info');
  }, [ahk, showToast]);

  // 开机自启开关
  const toggleStartup = useCallback((val) => {
    setAutoStart(val);
    if (ahk && typeof ahk.ToggleStartup === 'function') {
      ahk.ToggleStartup(val);
    }
    showToast(val ? '已开启开机自启动' : '已关闭开机自启动', 'info');
  }, [ahk, showToast]);

  // 刷新输入法
  const refreshImes = useCallback(() => {
    if (ahk && typeof ahk.ReloadSystemImes === 'function') {
      ahk.ReloadSystemImes();
      loadDataFromAhk();
      showToast('🔄 系统输入法列表已刷新', 'info');
    }
  }, [ahk, loadDataFromAhk, showToast]);

  // 全量保存并应用
  const saveConfig = useCallback(() => {
    if (ahk && typeof ahk.SaveConfigJson === 'function') {
      const ok = ahk.SaveConfigJson(JSON.stringify(systemImes));
      if (ok) {
        showToast('✅ 配置已立即保存并应用生效！', 'success');
      } else {
        showToast('❌ 保存配置失败，请查看日志', 'danger');
      }
    } else {
      showToast('测试模式: 配置保存成功', 'success');
    }
  }, [ahk, systemImes, showToast]);

  // 最小化到托盘
  const minimizeWindow = useCallback(() => {
    if (ahk && typeof ahk.MinimizeWindow === 'function') {
      ahk.MinimizeWindow();
    }
  }, [ahk]);

  // 检查在线更新
  const checkUpdate = useCallback((isManual = true) => {
    if (isManual) {
      showToast(t('update_checking'), 'info');
    }

    if (!ahk || typeof ahk.CheckForUpdates !== 'function') {
      setTimeout(() => {
        showToast(t('update_latest', `${currentVersion} #${currentCommit}`), 'success');
      }, 500);
      return;
    }

    try {
      const resJson = ahk.CheckForUpdates();
      const res = JSON.parse(resJson);

      if (res.hasUpdate) {
        setUpdateModal({
          isOpen: true,
          hasUpdate: true,
          latestVersion: res.latestVersion || currentVersion,
          latestCommit: res.latestCommit || '',
          latestTime: res.latestTime || '',
          message: res.message || '',
          downloadUrl: res.downloadUrl || '',
          htmlUrl: res.htmlUrl || '',
          isUpdating: false
        });
        showToast(t('update_available', res.latestVersion || (res.latestCommit ? `#${res.latestCommit}` : '新版本')), 'warning');
      } else if (res.error) {
        showToast(t('update_failed', res.error), 'danger');
      } else if (isManual) {
        showToast(t('update_latest', `${currentVersion} #${currentCommit}`), 'success');
      }
    } catch (err) {
      console.error('Update check failed:', err);
      if (isManual) {
        showToast(t('update_failed', err.message), 'danger');
      }
    }
  }, [ahk, currentVersion, currentCommit, showToast, t]);

  // 执行在线更新
  const applyUpdate = useCallback((downloadUrl) => {
    setUpdateModal((prev) => ({ ...prev, isUpdating: true }));
    showToast(t('update_downloading'), 'info', 8000);

    setTimeout(() => {
      if (ahk && typeof ahk.PerformUpdate === 'function') {
        ahk.PerformUpdate(downloadUrl || updateModal.downloadUrl);
      } else {
        alert('测试模式：已触发更新，真实环境下将自动下载并重启。');
        setUpdateModal((prev) => ({ ...prev, isUpdating: false, isOpen: false }));
      }
    }, 400);
  }, [ahk, updateModal.downloadUrl, showToast, t]);

  const closeUpdateModal = useCallback(() => {
    if (!updateModal.isUpdating) {
      setUpdateModal((prev) => ({ ...prev, isOpen: false }));
    }
  }, [updateModal.isUpdating]);

  // 挂载全局 window.app 供 AHK 异步回调
  useEffect(() => {
    window.app = {
      onWindowCaptured: (tabIdx, proc, remark) => {
        const targetIdx = tabIdx - 1;
        addExe(targetIdx, proc, remark);
        if (targetIdx !== activeTabIdx) {
          setActiveTabIdx(targetIdx);
        }
      },
      onKeyCaptured: (formattedText, rawHk) => {
        setTempHotkeyRaw(rawHk);
      },
      updateSetting: (name, val) => {
        if (name === 'debug') setDebugMode(val);
        if (name === 'autostart') setAutoStart(val);
      },
      loadDataFromAhk,
      switchTab,
      closeHotkeyModal,
      confirmHotkey,
      checkUpdate
    };
  }, [addExe, activeTabIdx, loadDataFromAhk, switchTab, closeHotkeyModal, confirmHotkey, checkUpdate]);

  // 离线测试模拟数据
  const initMockData = () => {
    setSystemImes([
      {
        hkl: 0x08040804,
        hklHex: '00000804',
        displayName: '微软拼音 (中文)',
        apps: [
          { exe: 'weixin.exe', remark: '微信聊天客户端' },
          { exe: 'qq.exe', remark: '腾讯 QQ' },
          { exe: 'dingtalk.exe', remark: '钉钉' }
        ]
      },
      {
        hkl: 0x04090409,
        hklHex: '00000409',
        displayName: 'English (United States)',
        apps: [
          { exe: 'code.exe', remark: 'VS Code 编辑器' },
          { exe: 'windowsterminal.exe', remark: 'Windows 终端' },
          { exe: 'idea64.exe', remark: 'IntelliJ IDEA' }
        ]
      }
    ]);
    setAvailableLangs([
      { code: 'zh', name: '简体中文' },
      { code: 'en', name: 'English' },
      { code: 'ja', name: '日本語' }
    ]);
    setCurrentLang('zh');
    setCurrentHotkey('^!i');
  };

  const value = {
    currentVersion,
    currentCommit,
    currentBuildTime,
    updateModal,
    checkUpdate,
    applyUpdate,
    closeUpdateModal,
    systemImes,
    activeTabIdx,
    currentLang,
    availableLangs,
    currentHotkey,
    debugMode,
    autoStart,
    searchQuery,
    selectedExes,
    toasts,
    isHotkeyModalOpen,
    tempHotkeyRaw,
    isManualModalOpen,
    confirmModal,
    t,
    showToast,
    switchTab,
    setSearchQuery,
    toggleSelectExe,
    toggleSelectAll,
    addExe,
    deleteExe,
    deleteSelected,
    clearCurrentTab,
    startCapture,
    browseExe,
    openHotkeyModal,
    closeHotkeyModal,
    setTempHotkeyRaw,
    confirmHotkey,
    resetHotkeyDefault,
    setIsManualModalOpen,
    setConfirmModal,
    changeLanguage,
    toggleDebug,
    toggleStartup,
    refreshImes,
    saveConfig,
    minimizeWindow
  };

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp() {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
}

