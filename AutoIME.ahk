#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(true)
DetectHiddenWindows(true) ; 开启：支持 IME 默认隐藏服务窗口

; ==============================================================================
; AutoIME - 多输入法自动绑定与切换工具 (AutoHotkey v2)
;
; 架构说明：模块化分层架构
;   - core/ : 核心逻辑层
;       - Globals.ahk       : 全局变量与配置状态
;       - Logger.ahk        : 调试日志辅助
;       - I18n.ahk          : 国际化语言包与字典管理器
;       - ImeEngine.ahk     : 系统输入法枚举与底层 IMM32 激活引擎
;       - Config.ahk        : INI 读写、规则持久化与热键管理
;       - WindowWatcher.ahk : WinEventHook 事件驱动窗口监听
;   - ui/   : 界面交互层
;       - HotkeyDialog.ahk  : 键盘组合键交互式设置弹窗
;       - WindowCapture.ahk : 🎯 靶心窗口捕获模式与鼠标钩子
;       - TrayMenu.ahk      : 托盘图标菜单与开关状态同步
;       - ConfigGui.ahk     : 主配置窗口 (原生 Tab 页控件架构)
; ==============================================================================

; 1. 引入核心逻辑模块
#Include "core\Globals.ahk"
#Include "core\Logger.ahk"
#Include "core\I18n.ahk"
#Include "core\ImeEngine.ahk"
#Include "core\Config.ahk"
#Include "core\WindowWatcher.ahk"

; 2. 引入 UI 视图层模块
#Include "ui\HotkeyDialog.ahk"
#Include "ui\WindowCapture.ahk"
#Include "ui\TrayMenu.ahk"
#Include "ui\ConfigGui.ahk"

; ==============================================================================
; 主程序生命周期与初始化
; ==============================================================================

LoadConfig()
ApplyHotkey(CurrentHotkey, false)
InitTrayMenu()
InitWinEventHook()
OnExit(CleanupWinEventHook)
ShowConfigGui()

; 首次启动时检测当前前台窗口
if (currHwnd := WinExist("A"))
    ProcessWindowSwitch(currHwnd)
