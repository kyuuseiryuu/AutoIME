$ErrorActionPreference = 'Stop'

$rootDir = Split-Path -Parent $PSScriptRoot
$libDir = Join-Path $rootDir "lib\WebView2"
$dll64 = Join-Path $libDir "64bit\WebView2Loader.dll"
$dll32 = Join-Path $libDir "32bit\WebView2Loader.dll"

if ((Test-Path $dll64) -and (Test-Path $dll32)) {
    Write-Host "✅ WebView2Loader.dll already present in lib\WebView2"
    exit 0
}

Write-Host "📥 Downloading WebView2Loader.dll from Microsoft.Web.WebView2 NuGet package..."

if (-not (Test-Path (Join-Path $libDir "64bit"))) { New-Item -ItemType Directory -Path (Join-Path $libDir "64bit") -Force | Out-Null }
if (-not (Test-Path (Join-Path $libDir "32bit"))) { New-Item -ItemType Directory -Path (Join-Path $libDir "32bit") -Force | Out-Null }

$url = 'https://www.nuget.org/api/v2/package/Microsoft.Web.WebView2'
$tempZip = [System.IO.Path]::GetTempFileName() + '.zip'
$extractDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString())

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
    Invoke-WebRequest -Uri $url -OutFile $tempZip -UseBasicParsing
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $extractDir)
    
    $src64 = Join-Path $extractDir 'build\native\x64\WebView2Loader.dll'
    $src32 = Join-Path $extractDir 'build\native\x86\WebView2Loader.dll'
    
    if (Test-Path $src64) {
        Copy-Item -Path $src64 -Destination $dll64 -Force
        Write-Host "✅ Installed 64-bit WebView2Loader.dll to $dll64"
    }
    if (Test-Path $src32) {
        Copy-Item -Path $src32 -Destination $dll32 -Force
        Write-Host "✅ Installed 32-bit WebView2Loader.dll to $dll32"
    }
}
finally {
    if (Test-Path $tempZip) { Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue }
    if (Test-Path $extractDir) { Remove-Item -Path $extractDir -Recurse -Force -ErrorAction SilentlyContinue }
}

