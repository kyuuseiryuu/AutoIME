#Requires AutoHotkey v2.0

; ==============================================================================
; AutoIME - 配置界面 (原生 Tab 页控件架构与列表规则管理)
; ==============================================================================

ShowConfigGui(defaultTabIdx := 1) {
    global ConfigGui, MainTabCtrl, ImeTabList, DEBUG_MODE, CurrentLang, CurrentHotkey
    global txtTitleCtrl, txtHkLabelCtrl, btnHotkeyCtrl, txtLangLabelCtrl, ddlLangCtrl
    global chkDebugCtrl, chkStartupCtrl, btnRefreshImeCtrl, btnSaveCtrl, btnCloseCtrl
    global AvailableLangs, AutoStartLnk
    
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
    global DEBUG_MODE, ConfigFile
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
