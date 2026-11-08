#Requires AutoHotkey v2.0

; ==============================================================================
; AutoIME - 在线更新与版本检测模块
; ==============================================================================

CheckForUpdatesOnline(isManual := true) {
    global CurrentVersion, CurrentCommit, GITHUB_REPO, GITHUB_API_URL

    res := {
        hasUpdate: false,
        currentVersion: CurrentVersion,
        currentCommit: CurrentCommit,
        latestVersion: CurrentVersion,
        latestCommit: CurrentCommit,
        message: "",
        downloadUrl: "",
        htmlUrl: "",
        error: ""
    }

    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.SetTimeouts(5000, 5000, 8000, 8000)

        ; 优先检测 GitHub Latest Release
        releaseUrl := GITHUB_API_URL . "/releases/latest"
        whr.Open("GET", releaseUrl, false)
        whr.SetRequestHeader("User-Agent", "AutoIME-App")
        whr.Send()

        if (whr.Status == 200) {
            data := JSON.parse(whr.ResponseText)
            tagName := data.Has("tag_name") ? data["tag_name"] : ""
            body := data.Has("body") ? data["body"] : ""
            htmlUrl := data.Has("html_url") ? data["html_url"] : ""

            downloadUrl := ""
            if data.Has("assets") && data["assets"].Length > 0 {
                for asset in data["assets"] {
                    if InStr(asset["name"], ".zip") {
                        downloadUrl := asset["browser_download_url"]
                        break
                    }
                }
            }
            if (downloadUrl == "" && data.Has("zipball_url"))
                downloadUrl := data["zipball_url"]

            ; 检查版本差异 (比较 tag_name 或 commit)
            if (tagName != "" && tagName != CurrentVersion && !InStr(tagName, CurrentCommit)) {
                res.hasUpdate := true
                res.latestVersion := tagName
                res.message := body
                res.downloadUrl := downloadUrl
                res.htmlUrl := htmlUrl
                return res
            }
        }

        ; 若无 Releases，降级检测 main 分支最新 Commit
        commitUrl := GITHUB_API_URL . "/commits/main"
        whr.Open("GET", commitUrl, false)
        whr.SetRequestHeader("User-Agent", "AutoIME-App")
        whr.Send()

        if (whr.Status == 200) {
            cData := JSON.parse(whr.ResponseText)
            remoteSha := cData.Has("sha") ? cData["sha"] : ""
            remoteShaShort := SubStr(remoteSha, 1, 7)
            cMsg := (cData.Has("commit") && cData["commit"].Has("message")) ? cData["commit"]["message"] : ""
            cHtml := cData.Has("html_url") ? cData["html_url"] : ""

            if (remoteShaShort != "" && remoteShaShort != CurrentCommit && CurrentCommit != "dev") {
                res.hasUpdate := true
                res.latestCommit := remoteShaShort
                res.message := cMsg
                res.downloadUrl := "https://github.com/" . GITHUB_REPO . "/archive/refs/heads/main.zip"
                res.htmlUrl := cHtml
                return res
            }
        }
    } catch as err {
        res.error := err.Message
    }

    return res
}

ApplyOnlineUpdate(downloadUrl := "") {
    global GITHUB_REPO
    if (downloadUrl == "")
        downloadUrl := "https://github.com/" . GITHUB_REPO . "/archive/refs/heads/main.zip"

    tempZip := A_Temp . "\AutoIME_update.zip"
    try FileDelete(tempZip)

    ; 1. 下载 zip 更新包
    try {
        Download(downloadUrl, tempZip)
    } catch as err {
        MsgBox("下载更新包失败: " . err.Message, "AutoIME 更新错误", "Iconx")
        return false
    }

    ; 2. 准备后台解压覆盖脚本并重启
    appDir := A_ScriptDir
    ahkExe := A_AhkPath
    mainAhk := appDir . "\AutoIME.ahk"

    psCmd := 'Start-Sleep -Seconds 1; '
        . '$zip = "' . tempZip . '"; '
        . '$extract = Join-Path $env:TEMP "AutoIME_extracted"; '
        . 'if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }; '
        . 'Expand-Archive -Path $zip -DestinationPath $extract -Force; '
        . '$sub = Get-ChildItem -Path $extract -Directory | Select-Object -First 1; '
        . '$src = if ($sub -and (Test-Path (Join-Path $sub.FullName "AutoIME.ahk"))) { $sub.FullName } else { $extract }; '
        . 'Get-ChildItem -Path $src -Exclude "AutoIME_config.ini", "*.log" | ForEach-Object { '
        . '    Copy-Item -Path $_.FullName -Destination "' . appDir . '" -Recurse -Force '
        . '}; '
        . 'Remove-Item $zip, $extract -Recurse -Force -ErrorAction SilentlyContinue; '
        . 'Start-Process -FilePath "' . ahkExe . '" -ArgumentList "' . mainAhk . '" -WorkingDirectory "' . appDir . '"'

    Run('powershell -NoProfile -WindowStyle Hidden -Command "' . psCmd . '"')
    ExitApp()
}

