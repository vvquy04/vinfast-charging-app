param(
  [string]$Version = "2.0.1"
)

$ErrorActionPreference = "Stop"

$packageRoot = Join-Path $env:LOCALAPPDATA "Pub\Cache\hosted\pub.dev\trackasia_gl_web-$Version"
$entryFile = Join-Path $packageRoot "lib\trackasia_gl_web.dart"
$platformFile = Join-Path $packageRoot "lib\src\trackasia_web_gl_platform.dart"

if (-not (Test-Path $entryFile) -or -not (Test-Path $platformFile)) {
  throw "trackasia_gl_web-$Version not found in pub cache at: $packageRoot"
}

$entryContent = Get-Content -Path $entryFile -Raw
if ($entryContent -notmatch "dart:ui_web") {
  $entryContent = $entryContent -replace "import 'dart:ui' as ui;", "import 'dart:ui' as ui;`r`nimport 'dart:ui_web' as ui_web;"
  Set-Content -Path $entryFile -Value $entryContent
}

$platformContent = Get-Content -Path $platformFile -Raw
$patchedPlatformContent = $platformContent -replace "ui\.platformViewRegistry", "ui_web.platformViewRegistry"
if ($patchedPlatformContent -ne $platformContent) {
  Set-Content -Path $platformFile -Value $patchedPlatformContent
}

Write-Output "Patched trackasia_gl_web-$Version for current Flutter web platformViewRegistry API."
