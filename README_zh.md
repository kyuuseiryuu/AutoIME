# AutoIME

基于 AutoHotkey v2 的 Windows 输入法与键盘布局自动切换工具。

[ [English](README.md) | 简体中文 | [日本語](README_ja.md) ]

[![AutoHotkey v2](https://img.shields.io/badge/AutoHotkey-v2.0%2B-334455.svg?style=flat-square)](https://www.autohotkey.com/)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%2F%2011-0078D6.svg?style=flat-square)](https://microsoft.com/windows)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)

---

## 概述

AutoIME 是一个运行于 Windows 平台的后台辅助工具，用于根据当前前台活动窗口自动切换对应的输入法（IME）或键盘布局。程序通过 Win32 全局事件钩子（`SetWinEventHook`）实时响应系统前台窗口激活事件（零周期轮询唤醒、零延迟瞬时生效），并在检测到匹配规则的进程时，调用系统接口将输入法切换至目标状态。

## 功能特性

- **进程级别自动切换**：目标程序获得前台焦点时，自动切换至配置的输入法或键盘布局。
- **系统布局动态枚举**：通过 Win32 API 与注册表读取当前系统已安装的键盘布局和输入法，自动生成对应的配置标签页。
- **窗口捕获模式**：实时检测鼠标指针指向窗口的进程名与窗口标题，支持通过点击或快捷键直接添加为匹配规则。
- **按键录制配置**：内置快捷键设置弹窗，实时监听键盘组合输入（支持 `Ctrl`、`Alt`、`Shift`、`Win` 与任意按键），用于配置全局唤醒快捷键（默认：`Ctrl+Alt+I`）。
- **多语言与易扩展**：原生支持简体中文、英文与日语，可在界面中直接切换。多语言采用独立的 `lang/*.ini` 文件维护，添加新语种只需新增对应的 INI 语言包即可，无需修改脚本源码。
- **系统托盘集成**：支持最小化至系统托盘常驻运行，托盘右键菜单提供配置打开、重载、通知切换及开机自启管理功能。
- **开机自启动管理**：通过在 Windows 用户启动目录（`shell:startup`）创建或移除快捷方式实现开机自启控制，不修改系统注册表。
- **规则冲突处理**：当尝试向某输入法添加已绑定在其他输入法的进程时，弹出确认提示并支持一键迁移。

## 运行环境

- **操作系统**：Windows 10 / Windows 11（支持 64 位及 32 位）
- **运行环境**：[AutoHotkey v2.0+](https://www.autohotkey.com/)（仅直接运行脚本时需要）

## 安装与运行

### 直接运行脚本

1. 克隆或下载代码仓库：
   ```bash
   git clone https://github.com/your-username/AutoIME.git
   cd AutoIME
   ```
2. 在已安装 AutoHotkey v2 的环境下直接运行 `AutoIME.ahk`。

### 编译为可执行文件 (EXE)

如需在未安装 AutoHotkey 的设备上运行：
1. 启动 AutoHotkey 自带的 `Ahk2Exe` 编译器；
2. **Source (script)** 指定为 `AutoIME.ahk`；
3. **Destination (.exe)** 指定为输出路径（如 `AutoIME.exe`）；
4. **Base File** 选择 `AutoHotkey64.exe` (v2)；
5. 点击 **Convert** 生成独立运行文件。

## 使用说明

### 添加进程规则

1. 按下快捷键 <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>I</kbd> 或双击系统托盘图标打开配置窗口。
2. 切换至目标输入法对应的标签页。
3. 通过以下任意方式添加进程：
   - **窗口捕获**：点击【🎯 窗口捕获】，将鼠标悬停在目标软件窗口上，单击鼠标左键（或按 <kbd>Space</kbd> / <kbd>Enter</kbd> / <kbd>F8</kbd>）确认；按 <kbd>Esc</kbd> 取消。
   - **浏览 EXE**：点击【📁 浏览EXE】，通过文件对话框选择可执行文件。
   - **手动添加**：点击【➕ 手动添加】，输入进程文件名（例如 `code.exe`）。
4. 点击【💾 保存并应用】保存更改。

### 常用快捷操作

| 操作 / 按键 | 说明 |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>I</kbd> | 打开或隐藏配置界面（可在界面中修改） |
| 双击系统托盘图标 | 打开配置界面 |
| 捕获模式下按 <kbd>Esc</kbd> | 退出捕获模式 |
| 捕获模式下按 <kbd>Space</kbd> / <kbd>Enter</kbd> / <kbd>F8</kbd> | 确认添加当前鼠标悬停的窗口 |

## 配置文件结构

配置持久化保存在脚本同级目录下的 `AutoIME_config.ini` 中（编码为 UTF-16 LE）。若文件不存在，程序首次启动时会自动创建并写入推荐初始规则。

```ini
[Settings]
DebugMode=0        ; 0: 关闭切换提示 | 1: 切换时显示 ToolTip 提示
Language=zh        ; 界面语言: zh (中文) | en (英文) | ja (日文)
Hotkey=^!i         ; 快捷键格式 (^=Ctrl, !=Alt, +=Shift, #=Win)

[IME_0x08040804]   ; 布局 HKL 标识 (如 微软拼音)
DisplayName=中文(简体) - 微软拼音
weixin.exe=微信
qq.exe=QQ

[IME_0x04090409]   ; 布局 HKL 标识 (如 美式键盘)
DisplayName=English (美式键盘)
code.exe=Visual Studio Code
windowsterminal.exe=Windows Terminal
```

参考模板文件见 [`AutoIME_config.example.ini`](AutoIME_config.example.ini)。

## 项目文件结构

```text
AutoIME/
├── lang/
│   ├── en.ini                    # 英文语言包
│   ├── ja.ini                    # 日文语言包
│   └── zh.ini                    # 中文语言包
├── AutoIME.ahk                   # 核心 AutoHotkey v2 脚本
├── AutoIME_config.example.ini    # 用户配置参考模板
├── LICENSE                       # MIT 开源许可证
├── README.md                     # 项目文档（英文主入口）
├── README_ja.md                  # 项目文档（日文）
└── README_zh.md                  # 项目文档（中文）
```

## 技术实现细节

- **事件驱动架构**：采用 Win32 原生事件钩子（`SetWinEventHook` 监听 `EVENT_SYSTEM_FOREGROUND = 0x0003`），彻底取代传统定时轮询机制，实现待机 0% CPU 占用与零延迟瞬发响应。
- **切换接口**：通过 `PostMessageW` 向目标窗口句柄投递 `WM_INPUTLANGCHANGEREQUEST`（消息号 `0x0050`）。对于中文（`0x0804`）及美式英语（`0x0409`），通过 IMM32 接口获取默认 IME 窗口（`ImmGetDefaultIMEWnd`）并发送状态控制消息（`0x0283`），以调整中英文开闭状态。
- **权限边界与 UIPI**：根据 Windows 用户界面特权隔离（UIPI）机制，低特权级别的进程无法向高特权级别（以管理员权限运行）的窗口发送消息。若需要对管理员权限运行的程序进行切换，需以管理员权限启动 AutoIME。

## 开源协议

本项目采用 [MIT License](LICENSE) 协议发布。

