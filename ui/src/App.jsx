import React from 'react';
import { Header } from './components/Header';
import { TabsNav } from './components/TabsNav';
import { Toolbar } from './components/Toolbar';
import { AppsTable } from './components/AppsTable';
import { BatchBar } from './components/BatchBar';
import { Footer } from './components/Footer';
import { HotkeyModal } from './components/HotkeyModal';
import { ManualModal } from './components/ManualModal';
import { ConfirmModal } from './components/ConfirmModal';
import { UpdateModal } from './components/UpdateModal';
import { ToastContainer } from './components/ToastContainer';

export function App() {
  return (
    <div className="app-container">
      {/* 顶部标题与设置栏 */}
      <Header />

      {/* 输入法切换标签栏 */}
      <TabsNav />

      {/* 主体卡片区域 */}
      <main className="content-card">
        <Toolbar />
        <AppsTable />
        <BatchBar />
      </main>

      {/* 底部功能状态栏 */}
      <Footer />

      {/* 交互弹窗集合 */}
      <HotkeyModal />
      <ManualModal />
      <ConfirmModal />
      <UpdateModal />

      {/* Toast 提示容器 */}
      <ToastContainer />
    </div>
  );
}

