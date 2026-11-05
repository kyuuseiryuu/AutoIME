# AutoIME 多语言配置与本地化指南 / Localization Guide

AutoIME 具备完整的国际化（i18n）架构。界面文本完全由外部语言文件驱动，支持运行时无缝切换、动态热加载与多层优雅回退。

本文档详细说明 AutoIME 的多语言机制、语言文件规范、所有词条对照说明，以及如何为 AutoIME 添加新语言。

---

## 目录 / Table of Contents

- [一、核心特性与回退机制](#一核心特性与回退机制)
- [二、语言包文件规范](#二语言包文件规范)
- [三、词条键值完整对照表](#三词条键值完整对照表)
- [四、添加新语言（简易教程）](#四添加新语言简易教程)
- [五、测试与生效](#五测试与生效)

---

## 一、核心特性与回退机制

1. **零编译热加载**：
   - 程序启动时会自动扫描 `lang/` 目录下的所有 `*.ini` 语言包。
   - 切换语言无需重启程序，在右上角下拉框选择后即刻全局刷新界面。

2. **内置英文根基（强壮兜底保障）**：
   - 即使外部 `lang/` 目录丢失，或误删除了 `lang/en.ini`，程序内部也内建了完整的英文词典，保证绝不崩溃，UI 也绝不会裸露原始变量名。
   - 若 `lang/en.ini` 缺失，程序会在启动时自动根据内置模板在 `lang/` 目录重新生成标准的 `en.ini`。

3. **词条级回退策略（Fallback）**：
   - 当正在使用的语言包（如自定义语言或翻译不完整的语言包）缺失某个词条时，系统会自动回退读取英文默认文本，确保界面元素始终完整可用。

---

## 二、语言包文件规范

### 1. 文件命名与存放路径

- 所有语言包均存放于项目根目录下的 `lang/` 文件夹。
- 命名规则：`<语言代码>.ini`，建议遵循 BCP 47 或标准 ISO 639 规范。
  - 例如：`fr.ini` (法语)、`de.ini` (德语)、`ko.ini` (韩语)、`es.ini` (西班牙语)、`zh_TW.ini` (繁体中文)。

### 2. 文件编码

- **必须使用 UTF-8 编码**（支持带 BOM 或无 BOM）。
- 若使用 ANSI / GBK 等系统编码保存，可能导致特殊字符或多国语言文字出现乱码。

### 3. 文件结构

语言文件采用标准 INI 格式，分为 `[Meta]` 与 `[UI]` 两个小节：

```ini
; ==============================================================================
; AutoIME Language File - <语言名称> (<代码>)
; Encoding: UTF-8
; ==============================================================================

[Meta]
Name=Français         ; 在配置窗口右上角语言下拉列表中显示的名称
Code=fr               ; 语言标识代码，需与文件名一致（不含 .ini）

[UI]
app_title=AutoIME - Configuration
header_title=⚡ AutoIME - Commutateur automatique
...
```

### 4. 语法规则与转义符

- **注释**：以 `;` 或 `#` 开头的行为注释行。
- **换行符**：在键值中使用 `\n` 表示换行（例如 `提示信息第一行\n提示信息第二行`）。
- **动态占位符**：
  - `{1}`, `{2}`, `{3}` ... 代表运行时动态填充的变量参数。
  - `{2:04X}` 表示将第 2 个参数格式化为 4 位大写十六进制（例如输入法 LangID：`0x0409`）。
  - **注意**：请务必在翻译中保留这些占位符，否则动态信息（如进程名、快捷键、输入法名称等）将无法正常显示。

---

## 三、词条键值完整对照表

### 1. 主窗口与顶部导航

| 键名 (Key) | 默认英文 (English Default) | 占位符说明 | 用途说明 |
| :--- | :--- | :--- | :--- |
| `app_title` | `AutoIME - Input Method Auto Switcher Configuration` | - | 主窗口标题栏文字 |
| `header_title` | `⚡ AutoIME - Automatic Input Method Switcher` | - | 顶部左侧主标题 |
| `header_desc` | `Tabs below correspond to installed system IMEs. Add applications to a panel to automatically switch to that IME when activated.` | - | 顶部说明文字（备用） |
| `lang_label` | `Language:` | - | 语言下拉框左侧提示标签 |
| `hotkey_label` | `Hotkey:` | - | 快捷键设置按钮左侧提示标签 |
| `hotkey_updated` | `Hotkey updated to: {1}` | `{1}`: 新快捷键显示名 | 快捷键修改成功气泡提示 |
| `hotkey_failed` | `Failed to register hotkey ({1}): {2}` | `{1}`: 快捷键, `{2}`: 错误码 | 快捷键注册失败提示 |

### 2. 标签页控制与列表

| 键名 (Key) | 默认英文 (English Default) | 占位符说明 | 用途说明 |
| :--- | :--- | :--- | :--- |
| `ime_info` | `IME: {1} (LangID: 0x{2:04X})  \|  Configured: {3} apps` | `{1}`: HKL十六进制<br>`{2}`: 语言ID<br>`{3}`: 规则数量 | Tab 页顶部的输入法状态说明 |
| `btn_capture` | `🎯 Capture Window` | - | 窗口捕获按钮 |
| `btn_browse` | `📁 Browse EXE` | - | 选择 EXE 文件按钮 |
| `btn_manual` | `➕ Add Manual` | - | 手动添加进程按钮 |
| `col_num` | `#` | - | 表格第一列：序号 |
| `col_exe` | `Process Name (EXE)` | - | 表格第二列：进程文件名 |
| `col_desc` | `Description / Window Title` | - | 表格第三列：窗口标题/程序说明 |
| `btn_delete` | `❌ Delete Selected` | - | 删除选中程序按钮 |
| `btn_clear` | `🗑️ Clear Tab` | - | 清空当前标签页按钮 |
| `chk_debug` | `Enable ToolTip notifications` | - | 底部：开启悬浮提示复选框 |
| `chk_startup` | `Run on Windows Startup` | - | 底部：开机自启动复选框 |
| `btn_refresh_ime` | `🔄 Refresh IMEs` | - | 底部：刷新系统输入法列表按钮 |
| `btn_save` | `💾 Save & Apply` | - | 底部：保存并应用按钮 |
| `btn_minimize` | `Minimize to Tray` | - | 底部：最小化至托盘按钮 |

### 3. 快捷键录制弹窗

| 键名 (Key) | 默认英文 (English Default) | 占位符说明 | 用途说明 |
| :--- | :--- | :--- | :--- |
| `hk_dialog_title` | `⌨️ Set Activation Hotkey` | - | 快捷键录制弹窗标题 |
| `hk_dialog_prompt` | `Press the new key combination directly on your keyboard:` | - | 弹窗主引导文本 |
| `hk_dialog_help` | `Supports: Ctrl, Alt, Shift, Win + any Key\nClick [Confirm] to apply and save` | - | 按键组合支持说明（支持 `\n` 换行） |
| `hk_dialog_confirm` | `Confirm` | - | 确认保存按钮 |
| `hk_dialog_cancel` | `Cancel` | - | 取消关闭按钮 |
| `hk_dialog_reset` | `Reset Default (Ctrl+Alt+I)` | - | 恢复默认快捷键按钮 |
| `hk_dialog_empty` | `Please press a valid key combination first!` | - | 未检测到有效组合时的警告提示 |

### 4. 交互对话框与消息提示

| 键名 (Key) | 默认英文 (English Default) | 占位符说明 | 用途说明 |
| :--- | :--- | :--- | :--- |
| `save_success` | `✅ Configuration saved and applied immediately!` | - | 保存成功弹窗提示 |
| `del_success` | `Selected application(s) removed.` | - | 删除条目成功提示 |
| `del_select_hint` | `Please select a row in the list first!` | - | 未选中列表行时的操作提示 |
| `clear_confirm` | `Are you sure you want to clear all configured apps for [{1}]?` | `{1}`: 当前输入法名称 | 清空前确认弹窗内容 |
| `clear_title` | `Confirm Clear` | - | 清空确认弹窗标题 |
| `browse_title` | `Select Executable File` | - | 文件选取对话框标题 |
| `browse_filter` | `Executables (*.exe)` | - | 文件选取过滤器 |
| `manual_prompt` | `Enter process executable name (e.g. notepad.exe or code.exe):` | - | 手动输入框提示 |
| `manual_title` | `Add Application Manually` | - | 手动输入框标题 |
| `manual_default_remark` | `Manually added` | - | 手动添加条目的默认备注 |
| `already_in_tab` | `Application [{1}] is already configured for [{2}]!` | `{1}`: 进程名<br>`{2}`: 输入法名 | 重复添加提示 |
| `conflict_prompt` | `Application [{1}] is currently assigned to [{2}].\n\nDo you want to move it to [{3}]?` | `{1}`: 进程名<br>`{2}`: 原输入法<br>`{3}`: 目标输入法 | 跨输入法规则冲突确认提示 |
| `conflict_title` | `Rule Conflict` | - | 冲突确认对话框标题 |
| `add_success` | `✅ Successfully bound: {1} -> {2}` | `{1}`: 进程名<br>`{2}`: 目标输入法 | 绑定成功提示 |

### 5. 🎯 窗口捕获模式

| 键名 (Key) | 默认英文 (English Default) | 占位符说明 | 用途说明 |
| :--- | :--- | :--- | :--- |
| `capture_mode_title` | `🎯 [AutoIME Window Capture Mode]` | - | 捕获浮窗顶部标题 |
| `capture_target_ime` | `Target IME: {1}` | `{1}`: 目标输入法名称 | 提示当前正绑定的输入法 |
| `capture_hover_proc` | `Hovered Process: {1}` | `{1}`: 鼠标悬停进程名 | 实时展示指向的进程 |
| `capture_hover_title` | `Window Title: {1}` | `{1}`: 鼠标悬停窗口标题 | 实时展示指向窗口的标题 |
| `capture_no_title` | `(No Title)` | - | 窗口无标题时的回退显示 |
| `capture_hint_confirm` | `👉 Action: [Left Click] or press [Space/Enter/F8] to capture` | - | 操作指引：确认绑定 |
| `capture_hint_cancel` | `👉 Cancel: Press [ESC] to exit` | - | 操作指引：退出捕获 |
| `capture_scanning` | `🎯 [Capturing] Point at target window and click (Press ESC to cancel)` | - | 状态提示 |
| `capture_invalid` | `Could not get a valid target window!` | - | 未能获取有效窗口句柄 |
| `capture_self_window` | `You selected AutoIME itself. Capture cancelled.` | - | 捕获自身窗口时的拦截提示 |
| `capture_failed_proc` | `Could not read process name for this window!` | - | 获取进程失败 |
| `capture_failed_title` | `Capture Failed` | - | 捕获失败弹窗标题 |
| `capture_cancelled` | `Window capture cancelled.` | - | 退出捕获模式提示 |

### 6. 系统托盘与状态控制

| 键名 (Key) | 默认英文 (English Default) | 占位符说明 | 用途说明 |
| :--- | :--- | :--- | :--- |
| `startup_enabled` | `Launch on startup enabled` | - | 开启开机启动通知 |
| `startup_disabled` | `Launch on startup disabled` | - | 关闭开机启动通知 |
| `startup_failed` | `Failed to configure startup: {1}` | `{1}`: 错误详情 | 开机启动操作失败提示 |
| `ime_reloaded` | `IME list reloaded successfully!` | - | 重新枚举输入法完成提示 |
| `tray_open_config` | `⚙️ Open Settings ({1})` | `{1}`: 激活快捷键 | 托盘右键菜单：打开主界面 |
| `tray_reload_config` | `🔄 Reload Config` | - | 托盘右键菜单：重新加载配置 |
| `tray_toggle_debug` | `💬 Toggle ToolTip Hints` | - | 托盘右键菜单：切换通知提示 |
| `tray_toggle_startup` | `🚀 Run on Startup` | - | 托盘右键菜单：开机自启动开关 |
| `tray_github` | `🌐 GitHub Repository (Check Updates)` | - | 托盘右键菜单：打开 GitHub 项目主页获取最新版本 |
| `tray_restart` | `⚡ Restart AutoIME` | - | 托盘右键菜单：一键重启自身程序 |
| `tray_exit` | `❌ Exit AutoIME` | - | 托盘右键菜单：退出程序 |
| `tray_tip_minimized` | `AutoIME is minimized to tray and running in background.\nDouble-click tray icon or press activation hotkey to open settings.` | - | 首次最小化到托盘时的气泡引导 |
| `debug_enabled` | `ToolTip hints enabled` | - | 切换通知开启状态提示 |
| `debug_disabled` | `ToolTip hints disabled` | - | 切换通知关闭状态提示 |

### 7. 默认分类备注

| 键名 (Key) | 默认英文 (English Default) | 占位符说明 | 用途说明 |
| :--- | :--- | :--- | :--- |
| `desc_dev_tool` | `Development Tool` | - | 默认内置推荐规则说明（如 VS Code、终端） |
| `desc_chat_tool` | `Communication App` | - | 默认内置推荐规则说明（如微信、QQ） |

---

## 四、添加新语言（简易教程）

只需 3 步即可为 AutoIME 添加一种全新的语言：

### 第 1 步：复制模板

复制 `lang/en.ini`，将其重命名为你想要添加的语言代码。例如添加法语：
```bash
copy lang\en.ini lang\fr.ini
```

### 第 2 步：编辑元信息与词条

使用支持 UTF-8 的文本编辑器（如 VS Code、Notepad++）打开新建的 `.ini` 文件：
1. 修改 `[Meta]` 小节：
   ```ini
   [Meta]
   Name=Français
   Code=fr
   ```
2. 逐行翻译 `[UI]` 小节下的对应文本。

### 第 3 步：保存并测试

- 确保保存格式为 **UTF-8**。
- 启动或重新加载 AutoIME，在右上角语言下拉框中即可直接看到新添加的 `Français`！选择后界面将即时刷新。

---

## 五、测试与生效

- 如果你的翻译文件中偶尔有部分词条尚未翻译，**可以直接省略该行或留空**，AutoIME 会自动显示对应的内置英文，绝不影响程序的正常稳定运行。
- 如果你在测试时发现了文案排版、折行或占位符异常，只需修改 `.ini` 文件并在托盘菜单点击【重新加载配置】（或在界面中重新切换语言）即可立即预览效果。
- 欢迎将你翻译的高质量语言包通过 Pull Request 提交至本仓库，与全球用户分享！

