#Requires AutoHotkey v2.0

; ==============================================================================
; AutoIME - 国际化 (i18n) 语言管理器
; ==============================================================================

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
