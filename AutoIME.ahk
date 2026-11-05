#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(true)
DetectHiddenWindows(true) ; 开启：支持 IME 默认隐藏服务窗口

; ==============================================================================
; AutoIME - 多输入法自动绑定与切换工具 (AutoHotkey v2)
; 功能：
;   1. 自动枚举系统当前安装的所有输入法/键盘布局，生成对应配置 Tab
;   2. 支持在每个输入法面板中绑定关联的进程 (exe)
;   3. 提供【🎯 窗口捕获】按钮，点击后鼠标指向或点击目标窗口即可自动提取 exe 名称
;   4. 窗口激活时毫秒级自动切换到匹配的输入法
;   5. 配置自动持久化到 AutoIME_config.ini，支持托盘操作与自定义快捷键唤醒
;   6. 全面支持中、英、日三语 i18n 实时切换
;   7. 托盘菜单原生同步 ToolTip 提示开关与开机自启动勾选激活标志 (✓)
;   8. 窗口支持全响应式 Resize 动态填充缩放，控件绝对坐标隔离，首屏秒开不白屏
;   9. 键盘组合键交互式弹窗设置与确认
; ==============================================================================

; ================== 1. 全局变量 ==================
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

; ================== 2. 国际化 (i18n) 语言管理器 ==================

; 获取程序内置的完整英文翻译字典（用作最高可靠性兜底保障）
GetBuiltinEnglishDict() {
    return Map(
        "app_title", "AutoIME - Input Method Auto Switcher Configuration",
        "header_title", "⚡ AutoIME - Automatic Input Method Switcher",
        "header_desc", "Tabs below correspond to installed system IMEs. Add applications to a panel to automatically switch to that IME when activated.",
        "lang_label", "Language:",
        "hotkey_label", "Hotkey:",
        "hotkey_updated", "Hotkey updated to: {1}",
        "hotkey_failed", "Failed to register hotkey ({1}): {2}",
        "ime_info", "IME: {1} (LangID: 0x{2:04X})  |  Configured: {3} apps",
        "btn_capture", "🎯 Capture Window",
        "btn_browse", "📁 Browse EXE",
        "btn_manual", "➕ Add Manual",
        "col_num", "#",
        "col_exe", "Process Name (EXE)",
        "col_desc", "Description / Window Title",
        "btn_delete", "❌ Delete Selected",
        "btn_clear", "🗑️ Clear Tab",
        "chk_debug", "Enable ToolTip notifications",
        "chk_startup", "Run on Windows Startup",
        "btn_refresh_ime", "🔄 Refresh IMEs",
        "btn_save", "💾 Save & Apply",
        "btn_minimize", "Minimize to Tray",
        "hk_dialog_title", "⌨️ Set Activation Hotkey",
        "hk_dialog_prompt", "Press the new key combination directly on your keyboard:",
        "hk_dialog_help", "Supports: Ctrl, Alt, Shift, Win + any Key`nClick [Confirm] to apply and save",
        "hk_dialog_confirm", "Confirm",
        "hk_dialog_cancel", "Cancel",
        "hk_dialog_reset", "Reset Default (Ctrl+Alt+I)",
        "hk_dialog_empty", "Please press a valid key combination first!",
        "save_success", "✅ Configuration saved and applied immediately!",
        "del_success", "Selected application(s) removed.",
        "del_select_hint", "Please select a row in the list first!",
        "clear_confirm", "Are you sure you want to clear all configured apps for [{1}]?",
        "clear_title", "Confirm Clear",
        "browse_title", "Select Executable File",
        "browse_filter", "Executables (*.exe)",
        "manual_prompt", "Enter process executable name (e.g. notepad.exe or code.exe):",
        "manual_title", "Add Application Manually",
        "manual_default_remark", "Manually added",
        "already_in_tab", "Application [{1}] is already configured for [{2}]!",
        "conflict_prompt", "Application [{1}] is currently assigned to [{2}].`n`nDo you want to move it to [{3}]?",
        "conflict_title", "Rule Conflict",
        "add_success", "✅ Successfully bound: {1} -> {2}",
        "capture_mode_title", "🎯 [AutoIME Window Capture Mode]",
        "capture_target_ime", "Target IME: {1}",
        "capture_hover_proc", "Hovered Process: {1}",
        "capture_hover_title", "Window Title: {1}",
        "capture_no_title", "(No Title)",
        "capture_hint_confirm", "👉 Action: [Left Click] or press [Space/Enter/F8] to capture",
        "capture_hint_cancel", "👉 Cancel: Press [ESC] to exit",
        "capture_scanning", "🎯 [Capturing] Point at target window and click (Press ESC to cancel)",
        "capture_invalid", "Could not get a valid target window!",
        "capture_self_window", "You selected AutoIME itself. Capture cancelled.",
        "capture_failed_proc", "Could not read process name for this window!",
        "capture_failed_title", "Capture Failed",
        "capture_cancelled", "Window capture cancelled.",
        "startup_enabled", "Launch on startup enabled",
        "startup_disabled", "Launch on startup disabled",
        "startup_failed", "Failed to configure startup: {1}",
        "ime_reloaded", "IME list reloaded successfully!",
        "tray_open_config", "⚙️ Open Settings ({1})",
        "tray_reload_config", "🔄 Reload Config",
        "tray_toggle_debug", "💬 Toggle ToolTip Hints",
        "tray_toggle_startup", "🚀 Run on Startup",
        "tray_github", "🌐 GitHub Repository (Check Updates)",
        "tray_restart", "⚡ Restart AutoIME",
        "tray_exit", "❌ Exit AutoIME",
        "tray_tip_minimized", "AutoIME is minimized to tray and running in background.`nDouble-click tray icon or press activation hotkey to open settings.",
        "debug_enabled", "ToolTip hints enabled",
        "debug_disabled", "ToolTip hints disabled",
        "desc_dev_tool", "Development Tool",
        "desc_chat_tool", "Communication App"
    )
}

; 若 lang/en.ini 缺失，自动在磁盘生成一份标准英文语言包供用户参考或自定义
EnsureDefaultEnIni() {
    global LANG_DIR
    enFile := LANG_DIR . "\en.ini"
    if FileExist(enFile)
        return
        
    if !DirExist(LANG_DIR) {
        try DirCreate(LANG_DIR)
    }
    
    enContent := 
(
"; ==============================================================================
; AutoIME Language File - English (en)
; Encoding: UTF-8
; ==============================================================================

[Meta]
Name=English
Code=en

[UI]
app_title=AutoIME - Input Method Auto Switcher Configuration
header_title=⚡ AutoIME - Automatic Input Method Switcher
header_desc=Tabs below correspond to installed system IMEs. Add applications to a panel to automatically switch to that IME when activated.
lang_label=Language:
hotkey_label=Hotkey:
hotkey_updated=Hotkey updated to: {1}
hotkey_failed=Failed to register hotkey ({1}): {2}
ime_info=IME: {1} (LangID: 0x{2:04X})  |  Configured: {3} apps
btn_capture=🎯 Capture Window
btn_browse=📁 Browse EXE
btn_manual=➕ Add Manual
col_num=#
col_exe=Process Name (EXE)
col_desc=Description / Window Title
btn_delete=❌ Delete Selected
btn_clear=🗑️ Clear Tab
chk_debug=Enable ToolTip notifications
chk_startup=Run on Windows Startup
btn_refresh_ime=🔄 Refresh IMEs
btn_save=💾 Save & Apply
btn_minimize=Minimize to Tray

; Hotkey dialog
hk_dialog_title=⌨️ Set Activation Hotkey
hk_dialog_prompt=Press the new key combination directly on your keyboard:
hk_dialog_help=Supports: Ctrl, Alt, Shift, Win + any Key\nClick [Confirm] to apply and save
hk_dialog_confirm=Confirm
hk_dialog_cancel=Cancel
hk_dialog_reset=Reset Default (Ctrl+Alt+I)
hk_dialog_empty=Please press a valid key combination first!

; Dialogs & messages
save_success=✅ Configuration saved and applied immediately!
del_success=Selected application(s) removed.
del_select_hint=Please select a row in the list first!
clear_confirm=Are you sure you want to clear all configured apps for [{1}]?
clear_title=Confirm Clear
browse_title=Select Executable File
browse_filter=Executables (*.exe)
manual_prompt=Enter process executable name (e.g. notepad.exe or code.exe):
manual_title=Add Application Manually
manual_default_remark=Manually added
already_in_tab=Application [{1}] is already configured for [{2}]!
conflict_prompt=Application [{1}] is currently assigned to [{2}].\n\nDo you want to move it to [{3}]?
conflict_title=Rule Conflict
add_success=✅ Successfully bound: {1} -> {2}

; Window capture
capture_mode_title=🎯 [AutoIME Window Capture Mode]
capture_target_ime=Target IME: {1}
capture_hover_proc=Hovered Process: {1}
capture_hover_title=Window Title: {1}
capture_no_title=(No Title)
capture_hint_confirm=👉 Action: [Left Click] or press [Space/Enter/F8] to capture
capture_hint_cancel=👉 Cancel: Press [ESC] to exit
capture_scanning=🎯 [Capturing] Point at target window and click (Press ESC to cancel)
capture_invalid=Could not get a valid target window!
capture_self_window=You selected AutoIME itself. Capture cancelled.
capture_failed_proc=Could not read process name for this window!
capture_failed_title=Capture Failed
capture_cancelled=Window capture cancelled.

; Tray & helpers
startup_enabled=Launch on startup enabled
startup_disabled=Launch on startup disabled
startup_failed=Failed to configure startup: {1}
ime_reloaded=IME list reloaded successfully!
tray_open_config=⚙️ Open Settings ({1})
tray_reload_config=🔄 Reload Config
tray_toggle_debug=💬 Toggle ToolTip Hints
tray_toggle_startup=🚀 Run on Startup
tray_github=🌐 GitHub Repository (Check Updates)
tray_restart=⚡ Restart AutoIME
tray_exit=❌ Exit AutoIME
tray_tip_minimized=AutoIME is minimized to tray and running in background.\nDouble-click tray icon or press activation hotkey to open settings.
debug_enabled=ToolTip hints enabled
debug_disabled=ToolTip hints disabled

; Default remarks
desc_dev_tool=Development Tool
desc_chat_tool=Communication App
"
)
    try {
        fileObj := FileOpen(enFile, "w", "UTF-8")
        fileObj.Write(enContent)
        fileObj.Close()
    }
}

; 解析单个 INI 语言文件
ParseLangIni(filePath) {
    dict := Map()
    meta := Map("Name", "", "Code", "")
    if !FileExist(filePath)
        return { meta: meta, dict: dict }
        
    try content := FileRead(filePath, "UTF-8")
    catch
        return { meta: meta, dict: dict }
        
    currentSection := ""
    Loop Parse, content, "`n", "`r" {
        line := Trim(A_LoopField)
        if (line == "" || SubStr(line, 1, 1) == ";" || SubStr(line, 1, 1) == "#")
            continue
        if RegExMatch(line, "^\[(.*)\]$", &m) {
            currentSection := StrUpper(Trim(m[1]))
            continue
        }
        if RegExMatch(line, "^([A-Za-z0-9_]+)\s*=\s*(.*)$", &m) {
            k := m[1]
            v := StrReplace(m[2], "\n", "`n")
            if (currentSection == "META") {
                meta[k] := v
            } else if (currentSection == "UI" || currentSection == "") {
                dict[k] := v
            }
        }
    }
    return { meta: meta, dict: dict }
}

; 扫描 lang/ 目录下的所有可用语言
ScanAvailableLanguages() {
    global LANG_DIR, AvailableLangs
    AvailableLangs := []
    
    ; 尝试确保磁盘存在 en.ini 模板文件
    EnsureDefaultEnIni()
    
    if DirExist(LANG_DIR) {
        Loop Files, LANG_DIR . "\*.ini" {
            res := ParseLangIni(A_LoopFilePath)
            SplitPath(A_LoopFileName,,,, &nameNoExt)
            code := res.meta.Has("Code") && res.meta["Code"] != "" ? res.meta["Code"] : nameNoExt
            name := res.meta.Has("Name") && res.meta["Name"] != "" ? res.meta["Name"] : code
            AvailableLangs.Push({ code: code, name: name, file: A_LoopFilePath })
        }
    }
    
    ; 确保 English 选项始终存在于语言列表（即使外部目录缺失或 en.ini 被删除）
    hasEn := false
    for item in AvailableLangs {
        if (item.code == "en") {
            hasEn := true
            break
        }
    }
    if (!hasEn) {
        AvailableLangs.Push({ code: "en", name: "English", file: LANG_DIR . "\en.ini" })
    }
}

; 加载指定语言字典（含多层回退策略）
LoadLanguage(langCode) {
    global LANG_DIR, CurrentDict, FallbackDict, CurrentLang
    
    ; 1. 始终使用内置完整英文词典作为最高可靠性兜底
    FallbackDict := GetBuiltinEnglishDict()
    
    ; 若磁盘存在 en.ini，用其内容合并扩充兜底字典（支持用户个性化微调英文文案）
    fbFile := LANG_DIR . "\en.ini"
    if FileExist(fbFile) {
        resFb := ParseLangIni(fbFile)
        for k, v in resFb.dict
            FallbackDict[k] := v
    }
    
    ; 2. 加载目标语言
    if (langCode == "en") {
        CurrentDict := FallbackDict.Clone()
        CurrentLang := "en"
        return
    }
    
    targetFile := LANG_DIR . "\" . langCode . ".ini"
    if FileExist(targetFile) {
        resTarget := ParseLangIni(targetFile)
        CurrentDict := resTarget.dict
        CurrentLang := langCode
    } else {
        ; 目标语言文件不存在时，优雅回退至英文
        CurrentDict := FallbackDict.Clone()
        CurrentLang := "en"
    }
}

; 多语言翻译函数（多层回退保障，绝不出现原始键名泄漏或格式化崩溃）
T(key, args*) {
    global CurrentDict, FallbackDict
    template := (CurrentDict.Has(key) && CurrentDict[key] != "") 
        ? CurrentDict[key] 
        : ((FallbackDict.Has(key) && FallbackDict[key] != "") ? FallbackDict[key] : key)
    if (args.Length > 0) {
        try return Format(template, args*)
        catch
            return template
    }
    return template
}

; 格式化热键显示字符串 (例如 ^!i -> Ctrl + Alt + I)
FormatHotkeyDisplay(hk) {
    if (hk == "")
        return ""
    res := ""
    work := hk
    if InStr(work, "#") {
        res .= "Win + "
        work := StrReplace(work, "#", "")
    }
    if InStr(work, "^") {
        res .= "Ctrl + "
        work := StrReplace(work, "^", "")
    }
    if InStr(work, "!") {
        res .= "Alt + "
        work := StrReplace(work, "!", "")
    }
    if InStr(work, "+") {
        res .= "Shift + "
        work := StrReplace(work, "+", "")
    }
    res .= (StrLen(work) == 1 ? StrUpper(work) : work)
    return res
}

; ================== 3. 主程序入口与初始化 ==================
LoadConfig()
ApplyHotkey(CurrentHotkey, false)
InitTrayMenu()
InitWinEventHook()
OnExit(CleanupWinEventHook)
ShowConfigGui()

; 首次启动时检测当前前台窗口
if (currHwnd := WinExist("A"))
    ProcessWindowSwitch(currHwnd)

; ================== 4. 系统输入法枚举 ==================

GetImeDetails(hkl) {
    hklHex := Format("0x{:08X}", hkl)
    langId := hkl & 0xFFFF
    layoutId := (hkl >> 16) & 0xFFFF
    klid := Format("{:08X}", (layoutId ? layoutId : langId))
    
    desc := ""
    descLen := DllCall("imm32\ImmGetDescriptionW", "Ptr", hkl, "Ptr", 0, "UInt", 0)
    if (descLen > 0) {
        descBuf := Buffer((descLen + 1) * 2)
        DllCall("imm32\ImmGetDescriptionW", "Ptr", hkl, "Ptr", descBuf, "UInt", descLen + 1)
        desc := StrGet(descBuf)
    }
    
    regDisplayName := ""
    try regDisplayName := RegRead("HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\" . klid, "Layout Display Name")
    resolvedLayout := ""
    if (regDisplayName != "") {
        resBuf := Buffer(512)
        if (DllCall("shlwapi\SHLoadIndirectString", "Str", regDisplayName, "Ptr", resBuf, "UInt", 256, "Ptr", 0) == 0)
            resolvedLayout := StrGet(resBuf)
    }
    if (resolvedLayout == "") {
        try resolvedLayout := RegRead("HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\" . klid, "Layout Text")
    }
    
    nameBuf := Buffer(512)
    DllCall("GetLocaleInfoW", "UInt", langId, "UInt", 0x4, "Ptr", nameBuf, "Int", 256) ; LOCALE_SNATIVELANGNAME
    nativeLang := StrGet(nameBuf)
    if (nativeLang == "") {
        DllCall("GetLocaleInfoW", "UInt", langId, "UInt", 0x2, "Ptr", nameBuf, "Int", 256) ; LOCALE_SENGLANGUAGE
        nativeLang := StrGet(nameBuf)
    }
    
    displayName := ""
    if (desc != "") {
        displayName := desc
    } else if (resolvedLayout != "") {
        if (InStr(resolvedLayout, nativeLang))
            displayName := resolvedLayout
        else
            displayName := nativeLang . " (" . resolvedLayout . ")"
    } else {
        displayName := nativeLang . " (" . hklHex . ")"
    }
    
    displayName := RegExReplace(displayName, "[\r\n\t]", "")
    
    if (langId == 0x0804 && InStr(displayName, "美式键盘")) {
        displayName := "中文(简体) - 微软拼音"
    } else if (langId == 0x0409 && displayName == "美式键盘") {
        displayName := "英语(美国) - 美式键盘"
    }
    
    return {
        hkl: hkl,
        hklHex: hklHex,
        langId: langId,
        displayName: displayName
    }
}

GetSystemImeList() {
    imeList := []
    seen := Map()
    
    count := DllCall("GetKeyboardLayoutList", "Int", 0, "Ptr", 0)
    if (count > 0) {
        buf := Buffer(count * A_PtrSize)
        DllCall("GetKeyboardLayoutList", "Int", count, "Ptr", buf)
        Loop count {
            hkl := NumGet(buf, (A_Index - 1) * A_PtrSize, "Ptr")
            hklHex := Format("0x{:08X}", hkl)
            if seen.Has(hklHex)
                continue
            seen[hklHex] := true
            imeList.Push(GetImeDetails(hkl))
        }
    }
    
    Loop {
        try {
            val := RegRead("HKEY_CURRENT_USER\Keyboard Layout\Preload", A_Index)
            klid := StrUpper(Format("{:08s}", val))
            hklInt := Integer("0x" . klid)
            if ((hklInt >> 16) == 0)
                hklInt := (hklInt << 16) | hklInt
            hklHex := Format("0x{:08X}", hklInt)
            if !seen.Has(hklHex) {
                seen[hklHex] := true
                imeList.Push(GetImeDetails(hklInt))
            }
        } catch {
            break
        }
    }
    
    return imeList
}

; ================== 5. 配置管理 (INI 读写与默认导入) ==================

LoadConfig() {
    global SystemImes, AppToImeMap, ImeTabList, DEBUG_MODE, CurrentLang, CurrentHotkey
    
    SystemImes := GetSystemImeList()
    AppToImeMap := Map()
    ImeTabList := []
    
    try DEBUG_MODE := (IniRead(ConfigFile, "Settings", "DebugMode", "1") == "1")
    
    ; 读取快捷键配置
    try savedHk := IniRead(ConfigFile, "Settings", "Hotkey", "^!i")
    if (savedHk != "")
        CurrentHotkey := savedHk
    
    ScanAvailableLanguages()
    
    ; 读取语言配置，默认根据系统当前显示语言探测
    try savedLang := IniRead(ConfigFile, "Settings", "Language", "")
    langFound := false
    if (savedLang != "") {
        for item in AvailableLangs {
            if (item.code == savedLang) {
                langFound := true
                break
            }
        }
    }
    
    if (langFound) {
        CurrentLang := savedLang
    } else {
        uiLang := DllCall("GetUserDefaultUILanguage", "UShort")
        targetCode := "en"
        if (uiLang == 0x0411)
            targetCode := "ja"
        else if ((uiLang & 0xFF) == 0x04)
            targetCode := "zh"
            
        matched := false
        for item in AvailableLangs {
            if (item.code == targetCode) {
                matched := true
                break
            }
        }
        CurrentLang := matched ? targetCode : (AvailableLangs.Length > 0 ? AvailableLangs[1].code : "en")
    }
    
    LoadLanguage(CurrentLang)
    
    isFirstRun := !FileExist(ConfigFile)
    
    for ime in SystemImes {
        tabItem := {
            hkl: ime.hkl,
            hklHex: ime.hklHex,
            displayName: ime.displayName,
            apps: Map(),
            lvControl: "",
            txtInfo: "",
            btnCapture: "",
            btnBrowse: "",
            btnAddManual: "",
            btnDel: "",
            btnClear: ""
        }
        
        sectionData := ""
        try sectionData := IniRead(ConfigFile, "IME_" . ime.hklHex)
        
        if (sectionData != "") {
            for line in StrSplit(sectionData, "`n", "`r") {
                line := Trim(line)
                if (line == "" || SubStr(line, 1, 1) == ";" || InStr(line, "=") == 0)
                    continue
                parts := StrSplit(line, "=", , 2)
                key := StrLower(Trim(parts[1]))
                val := (parts.Length >= 2) ? Trim(parts[2]) : ""
                if (key != "displayname") {
                    tabItem.apps[key] := val
                    AppToImeMap[key] := { hkl: ime.hkl, name: ime.displayName }
                }
            }
        }
        
        ImeTabList.Push(tabItem)
    }
    
    if (isFirstRun) {
        InitDefaultRules()
        SaveConfig(false)
    }
}

InitDefaultRules() {
    global ImeTabList, AppToImeMap
    for tab in ImeTabList {
        langId := tab.hkl & 0xFFFF
        if (langId == 0x0409) {
            defaultEnglish := Map(
                "code.exe", T("desc_dev_tool"),
                "windowsterminal.exe", T("desc_dev_tool"),
                "cmd.exe", T("desc_dev_tool"),
                "powershell.exe", T("desc_dev_tool"),
                "pwsh.exe", T("desc_dev_tool"),
                "idea64.exe", T("desc_dev_tool"),
                "pycharm64.exe", T("desc_dev_tool"),
                "clion64.exe", T("desc_dev_tool"),
                "devenv.exe", T("desc_dev_tool"),
                "sublime_text.exe", T("desc_dev_tool"),
                "git-bash.exe", T("desc_dev_tool"),
                "antigravity ide.exe", T("desc_dev_tool"),
                "pebrel.exe", T("desc_dev_tool")
            )
            for app, desc in defaultEnglish {
                tab.apps[app] := desc
                AppToImeMap[app] := { hkl: tab.hkl, name: tab.displayName }
            }
        } else if (langId == 0x0804) {
            defaultChinese := Map(
                "antigravity.exe", T("desc_chat_tool"),
                "weixin.exe", T("desc_chat_tool"),
                "qq.exe", T("desc_chat_tool"),
                "dingtalk.exe", T("desc_chat_tool"),
                "feishu.exe", T("desc_chat_tool")
            )
            for app, desc in defaultChinese {
                tab.apps[app] := desc
                AppToImeMap[app] := { hkl: tab.hkl, name: tab.displayName }
            }
        }
    }
}

SaveConfig(notify := true) {
    global ImeTabList, AppToImeMap, DEBUG_MODE, CurrentLang, CurrentHotkey
    
    try IniWrite(DEBUG_MODE ? "1" : "0", ConfigFile, "Settings", "DebugMode")
    try IniWrite(CurrentLang, ConfigFile, "Settings", "Language")
    try IniWrite(CurrentHotkey, ConfigFile, "Settings", "Hotkey")
    
    AppToImeMap := Map()
    for tab in ImeTabList {
        secName := "IME_" . tab.hklHex
        try IniDelete(ConfigFile, secName)
        try IniWrite(tab.displayName, ConfigFile, secName, "DisplayName")
        for proc, remark in tab.apps {
            try IniWrite(remark, ConfigFile, secName, proc)
            AppToImeMap[proc] := { hkl: tab.hkl, name: tab.displayName }
        }
    }
    
    if (notify) {
        ToolTip(T("save_success"))
        SetTimer(() => ToolTip(), -2000)
    }
}

; 动态应用或更新激活快捷键
ApplyHotkey(newHk, notify := true) {
    global CurrentHotkey
    if (newHk == "")
        return false
    try {
        if (CurrentHotkey != "")
            Hotkey(CurrentHotkey, "Off")
    }
    try {
        Hotkey(newHk, (*) => ShowConfigGui(), "On")
        CurrentHotkey := newHk
        try IniWrite(CurrentHotkey, ConfigFile, "Settings", "Hotkey")
        InitTrayMenu()
        if (notify) {
            ToolTip(T("hotkey_updated", FormatHotkeyDisplay(CurrentHotkey)))
            SetTimer(() => ToolTip(), -1500)
        }
        return true
    } catch as err {
        if (notify)
            MsgBox(T("hotkey_failed", newHk, err.Message), "AutoIME", "Iconx")
        if (CurrentHotkey != "") {
            try Hotkey(CurrentHotkey, (*) => ShowConfigGui(), "On")
        }
        return false
    }
}

; ================== 6. 窗口切换监听与输入法激活 (WinEventHook 事件驱动) ==================

; 初始化全局前台窗口切换事件钩子
InitWinEventHook() {
    global WinEventHookHandle, WinEventProcCallback
    if (WinEventHookHandle)
        return
        
    WinEventProcCallback := CallbackCreate(OnForegroundWindowChanged, "F", 7)
    ; EVENT_SYSTEM_FOREGROUND = 0x0003
    ; WINEVENT_OUTOFCONTEXT (0x0000) | WINEVENT_SKIPOWNPROCESS (0x0002) = 0x0002
    WinEventHookHandle := DllCall("SetWinEventHook"
        , "UInt", 0x0003, "UInt", 0x0003   ; 仅监听 EVENT_SYSTEM_FOREGROUND
        , "Ptr", 0                        ; 外部 DLL 句柄 (无)
        , "Ptr", WinEventProcCallback     ; 回调函数指针
        , "UInt", 0, "UInt", 0            ; 所有进程、所有线程
        , "UInt", 2                       ; WINEVENT_SKIPOWNPROCESS (忽略自身事件)
        , "Ptr")
}

; 退出时注销事件钩子与回调内存
CleanupWinEventHook(*) {
    global WinEventHookHandle, WinEventProcCallback
    if (WinEventHookHandle) {
        DllCall("UnhookWinEvent", "Ptr", WinEventHookHandle)
        WinEventHookHandle := 0
    }
    if (WinEventProcCallback) {
        CallbackFree(WinEventProcCallback)
        WinEventProcCallback := 0
    }
}

; 系统前台窗口激活事件回调
OnForegroundWindowChanged(hHook, event, hwnd, idObject, idChild, idThread, dwTime) {
    if (event == 0x0003 && hwnd) {
        ProcessWindowSwitch(hwnd)
    }
}

; 核心窗口切换与规则匹配处理
ProcessWindowSwitch(hwnd) {
    global lastHwnd, AppToImeMap, ConfigGui
    try {
        if (!hwnd || hwnd = lastHwnd)
            return
        
        ; 忽略自身的配置窗口
        if (IsSet(ConfigGui) && ConfigGui && hwnd == ConfigGui.Hwnd)
            return
            
        lastHwnd := hwnd
        processName := StrLower(WinGetProcessName(hwnd))
        winTitle := WinGetTitle(hwnd)
        shortTitle := (StrLen(winTitle) > 35) ? SubStr(winTitle, 1, 35) . "..." : winTitle

        if AppToImeMap.Has(processName) {
            imeInfo := AppToImeMap[processName]
            LogMessage("【命中规则】" . processName . " -> 切换至: " . imeInfo.name . "`n标题: " . shortTitle)
            SwitchToIme(imeInfo.hkl, hwnd)
        } else {
            LogMessage("【未配置】进程: " . processName . "`n标题: " . shortTitle)
        }
    } catch as err {
        LogMessage("[异常] 读取窗口失败: " . err.Message, false)
    }
}

; 兼容性方法：主动检查并处理活动窗口
WatchActiveWindow(targetHwnd := 0) {
    if (!targetHwnd)
        targetHwnd := WinExist("A")
    if (targetHwnd)
        ProcessWindowSwitch(targetHwnd)
}

SwitchToIme(targetHkl, hwnd) {
    try {
        if !hwnd
            hwnd := WinExist("A")
        if !hwnd
            return

        ; 1. 向目标窗口发送 WM_INPUTLANGCHANGEREQUEST (0x0050)
        DllCall("PostMessageW", "Ptr", hwnd, "UInt", 0x0050, "Ptr", 1, "Ptr", targetHkl)
        
        ; 2. IMM32 针对中文与英文输入模式细化开闭控制
        langId := targetHkl & 0xFFFF
        if (langId == 0x0804) {
            SetImeOpenStatus(1, hwnd)
        } else if (langId == 0x0409) {
            SetImeOpenStatus(0, hwnd)
        }
    } catch as err {
        LogMessage("  └─ [异常] 切换输入法失败: " . err.Message, false)
    }
}

SetImeOpenStatus(state, hwnd := 0) {
    try {
        if !hwnd
            hwnd := WinExist("A")
        if !hwnd
            return
        imeHwnd := DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr")
        if !imeHwnd
            return
        DllCall("SendMessageW", "Ptr", imeHwnd, "UInt", 0x0283, "Ptr", 0x0006, "Ptr", state, "Ptr")
    }
}

; ================== 7. 调试日志辅助 ==================

LogMessage(msg, showToolTip := true) {
    if !DEBUG_MODE
        return
    timeStr := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    fullMsg := "[" . timeStr . "] " . StrReplace(msg, "`n", " | ")
    OutputDebug(fullMsg . "`n")
    try FileAppend(fullMsg . "`n", LOG_FILE, "UTF-8")
    if (showToolTip) {
        ToolTip("【AutoIME 调试】`n" . msg)
        SetTimer(() => ToolTip(), -2000)
    }
}

; ================== 8. 配置界面 (原生 Tab 页控件架构) ==================

ShowConfigGui(defaultTabIdx := 1) {
    global ConfigGui, MainTabCtrl, ImeTabList, DEBUG_MODE, CurrentLang, CurrentHotkey
    global txtTitleCtrl, txtHkLabelCtrl, btnHotkeyCtrl, txtLangLabelCtrl, ddlLangCtrl
    global chkDebugCtrl, chkStartupCtrl, btnRefreshImeCtrl, btnSaveCtrl, btnCloseCtrl
    
    if (IsSet(ConfigGui) && ConfigGui) {
        ConfigGui.Show()
        WinActivate("ahk_id " . ConfigGui.Hwnd)
        return
    }
    
    ; 窗口锁定固定尺寸 860x600，禁用拖拽缩放与最大化 (-MaximizeBox)
    ConfigGui := Gui("-MaximizeBox +0x02000000", T("app_title"))
    
    ; 顶部右侧：快捷键与语言选择控件组（自右向左逆向锚定布局，保证各语言自适应且互不遮挡）
    ConfigGui.SetFont("s9 norm", "Microsoft YaHei UI")
    rightMargin := 840  ; 对应 Tab 控件右边缘 (x20 + w820)
    
    ; 1. 语言选择下拉框 (靠最右侧)
    langNames := []
    selectedIdx := 1
    for idx, item in AvailableLangs {
        langNames.Push(item.name)
        if (item.code == CurrentLang)
            selectedIdx := idx
    }
    wDdl := 110
    xDdl := rightMargin - wDdl
    ddlLangCtrl := ConfigGui.Add("DropDownList", Format("x{} y14 w{}", xDdl, wDdl), langNames)
    if (langNames.Length > 0)
        ddlLangCtrl.Choose(selectedIdx)
    ddlLangCtrl.OnEvent("Change", OnLanguageSelectChange)
    
    ; 2. 语言提示标签（自适应宽度，排在下拉框左侧）
    txtLangLabelCtrl := ConfigGui.Add("Text", "y18 h22 +0x200 Right", T("lang_label"))
    txtLangLabelCtrl.GetPos(&_, &_, &wLangLabel, &_)
    xLangLabel := xDdl - 8 - wLangLabel
    txtLangLabelCtrl.Move(xLangLabel, 18)
    
    ; 3. 快捷键弹窗设置按钮（排在语言标签左侧）
    wBtnHk := 130
    xBtnHk := xLangLabel - 15 - wBtnHk
    btnHotkeyCtrl := ConfigGui.Add("Button", Format("x{} y14 w{} h26", xBtnHk, wBtnHk), "⌨️ " . FormatHotkeyDisplay(CurrentHotkey))
    btnHotkeyCtrl.OnEvent("Click", (*) => ShowHotkeySettingDialog(ConfigGui.Hwnd))
    
    ; 4. 快捷键提示标签（自适应宽度，排在快捷键按钮左侧）
    txtHkLabelCtrl := ConfigGui.Add("Text", "y18 h22 +0x200 Right", T("hotkey_label"))
    txtHkLabelCtrl.GetPos(&_, &_, &wHkLabel, &_)
    xHkLabel := xBtnHk - 6 - wHkLabel
    txtHkLabelCtrl.Move(xHkLabel, 18)
    
    ; 顶部左侧标题（完全自适应文本宽度，+0x200 垂直居中，+0x4000 保证单行绝不折行遮挡）
    ConfigGui.SetFont("s11 bold", "Microsoft YaHei UI")
    maxTitleW := xHkLabel - 20 - 10
    txtTitleCtrl := ConfigGui.Add("Text", "x20 y15 h26 +0x200 +0x4000", T("header_title"))
    txtTitleCtrl.GetPos(&_, &_, &wTitle, &_)
    if (wTitle > maxTitleW && maxTitleW > 50)
        txtTitleCtrl.Move(,, maxTitleW)
        
    ; 恢复基础字体
    ConfigGui.SetFont("s9 norm", "Microsoft YaHei UI")
    
    ; 构造 Tab 标题数组
    tabTitles := []
    for tab in ImeTabList {
        tabTitles.Push(tab.displayName)
    }
    
    ; 主 Tab 控件：y=55 开始，保留充足高度 (+0x02000000 防背景擦白)
    MainTabCtrl := ConfigGui.Add("Tab3", "x20 y55 w820 h480 +0x02000000", tabTitles)
    
    ; 核心机制：为每个 Tab 页面添加属于它自己的子控件
    ; 在 AutoHotkey v2 中，Tab 内部控件坐标同样基于 GUI Client 窗口坐标系
    for tabIdx, tab in ImeTabList {
        MainTabCtrl.UseTab(tabIdx)
        
        ; 状态与信息提示（位于 Tab 内部顶部行：y=92）
        hklText := T("ime_info", tab.hklHex, tab.hkl & 0xFFFF, tab.apps.Count)
        tab.txtInfo := ConfigGui.Add("Text", "x35 y92 w415 h20", hklText)
        
        ; 工具栏操作按钮（位于 Tab 内部顶部行：y=88）
        tab.btnCapture := ConfigGui.Add("Button", "x455 y88 w130 h28", T("btn_capture"))
        tab.btnCapture.OnEvent("Click", StartWindowCapture.Bind(tabIdx))
        
        tab.btnBrowse := ConfigGui.Add("Button", "x595 y88 w110 h28", T("btn_browse"))
        tab.btnBrowse.OnEvent("Click", BrowseAndAddExe.Bind(tabIdx))
        
        tab.btnAddManual := ConfigGui.Add("Button", "x715 y88 w110 h28", T("btn_manual"))
        tab.btnAddManual.OnEvent("Click", ManualAddExe.Bind(tabIdx))
        
        ; ListView 列表控件（位于 Tab 内部中间主体区域：y=122, h=363）
        lv := ConfigGui.Add("ListView", "x35 y122 w790 h363 Grid +LV0x10000", [T("col_num"), T("col_exe"), T("col_desc")])
        lv.ModifyCol(1, "50 Center Integer")
        lv.ModifyCol(2, "220")
        lv.ModifyCol(3, "490")
        tab.lvControl := lv
        
        ; 填充当前 Tab 的数据
        RefreshTabListView(tabIdx)
        
        ; Tab 面板底部操作按钮（位于 Tab 内部底部行：y=493, h=30）
        tab.btnDel := ConfigGui.Add("Button", "x35 y493 w130 h30", T("btn_delete"))
        tab.btnDel.OnEvent("Click", DeleteSelectedExe.Bind(tabIdx))
        
        tab.btnClear := ConfigGui.Add("Button", "x175 y493 w140 h30", T("btn_clear"))
        tab.btnClear.OnEvent("Click", ClearTabExes.Bind(tabIdx))
    }
    
    MainTabCtrl.UseTab() ; 退出 Tab 控制域
    MainTabCtrl.OnEvent("Change", OnTabChange)
        
    ; 窗口全局功能底栏（位于 Tab3 外部下方，y=552，绝不被 Tab 外边框遮挡！）
    chkDebugCtrl := ConfigGui.Add("Checkbox", "x25 y554 w230 h26", T("chk_debug"))
    chkDebugCtrl.Value := DEBUG_MODE ? 1 : 0
    chkDebugCtrl.OnEvent("Click", OnGuiDebugToggle)
    
    chkStartupCtrl := ConfigGui.Add("Checkbox", "x265 y554 w190 h26", T("chk_startup"))
    chkStartupCtrl.Value := FileExist(AutoStartLnk) ? 1 : 0
    chkStartupCtrl.OnEvent("Click", (chk, *) => ToggleAutoStart(chk.Value))
    
    btnRefreshImeCtrl := ConfigGui.Add("Button", "x465 y552 w135 h32", T("btn_refresh_ime"))
    btnRefreshImeCtrl.OnEvent("Click", (*) => ReloadSystemImes())
    
    btnSaveCtrl := ConfigGui.Add("Button", "x610 y552 w130 h32 Default", T("btn_save"))
    btnSaveCtrl.OnEvent("Click", (*) => SaveFromGui())
    
    btnCloseCtrl := ConfigGui.Add("Button", "x750 y552 w90 h32", T("btn_minimize"))
    btnCloseCtrl.OnEvent("Click", (*) => ConfigGui.Hide())
    
    ; 绑定窗口关闭事件（最小化到托盘）
    ConfigGui.OnEvent("Close", (*) => ConfigGui.Hide())
    
    ConfigGui.Show("w860 h600")
    
    ; 为 Tab3 内部承载对话框 (#32770) 设置 WS_CLIPCHILDREN，杜绝背景擦除白屏
    childList := WinGetControlsHwnd(ConfigGui.Hwnd)
    for h in childList {
        if (WinGetClass(h) == "#32770") {
            WinSetStyle("+0x02000000", h)
            break
        }
    }
    
    ; 核心修复：彻底解决 Win32 Tab3 首屏及刷新输入法后的白屏渲染 Bug
    ; 在窗口完全呈现 (Show) 之后执行 Tab 激活与切换，唤醒底层子对话框的重绘管道
    if (tabTitles.Length > 1) {
        tempTab := (defaultTabIdx == 1) ? 2 : 1
        MainTabCtrl.Value := tempTab
        MainTabCtrl.Value := defaultTabIdx
    } else if (tabTitles.Length == 1) {
        MainTabCtrl.Value := defaultTabIdx
    }
    
    ; 确保当前活动 Tab 列表及全窗重绘
    RefreshTabListView(defaultTabIdx)
    WinRedraw("ahk_id " . ConfigGui.Hwnd)
}

; Tab 切换事件：确保目标页控件获得有效绘制激活
OnTabChange(tabCtrl, *) {
    global ImeTabList
    curTab := tabCtrl.Value
    if (curTab >= 1 && curTab <= ImeTabList.Length) {
        tab := ImeTabList[curTab]
        if (tab.lvControl) {
            tab.lvControl.Opt("+Redraw")
        }
    }
}

; 语言下拉框切换处理
OnLanguageSelectChange(ctrl, *) {
    global CurrentLang, AvailableLangs, ConfigFile
    choice := ctrl.Value
    if (choice >= 1 && choice <= AvailableLangs.Length) {
        newLang := AvailableLangs[choice].code
        if (newLang != CurrentLang) {
            CurrentLang := newLang
            try IniWrite(CurrentLang, ConfigFile, "Settings", "Language")
            LoadLanguage(CurrentLang)
            InitTrayMenu()
            RefreshGuiLanguage()
        }
    }
}

RefreshGuiLanguage() {
    global ConfigGui, MainTabCtrl
    savedTab := 1
    if (IsSet(MainTabCtrl) && MainTabCtrl)
        savedTab := MainTabCtrl.Value
    if (IsSet(ConfigGui) && ConfigGui) {
        ConfigGui.Destroy()
        ConfigGui := unset
    }
    ShowConfigGui(savedTab)
}

OnGuiDebugToggle(chk, *) {
    global DEBUG_MODE
    DEBUG_MODE := chk.Value
    try IniWrite(DEBUG_MODE ? "1" : "0", ConfigFile, "Settings", "DebugMode")
    UpdateTrayMenuChecks()
}

; 刷新指定 Tab 的 ListView
RefreshTabListView(tabIdx) {
    global ImeTabList
    if (tabIdx < 1 || tabIdx > ImeTabList.Length)
        return
    tab := ImeTabList[tabIdx]
    if !tab.lvControl
        return
    
    tab.lvControl.Delete()
    tab.lvControl.Opt("-Redraw")
    idx := 1
    for proc, remark in tab.apps {
        tab.lvControl.Add("", idx, proc, remark)
        idx++
    }
    tab.lvControl.Opt("+Redraw")
    
    if (tab.txtInfo)
        tab.txtInfo.Text := T("ime_info", tab.hklHex, tab.hkl & 0xFFFF, tab.apps.Count)
}

; 从界面保存到 INI
SaveFromGui() {
    global ImeTabList
    for tab in ImeTabList {
        if !tab.lvControl
            continue
        newApps := Map()
        rowCount := tab.lvControl.GetCount()
        Loop rowCount {
            proc := StrLower(Trim(tab.lvControl.GetText(A_Index, 2)))
            remark := Trim(tab.lvControl.GetText(A_Index, 3))
            if (proc != "")
                newApps[proc] := remark
        }
        tab.apps := newApps
    }
    SaveConfig(true)
}

; 删除选中的程序
DeleteSelectedExe(tabIdx := 0, *) {
    global ImeTabList, MainTabCtrl
    if (!tabIdx && IsSet(MainTabCtrl))
        tabIdx := MainTabCtrl.Value
    if (tabIdx < 1 || tabIdx > ImeTabList.Length)
        return
    tab := ImeTabList[tabIdx]
    lv := tab.lvControl
    if !lv
        return
        
    rowNumber := 0
    delCount := 0
    while (rowNumber := lv.GetNext(rowNumber)) {
        proc := StrLower(lv.GetText(rowNumber, 2))
        if tab.apps.Has(proc)
            tab.apps.Delete(proc)
        delCount++
    }
    if (delCount > 0) {
        RefreshTabListView(tabIdx)
        SaveConfig(false)
        ToolTip(T("del_success"))
        SetTimer(() => ToolTip(), -1500)
    } else {
        MsgBox(T("del_select_hint"), "AutoIME", "Icon!")
    }
}

; 清空当前 Tab
ClearTabExes(tabIdx := 0, *) {
    global ImeTabList, MainTabCtrl
    if (!tabIdx && IsSet(MainTabCtrl))
        tabIdx := MainTabCtrl.Value
    if (tabIdx < 1 || tabIdx > ImeTabList.Length)
        return
    tab := ImeTabList[tabIdx]
    if (tab.apps.Count == 0)
        return
    ans := MsgBox(T("clear_confirm", tab.displayName), T("clear_title"), "YesNo Icon?")
    if (ans == "Yes") {
        tab.apps := Map()
        RefreshTabListView(tabIdx)
        SaveConfig(false)
    }
}

; 浏览 EXE 文件添加
BrowseAndAddExe(tabIdx := 0, *) {
    global ImeTabList, MainTabCtrl
    if (!tabIdx && IsSet(MainTabCtrl))
        tabIdx := MainTabCtrl.Value
    if (tabIdx < 1 || tabIdx > ImeTabList.Length)
        return
    tab := ImeTabList[tabIdx]
    selectedPath := FileSelect(1, , T("browse_title"), T("browse_filter"))
    if (selectedPath == "")
        return
    
    SplitPath(selectedPath, &outFileName, , , &outNameNoExt)
    procName := StrLower(outFileName)
    AddExeToTab(tabIdx, procName, outNameNoExt . " (" . selectedPath . ")")
}

; 手动输入添加
ManualAddExe(tabIdx := 0, *) {
    global ImeTabList, MainTabCtrl
    if (!tabIdx && IsSet(MainTabCtrl))
        tabIdx := MainTabCtrl.Value
    if (tabIdx < 1 || tabIdx > ImeTabList.Length)
        return
    tab := ImeTabList[tabIdx]
    ib := InputBox(T("manual_prompt"), T("manual_title"), "w380 h130")
    if (ib.Result != "OK" || Trim(ib.Value) == "")
        return
    
    procName := StrLower(Trim(ib.Value))
    if !InStr(procName, ".exe")
        procName .= ".exe"
        
    AddExeToTab(tabIdx, procName, T("manual_default_remark"))
}

; 添加程序到指定 Tab (含冲突检测)
AddExeToTab(tabIdx, procName, remark := "") {
    global ImeTabList, ConfigGui, MainTabCtrl
    if (tabIdx < 1 || tabIdx > ImeTabList.Length)
        return false
    currentTab := ImeTabList[tabIdx]
    
    if currentTab.apps.Has(procName) {
        MsgBox(T("already_in_tab", procName, currentTab.displayName), "AutoIME", "Icon!")
        return false
    }
    
    for idx, otherTab in ImeTabList {
        if (idx == tabIdx)
            continue
        if otherTab.apps.Has(procName) {
            ans := MsgBox(T("conflict_prompt", procName, otherTab.displayName, currentTab.displayName), T("conflict_title"), "YesNo Icon?")
            if (ans == "Yes") {
                otherTab.apps.Delete(procName)
                RefreshTabListView(idx)
            } else {
                return false
            }
            break
        }
    }
    
    currentTab.apps[procName] := remark
    RefreshTabListView(tabIdx)
    SaveConfig(false)
    
    if currentTab.lvControl {
        cnt := currentTab.lvControl.GetCount()
        currentTab.lvControl.Modify(cnt, "Select Focus Vis")
    }
    
    ToolTip(T("add_success", procName, currentTab.displayName))
    SetTimer(() => ToolTip(), -2000)
    return true
}

; ================== 9. 键盘组合键交互式设置弹窗 ==================

ShowHotkeySettingDialog(parentHwnd) {
    global CurrentHotkey, btnHotkeyCtrl
    
    dlg := Gui("+Owner" . parentHwnd . " +ToolWindow -MinimizeBox", T("hk_dialog_title"))
    dlg.SetFont("s9", "Microsoft YaHei UI")
    
    dlg.Add("Text", "x25 y15 w370 Center", T("hk_dialog_prompt"))
    
    ; 居中大号按键显示框
    tempHk := CurrentHotkey
    txtHkDisplay := dlg.Add("Text", "x30 y45 w360 h45 Center +0x200 BackgroundFFFFFF +Border", FormatHotkeyDisplay(tempHk))
    txtHkDisplay.SetFont("s13 bold", "Segoe UI")
    
    dlg.Add("Text", "x25 y100 w370 Center c666666", T("hk_dialog_help"))
    
    ; 确定、恢复默认、取消按钮
    btnOk := dlg.Add("Button", "x45 y145 w100 h32 Default", T("hk_dialog_confirm"))
    btnReset := dlg.Add("Button", "x155 y145 w125 h32", T("hk_dialog_reset"))
    btnCancel := dlg.Add("Button", "x290 y145 w85 h32", T("hk_dialog_cancel"))
    
    ; 键盘钩子实时捕获键盘组合键
    hkHook := InputHook("V L0")
    hkHook.KeyOpt("{All}", "N")
    hkHook.OnKeyDown := (ih, vk, sc) => OnKeyCapture(vk, sc)
    hkHook.Start()
    
    OnKeyCapture(vk, sc) {
        keyName := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
        if (keyName == "")
            return
        
        ; 忽略单独的修饰键触发
        if (keyName ~= "i)^(LControl|RControl|Control|LAlt|RAlt|Alt|LShift|RShift|Shift|LWin|RWin)$")
            return
            
        ; 按 Esc 直接取消
        if (keyName = "Escape") {
            CloseDialog()
            return
        }
        
        ; 按无修饰符的 Enter 直接确认
        mods := ""
        if (GetKeyState("LWin", "P") || GetKeyState("RWin", "P"))
            mods .= "#"
        if GetKeyState("Ctrl", "P")
            mods .= "^"
        if GetKeyState("Alt", "P")
            mods .= "!"
        if GetKeyState("Shift", "P")
            mods .= "+"
            
        if (mods == "" && keyName = "Enter") {
            ConfirmHotkey()
            return
        }
        
        newHk := mods . keyName
        tempHk := newHk
        txtHkDisplay.Text := FormatHotkeyDisplay(tempHk)
    }
    
    ConfirmHotkey(*) {
        hkHook.Stop()
        if (tempHk == "") {
            MsgBox(T("hk_dialog_empty"), "AutoIME", "Icon!")
            return
        }
        success := ApplyHotkey(tempHk, true)
        if (success) {
            if (IsSet(btnHotkeyCtrl) && btnHotkeyCtrl)
                btnHotkeyCtrl.Text := "⌨️ " . FormatHotkeyDisplay(CurrentHotkey)
            dlg.Destroy()
        }
    }
    
    ResetHotkey(*) {
        tempHk := "^!i"
        txtHkDisplay.Text := FormatHotkeyDisplay(tempHk)
    }
    
    CloseDialog(*) {
        hkHook.Stop()
        dlg.Destroy()
    }
    
    btnOk.OnEvent("Click", ConfirmHotkey)
    btnReset.OnEvent("Click", ResetHotkey)
    btnCancel.OnEvent("Click", CloseDialog)
    dlg.OnEvent("Close", CloseDialog)
    
    dlg.Show("w420 h195 Center")
}

; ================== 10. 窗口捕获模式实现 ==================

StartWindowCapture(tabIdx := 0, *) {
    global isCapturing, captureTab, ConfigGui, MainTabCtrl
    if isCapturing
        return
    if (!tabIdx && IsSet(MainTabCtrl))
        tabIdx := MainTabCtrl.Value
    if (tabIdx < 1 || tabIdx > ImeTabList.Length)
        return
        
    isCapturing := true
    captureTab := tabIdx
    
    if (IsSet(ConfigGui) && ConfigGui)
        ConfigGui.Minimize()
    
    SetTimer(WatchCaptureMouse, 40)
    
    Hotkey("~LButton", OnCaptureClick, "On")
    Hotkey("Space", OnCaptureConfirmKey, "On")
    Hotkey("Enter", OnCaptureConfirmKey, "On")
    Hotkey("F8", OnCaptureConfirmKey, "On")
    Hotkey("Escape", OnCaptureCancelKey, "On")
}

StopWindowCapture() {
    global isCapturing
    if !isCapturing
        return
    isCapturing := false
    SetTimer(WatchCaptureMouse, 0)
    ToolTip()
    
    try Hotkey("~LButton", "Off")
    try Hotkey("Space", "Off")
    try Hotkey("Enter", "Off")
    try Hotkey("F8", "Off")
    try Hotkey("Escape", "Off")
}

WatchCaptureMouse() {
    global isCapturing, ConfigGui, ImeTabList, captureTab
    if !isCapturing
        return
    
    MouseGetPos(&mX, &mY, &mHwnd)
    if !mHwnd
        return
        
    try {
        proc := StrLower(WinGetProcessName(mHwnd))
        title := WinGetTitle(mHwnd)
        if (StrLen(title) > 35)
            title := SubStr(title, 1, 35) . "..."
            
        targetTabName := ImeTabList[captureTab].displayName
        
        infoTip := T("capture_mode_title") . "`n"
                .  T("capture_target_ime", targetTabName) . "`n"
                .  "-----------------------------------`n"
                .  T("capture_hover_proc", proc) . "`n"
                .  T("capture_hover_title", (title != "" ? title : T("capture_no_title"))) . "`n"
                .  "-----------------------------------`n"
                .  T("capture_hint_confirm") . "`n"
                .  T("capture_hint_cancel")
        
        ToolTip(infoTip, mX + 16, mY + 16)
    } catch {
        ToolTip(T("capture_scanning"), mX + 16, mY + 16)
    }
}

OnCaptureClick(ThisHotkey) {
    Sleep(60)
    ConfirmCapturedWindow()
}

OnCaptureConfirmKey(ThisHotkey) {
    ConfirmCapturedWindow()
}

ConfirmCapturedWindow() {
    global captureTab, ConfigGui
    MouseGetPos(&mX, &mY, &mHwnd)
    StopWindowCapture()
    
    if (IsSet(ConfigGui) && ConfigGui) {
        ConfigGui.Restore()
        ConfigGui.Show()
        WinActivate("ahk_id " . ConfigGui.Hwnd)
    }
    
    if !mHwnd {
        MsgBox(T("capture_invalid"), "AutoIME", "Icon!")
        return
    }
    
    if (IsSet(ConfigGui) && ConfigGui && mHwnd == ConfigGui.Hwnd) {
        MsgBox(T("capture_self_window"), "AutoIME", "Icon!")
        return
    }
    
    try {
        proc := StrLower(WinGetProcessName(mHwnd))
        title := WinGetTitle(mHwnd)
        if (proc == "") {
            MsgBox(T("capture_failed_proc"), T("capture_failed_title"), "Icon!")
            return
        }
        
        AddExeToTab(captureTab, proc, title)
    } catch as err {
        MsgBox(err.Message, T("capture_failed_title"), "Iconx")
    }
}

OnCaptureCancelKey(ThisHotkey) {
    global ConfigGui
    StopWindowCapture()
    if (IsSet(ConfigGui) && ConfigGui) {
        ConfigGui.Restore()
        ConfigGui.Show()
        WinActivate("ahk_id " . ConfigGui.Hwnd)
    }
    ToolTip(T("capture_cancelled"))
    SetTimer(() => ToolTip(), -1500)
}

; ================== 11. 辅助功能与自启动 ==================

ToggleAutoStart(enable) {
    global AutoStartLnk, chkStartupCtrl
    try {
        if (enable) {
            FileCreateShortcut(A_ScriptFullPath, AutoStartLnk, A_ScriptDir, , "AutoIME")
            ToolTip(T("startup_enabled"))
        } else {
            if FileExist(AutoStartLnk)
                FileDelete(AutoStartLnk)
            ToolTip(T("startup_disabled"))
        }
        UpdateTrayMenuChecks()
        if (IsSet(chkStartupCtrl) && chkStartupCtrl)
            chkStartupCtrl.Value := FileExist(AutoStartLnk) ? 1 : 0
        SetTimer(() => ToolTip(), -1500)
    } catch as err {
        MsgBox(T("startup_failed", err.Message), "AutoIME", "Iconx")
    }
}

ReloadSystemImes() {
    global ConfigGui, MainTabCtrl, ImeTabList
    savedTab := 1
    if (IsSet(MainTabCtrl) && MainTabCtrl) {
        try savedTab := MainTabCtrl.Value
    }
    LoadConfig()
    if (IsSet(ConfigGui) && ConfigGui) {
        ConfigGui.Destroy()
        ConfigGui := unset
    }
    if (savedTab < 1 || savedTab > ImeTabList.Length)
        savedTab := 1
    ShowConfigGui(savedTab)
    ToolTip(T("ime_reloaded"))
    SetTimer(() => ToolTip(), -1500)
}

; ================== 12. 托盘菜单与交互 (支持 Checkmark 勾选标志) ==================

InitTrayMenu() {
    global TrayItem_Open, TrayItem_Reload, TrayItem_Debug, TrayItem_AutoStart, TrayItem_Github, TrayItem_Restart, TrayItem_Exit, CurrentHotkey
    global PROJECT_URL
    
    TrayItem_Open      := T("tray_open_config", FormatHotkeyDisplay(CurrentHotkey))
    TrayItem_Reload    := T("tray_reload_config")
    TrayItem_Debug     := T("tray_toggle_debug")
    TrayItem_AutoStart := T("tray_toggle_startup")
    TrayItem_Github    := T("tray_github")
    TrayItem_Restart   := T("tray_restart")
    TrayItem_Exit      := T("tray_exit")
    
    A_TrayMenu.Delete()
    A_TrayMenu.Add(TrayItem_Open, (*) => ShowConfigGui())
    A_TrayMenu.Default := TrayItem_Open
    A_TrayMenu.Add()
    A_TrayMenu.Add(TrayItem_Reload, (*) => (LoadConfig(), ToolTip(T("save_success")), SetTimer(() => ToolTip(), -1500)))
    
    ; 切换开关菜单项（带激活勾选标记）
    A_TrayMenu.Add(TrayItem_Debug, ToggleDebugFromTray)
    A_TrayMenu.Add(TrayItem_AutoStart, ToggleAutoStartFromTray)
    
    A_TrayMenu.Add()
    A_TrayMenu.Add(TrayItem_Github, (*) => Run(PROJECT_URL))
    A_TrayMenu.Add()
    A_TrayMenu.Add(TrayItem_Restart, (*) => Reload())
    A_TrayMenu.Add(TrayItem_Exit, (*) => ExitApp())
    
    UpdateTrayMenuChecks()
}

; 更新托盘菜单勾选标志 (✓)
UpdateTrayMenuChecks() {
    global TrayItem_Debug, TrayItem_AutoStart, DEBUG_MODE, AutoStartLnk
    try {
        if (DEBUG_MODE)
            A_TrayMenu.Check(TrayItem_Debug)
        else
            A_TrayMenu.Uncheck(TrayItem_Debug)
            
        if (FileExist(AutoStartLnk))
            A_TrayMenu.Check(TrayItem_AutoStart)
        else
            A_TrayMenu.Uncheck(TrayItem_AutoStart)
    }
}

ToggleDebugFromTray(ItemName, ItemPos, MyMenu) {
    global DEBUG_MODE, chkDebugCtrl, ConfigFile
    DEBUG_MODE := !DEBUG_MODE
    try IniWrite(DEBUG_MODE ? "1" : "0", ConfigFile, "Settings", "DebugMode")
    UpdateTrayMenuChecks()
    if (IsSet(chkDebugCtrl) && chkDebugCtrl)
        chkDebugCtrl.Value := DEBUG_MODE ? 1 : 0
    ToolTip(DEBUG_MODE ? T("debug_enabled") : T("debug_disabled"))
    SetTimer(() => ToolTip(), -1500)
}

ToggleAutoStartFromTray(ItemName, ItemPos, MyMenu) {
    global AutoStartLnk
    isAuto := FileExist(AutoStartLnk)
    ToggleAutoStart(!isAuto)
}
