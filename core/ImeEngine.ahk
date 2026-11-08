#Requires AutoHotkey v2.0

; ==============================================================================
; AutoIME - 系统输入法枚举与激活引擎
; ==============================================================================

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
