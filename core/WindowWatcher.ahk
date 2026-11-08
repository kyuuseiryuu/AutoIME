#Requires AutoHotkey v2.0

; ==============================================================================
; AutoIME - 窗口切换监听与输入法自动激活 (WinEventHook 事件驱动)
; ==============================================================================

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

