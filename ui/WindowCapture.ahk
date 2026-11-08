#Requires AutoHotkey v2.0

; ==============================================================================
; AutoIME - 窗口捕获模式实现
; ==============================================================================

StartWindowCapture(tabIdx := 0, *) {
    global isCapturing, captureTab, ConfigGui, MainTabCtrl, ImeTabList
    if isCapturing
        return
    if (!tabIdx && IsSet(MainTabCtrl) && MainTabCtrl)
        tabIdx := MainTabCtrl.Value
    if (tabIdx < 1 || tabIdx > ImeTabList.Length)
        tabIdx := 1
        
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

