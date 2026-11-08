#Requires AutoHotkey v2.0

; ==============================================================================
; AutoIME - 托盘菜单与交互 (支持 Checkmark 勾选标志与自启动)
; ==============================================================================

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
