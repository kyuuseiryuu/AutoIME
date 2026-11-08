#Requires AutoHotkey v2.0

; ==============================================================================
; AutoIME - 配置管理模块 (INI 读写、规则持久化与热键管理)
; ==============================================================================

LoadConfig() {
    global SystemImes, AppToImeMap, ImeTabList, DEBUG_MODE, CurrentLang, CurrentHotkey, ConfigFile, AvailableLangs
    
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
    global ImeTabList, AppToImeMap, DEBUG_MODE, CurrentLang, CurrentHotkey, ConfigFile
    
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
    global CurrentHotkey, ConfigFile
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

