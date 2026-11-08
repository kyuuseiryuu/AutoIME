#Requires AutoHotkey v2.0

; ==============================================================================
; AutoIME - 在线更新与版本检测模块 (基于 GitHub API 发布时间与 Tag/Commit 双重校验)
; ==============================================================================

CheckForUpdatesOnline(isManual := true) {
    global CurrentVersion, CurrentCommit, CurrentBuildTime, GITHUB_REPO, GITHUB_API_URL

    res := {
        hasUpdate: false,
        currentVersion: CurrentVersion,
        currentCommit: CurrentCommit,
        currentBuildTime: CurrentBuildTime,
        latestVersion: CurrentVersion,
        latestCommit: CurrentCommit,
        latestTime: "",
        message: "",
        downloadUrl: "",
        htmlUrl: "",
        error: ""
    }

    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.SetTimeouts(5000, 5000, 8000, 8000)

        ; 1. 优先检测 GitHub Latest Release (正式版本发布)
        releaseUrl := GITHUB_API_URL . "/releases/latest"
        whr.Open("GET", releaseUrl, false)
        whr.SetRequestHeader("User-Agent", "AutoIME-App")
        whr.Send()

        if (whr.Status == 200) {
            data := JSON.parse(whr.ResponseText)
            tagName := data.Has("tag_name") ? data["tag_name"] : ""
            body := data.Has("body") ? data["body"] : ""
            htmlUrl := data.Has("html_url") ? data["html_url"] : ""
            publishedAt := data.Has("published_at") ? data["published_at"] : (data.Has("created_at") ? data["created_at"] : "")

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
            if (downloadUrl == "" && tagName != "")
                downloadUrl := "https://github.com/" . GITHUB_REPO . "/archive/refs/tags/" . tagName . ".zip"

            ; 时间比对校验：若 Release 发布时间晚于本地构建时间，或 tag 名称更新
            isNewer := false
            if (publishedAt != "" && CurrentBuildTime != "") {
                isNewer := (publishedAt > CurrentBuildTime)
            } else if (tagName != "") {
                isNewer := (tagName != CurrentVersion && !InStr(tagName, CurrentCommit))
            }

            if (isNewer) {
                res.hasUpdate := true
                res.latestVersion := tagName
                res.latestTime := publishedAt
                res.message := body
                res.downloadUrl := downloadUrl
                res.htmlUrl := htmlUrl
                return res
            }
        }

        ; 2. 若无正式 Release，降级检测 main 分支最新 Commit 提交记录与时间
        commitUrl := GITHUB_API_URL . "/commits/main"
        whr.Open("GET", commitUrl, false)
        whr.SetRequestHeader("User-Agent", "AutoIME-App")
        whr.Send()

        if (whr.Status == 200) {
            cData := JSON.parse(whr.ResponseText)
            remoteSha := cData.Has("sha") ? cData["sha"] : ""
            remoteShaShort := SubStr(remoteSha, 1, 7)
            
            commitDate := ""
            if (cData.Has("commit") && cData["commit"].Has("committer") && cData["commit"]["committer"].Has("date"))
                commitDate := cData["commit"]["committer"]["date"]
            else if (cData.Has("commit") && cData["commit"].Has("author") && cData["commit"]["author"].Has("date"))
                commitDate := cData["commit"]["author"]["date"]

            cMsg := (cData.Has("commit") && cData["commit"].Has("message")) ? cData["commit"]["message"] : ""
            cHtml := cData.Has("html_url") ? cData["html_url"] : ""

            isNewer := false
            if (commitDate != "" && CurrentBuildTime != "") {
                isNewer := (commitDate > CurrentBuildTime)
            } else if (remoteShaShort != "") {
                isNewer := (remoteShaShort != CurrentCommit && CurrentCommit != "dev")
            }

            if (isNewer) {
                res.hasUpdate := true
                res.latestCommit := remoteShaShort
                res.latestTime := commitDate
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
