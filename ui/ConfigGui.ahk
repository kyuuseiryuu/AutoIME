#Requires AutoHotkey v2.0

; ==============================================================================
; AutoIME - 现代 WebView2 核心配置界面
; 基于 Microsoft Edge WebView2 (Chromium) 打造现代化、高颜值配置交互
; ==============================================================================

#Include "..\lib\WebView2\WebView2.ahk"
#Include "..\lib\JSON.ahk"

global ActiveHkHook := unset
global HostBridgeInstance := unset

ShowConfigGui(defaultTabIdx := 1) {
    global ConfigGui, wvController, wvCore, ImeTabList, DEBUG_MODE, HostBridgeInstance

    if (IsSet(ConfigGui) && ConfigGui) {
        ConfigGui.Restore()
        ConfigGui.Show()
        WinActivate("ahk_id " . ConfigGui.Hwnd)
        if (IsSet(wvController) && wvController) {
            wvController.IsVisible := 1
            wvController.Fill()
        }
        if (IsSet(wvCore) && wvCore) {
            try wvCore.ExecuteScriptAsync("window.app && window.app.switchTab(" . (defaultTabIdx - 1) . ")")
        }
        return
    }

    ; 创建主配置窗口并显示 (先呈现窗口以确保客户区尺寸有效计算)
    ConfigGui := Gui("+Resize -MaximizeBox", T("app_title"))
    ConfigGui.BackColor := "F8FAFC"
    ConfigGui.Show("w940 h660 Center")

    ; 注册窗口尺寸下限限制 (860 x 580)
    OnMessage(0x0024, OnGetMinMaxInfo)

    ; 初始化 WebView2 运行时 (独立缓存隔离目录，避免占用或污染用户配置)
    userDataDir := A_Temp . "\AutoIME_WebView2"
    if !DirExist(userDataDir)
        try DirCreate(userDataDir)

    wvc := WebView2.CreateControllerAsync(ConfigGui.Hwnd, 0, userDataDir).await2()
    wv := wvc.CoreWebView2

    wvController := wvc
    wvCore := wv

    ; 关键修复 1：显式激活 WebView2 控制器可见性与尺寸填充，杜绝未激活导致的白屏
    wvc.IsVisible := 1
    wvc.Fill()

    ; 配置 WebView2 行为与开发者选项
    wv.Settings.AreDevToolsEnabled := DEBUG_MODE ? 1 : 0
    wv.Settings.AreDefaultContextMenusEnabled := DEBUG_MODE ? 1 : 0
    wv.Settings.IsStatusBarEnabled := 0

    ; 关键修复 2：采用普通对象（而非类实例方法）注册通信桥梁，防止 COM IDispatch 丢失 this 报 Missing parameter
    HostBridgeInstance := CreateAutoImeHostBridge()
    wv.AddHostObjectToScript("ahk", HostBridgeInstance)

    ; 窗口尺寸改变时确保填满视口与保持可见
    ConfigGui.OnEvent("Size", (guiObj, minMax, w, h) => (
        minMax != -1 && IsSet(wvController) && wvController ? (wvController.IsVisible := 1, wvController.Fill()) : 0
    ))

    ; 窗口关闭时最小化到托盘
    ConfigGui.OnEvent("Close", (*) => ConfigGui.Hide())

    ; 加载本地现代 HTML 界面
    htmlPath := A_ScriptDir . "\ui\html\index.html"
    wv.Navigate("file:///" . StrReplace(htmlPath, "\", "/"))
}

; 限制窗口最小缩放尺寸为 860x580
OnGetMinMaxInfo(wParam, lParam, msg, hwnd) {
    global ConfigGui
    if (IsSet(ConfigGui) && ConfigGui && hwnd == ConfigGui.Hwnd) {
        NumPut("int", 860, lParam, 24) ; ptMinTrackSize.x
        NumPut("int", 580, lParam, 28) ; ptMinTrackSize.y
    }
}

; ==============================================================================
; AHK 与 Web 前端双向互操作宿主桥梁函数组 (普通对象闭包封装)
; ==============================================================================

CreateAutoImeHostBridge() {
    return {
        GetInitialDataJson: () => Bridge_GetInitialDataJson(),
        SaveConfigJson: (jsonPayload) => Bridge_SaveConfigJson(jsonPayload),
        SyncStateToAhk: (jsonPayload) => Bridge_SyncStateToAhk(jsonPayload),
        ChangeLanguage: (code) => Bridge_ChangeLanguage(code),
        ToggleDebug: (val) => Bridge_ToggleDebug(val),
        ToggleStartup: (val) => Bridge_ToggleStartup(val),
        StartWindowCapture: (tabIdx) => Bridge_StartWindowCapture(tabIdx),
        BrowseExe: (tabIdx) => Bridge_BrowseExe(tabIdx),
        ReloadSystemImes: () => Bridge_ReloadSystemImes(),
        MinimizeWindow: () => Bridge_MinimizeWindow(),
        SetTheme: (themeMode) => Bridge_SetTheme(themeMode),
        StartHotkeyCapture: () => Bridge_StartHotkeyCapture(),
        StopHotkeyCapture: () => Bridge_StopHotkeyCapture(),
        ConfirmHotkey: (newHk) => Bridge_ConfirmHotkey(newHk),
        CheckForUpdates: () => Bridge_CheckForUpdates(),
        PerformUpdate: (downloadUrl) => Bridge_PerformUpdate(downloadUrl)
    }
}

Bridge_GetInitialDataJson() {
    global ImeTabList, CurrentLang, CurrentTheme, CurrentVersion, CurrentCommit, AvailableLangs, CurrentHotkey, DEBUG_MODE, AutoStartLnk, CurrentDict, FallbackDict

    systemImesData := []
    for tab in ImeTabList {
        appsList := []
        for proc, remark in tab.apps {
            appsList.Push({ exe: proc, remark: remark })
        }
        systemImesData.Push({
            hkl: tab.hkl,
            hklHex: tab.hklHex,
            displayName: tab.displayName,
            apps: appsList
        })
    }

    transMap := Map()
    for k, v in FallbackDict
        transMap[k] := v
    for k, v in CurrentDict
        transMap[k] := v

    data := {
        systemImes: systemImesData,
        currentLang: CurrentLang,
        theme: CurrentTheme,
        currentVersion: CurrentVersion,
        currentCommit: CurrentCommit,
        availableLangs: AvailableLangs,
        currentHotkey: CurrentHotkey,
        debugMode: DEBUG_MODE ? 1 : 0,
        autoStart: FileExist(AutoStartLnk) ? 1 : 0,
        translations: transMap
    }

    return JSON.stringify(data)
}

Bridge_CheckForUpdates() {
    updateRes := CheckForUpdatesOnline(true)
    return JSON.stringify(updateRes)
}

Bridge_PerformUpdate(downloadUrl) {
    ApplyOnlineUpdate(downloadUrl)
    return 1
}

Bridge_SetTheme(themeMode) {
    global CurrentTheme, ConfigFile
    CurrentTheme := themeMode
    try IniWrite(CurrentTheme, ConfigFile, "Settings", "Theme")
    return 1
}

Bridge_SaveConfigJson(jsonPayload) {
    global ImeTabList
    try {
        parsedImes := JSON.parse(jsonPayload)
        for item in parsedImes {
            hklHex := item["hklHex"]
            for tab in ImeTabList {
                if (tab.hklHex == hklHex) {
                    newApps := Map()
                    if item.Has("apps") {
                        for a in item["apps"] {
                            exe := StrLower(Trim(a["exe"]))
                            remark := Trim(a["remark"])
                            if (exe != "")
                                newApps[exe] := remark
                        }
                    }
                    tab.apps := newApps
                    break
                }
            }
        }
        SaveConfig(true)
        return 1
    } catch as err {
        return 0
    }
}

Bridge_SyncStateToAhk(jsonPayload) {
    global ImeTabList
    try {
        parsedImes := JSON.parse(jsonPayload)
        for item in parsedImes {
            hklHex := item["hklHex"]
            for tab in ImeTabList {
                if (tab.hklHex == hklHex) {
                    newApps := Map()
                    if item.Has("apps") {
                        for a in item["apps"] {
                            exe := StrLower(Trim(a["exe"]))
                            remark := Trim(a["remark"])
                            if (exe != "")
                                newApps[exe] := remark
                        }
                    }
                    tab.apps := newApps
                    break
                }
            }
        }
        SaveConfig(false)
        return 1
    } catch as err {
        return 0
    }
}

Bridge_ChangeLanguage(code) {
    global CurrentLang, AvailableLangs, ConfigFile
    for item in AvailableLangs {
        if (item.code == code) {
            CurrentLang := code
            try IniWrite(CurrentLang, ConfigFile, "Settings", "Language")
            LoadLanguage(CurrentLang)
            InitTrayMenu()
            return 1
        }
    }
    return 0
}

Bridge_ToggleDebug(val) {
    global DEBUG_MODE, ConfigFile
    DEBUG_MODE := !!val
    try IniWrite(DEBUG_MODE ? "1" : "0", ConfigFile, "Settings", "DebugMode")
    UpdateTrayMenuChecks()
    return 1
}

Bridge_ToggleStartup(val) {
    ToggleAutoStart(!!val)
    return 1
}

Bridge_StartWindowCapture(tabIdx) {
    StartWindowCapture(tabIdx)
}

Bridge_BrowseExe(tabIdx) {
    global ImeTabList
    if (tabIdx < 1 || tabIdx > ImeTabList.Length)
        return ""
    tab := ImeTabList[tabIdx]
    selectedPath := FileSelect(1, , T("browse_title"), T("browse_filter"))
    if (selectedPath == "")
        return ""

    SplitPath(selectedPath, &outFileName, , , &outNameNoExt)
    procName := StrLower(outFileName)
    remark := outNameNoExt . " (" . selectedPath . ")"
    AddExeToTab(tabIdx, procName, remark)
    return JSON.stringify({ exe: procName, remark: remark })
}

Bridge_ReloadSystemImes() {
    ReloadSystemImes()
}

Bridge_MinimizeWindow() {
    global ConfigGui
    if (IsSet(ConfigGui) && ConfigGui)
        ConfigGui.Hide()
}

Bridge_StartHotkeyCapture() {
    global ActiveHkHook, wvCore
    if (IsSet(ActiveHkHook) && ActiveHkHook)
        ActiveHkHook.Stop()

    ActiveHkHook := InputHook("V L0")
    ActiveHkHook.KeyOpt("{All}", "N")
    ActiveHkHook.OnKeyDown := (ih, vk, sc) => OnKeyCaptureHandler(vk, sc)
    ActiveHkHook.Start()
}

OnKeyCaptureHandler(vk, sc) {
    global wvCore
    keyName := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
    if (keyName == "")
        return

    if (keyName ~= "i)^(LControl|RControl|Control|LAlt|RAlt|Alt|LShift|RShift|Shift|LWin|RWin)$")
        return

    mods := ""
    if (GetKeyState("LWin", "P") || GetKeyState("RWin", "P"))
        mods .= "#"
    if GetKeyState("Ctrl", "P")
        mods .= "^"
    if GetKeyState("Alt", "P")
        mods .= "!"
    if GetKeyState("Shift", "P")
        mods .= "+"

    if (keyName = "Escape") {
        Bridge_StopHotkeyCapture()
        if (IsSet(wvCore) && wvCore)
            wvCore.ExecuteScriptAsync("window.app && window.app.closeHotkeyModal()")
        return
    }

    if (mods == "" && keyName = "Enter") {
        if (IsSet(wvCore) && wvCore)
            wvCore.ExecuteScriptAsync("window.app && window.app.confirmHotkey()")
        return
    }

    rawHk := mods . keyName
    displayHk := FormatHotkeyDisplay(rawHk)

    if (IsSet(wvCore) && wvCore) {
        wvCore.ExecuteScriptAsync("window.app && window.app.onKeyCaptured('" . displayHk . "', '" . rawHk . "')")
    }
}

Bridge_StopHotkeyCapture() {
    global ActiveHkHook
    if (IsSet(ActiveHkHook) && ActiveHkHook) {
        ActiveHkHook.Stop()
        ActiveHkHook := unset
    }
}

Bridge_ConfirmHotkey(newHk) {
    Bridge_StopHotkeyCapture()
    if (newHk == "")
        return 0
    return ApplyHotkey(newHk, true) ? 1 : 0
}

; ==============================================================================
; 辅助函数与向后兼容接口
; ==============================================================================

; 添加程序到指定 Tab (含冲突检测与前端视图同步)
AddExeToTab(tabIdx, procName, remark := "") {
    global ImeTabList, wvCore
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
            } else {
                return false
            }
            break
        }
    }

    currentTab.apps[procName] := remark
    SaveConfig(false)

    if (IsSet(wvCore) && wvCore) {
        escapedRemark := StrReplace(StrReplace(remark, "\", "\\"), "'", "\'")
        wvCore.ExecuteScriptAsync("window.app && window.app.onWindowCaptured(" . tabIdx . ", '" . procName . "', '" . escapedRemark . "')")
    }

    ToolTip(T("add_success", procName, currentTab.displayName))
    SetTimer(() => ToolTip(), -2000)
    return true
}

RefreshTabListView(tabIdx) {
    global wvCore
    if (IsSet(wvCore) && wvCore) {
        try wvCore.ExecuteScriptAsync("window.app && window.app.loadDataFromAhk()")
    }
}

SaveFromGui() {
    global wvCore
    if (IsSet(wvCore) && wvCore) {
        try wvCore.ExecuteScriptAsync("window.app && window.app.saveConfig()")
    }
}
