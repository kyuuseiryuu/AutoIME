#Requires AutoHotkey v2.0

; ==============================================================================
; AutoIME - 全局变量与状态配置
; ==============================================================================

global ConfigFile     := A_ScriptDir . "\AutoIME_config.ini"
global LOG_FILE       := A_ScriptDir . "\AutoIME_debug.log"
global LANG_DIR       := A_ScriptDir . "\lang"
global PROJECT_URL    := "https://github.com/kyuuseiryuu/AutoIME"
global DEBUG_MODE     := true
global CurrentLang    := "en"      ; 界面语言代码 (默认为 en)
global CurrentDict    := Map()     ; 当前语言字典
global FallbackDict   := Map()     ; 回退语言字典 (en)
global AvailableLangs := []        ; 可用语言列表 [{ code, name, file }]
global CurrentHotkey  := "^!i"     ; 默认唤醒快捷键 (Ctrl+Alt+I)
global SystemImes     := []        ; Array of { hkl, hklHex, displayName, langId }
global AppToImeMap    := Map()     ; Map(procName => { hkl, name })
global ImeTabList     := []        ; Array of tab data with controls
global ConfigGui      := unset     ; GUI 实例
global MainTabCtrl    := unset     ; Tab 控件实例

; GUI 顶部与底部全局控件句柄（用于 Resize 动态布局）
global txtTitleCtrl       := unset
global txtHkLabelCtrl     := unset
global btnHotkeyCtrl      := unset
global txtLangLabelCtrl   := unset
global ddlLangCtrl        := unset
global chkDebugCtrl       := unset
global chkStartupCtrl     := unset
global btnRefreshImeCtrl  := unset
global btnSaveCtrl        := unset
global btnCloseCtrl       := unset

global isCapturing    := false     ; 是否处于窗口捕获模式
global captureTab     := 1         ; 当前捕获的目标 Tab 序号
global lastHwnd       := 0         ; 上一个活动窗口句柄
global AutoStartLnk   := A_Startup . "\AutoIME.lnk"
global WinEventHookHandle   := 0   ; WinEventHook 事件钩子句柄
global WinEventProcCallback := 0   ; 事件回调函数指针

; 托盘菜单项文本引用（用于动态勾选）
global TrayItem_Open      := ""
global TrayItem_Reload    := ""
global TrayItem_Debug     := ""
global TrayItem_AutoStart := ""
global TrayItem_Github    := ""
global TrayItem_Restart   := ""
global TrayItem_Exit      := ""
