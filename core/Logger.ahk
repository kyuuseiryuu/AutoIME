#Requires AutoHotkey v2.0

; ==============================================================================
; AutoIME - 调试日志辅助模块
; ==============================================================================

LogMessage(msg, showToolTip := true) {
    global DEBUG_MODE, LOG_FILE
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

