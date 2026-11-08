#Requires AutoHotkey v2.0

; ==============================================================================
; AutoIME - 键盘组合键交互式设置弹窗
; ==============================================================================

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
