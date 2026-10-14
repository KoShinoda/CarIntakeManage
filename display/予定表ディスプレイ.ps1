<#
  予定表ウェブアプリを指定モニターにキオスク（全画面）表示する。
  表示・初回ログイン・起動時の登録・解除をまとめた本体。

  （引数なし）  修理入庫予定表を全画面表示
  -App general  一般修理管理表を全画面表示
  -Monitor 1    表示するモニター番号。省略時は縦向きのモニター、なければメイン
  -Setup        初回の Google ログイン用に通常ウィンドウで開く
  -Install      起動時の表示とデスクトップのショートカットを登録する
  -Remove       登録したショートカットと表示専用の Chrome プロファイルを消す
  -List         モニター一覧を表示する

  全画面表示は Alt+F4 で閉じる。
#>
param(
  [ValidateSet('repair', 'general')]
  [string]$App = 'repair',
  [int]$Monitor = -1,
  [switch]$Setup,
  [switch]$Install,
  [switch]$Remove,
  [switch]$List
)

$urls = @{
  repair  = 'https://script.google.com/macros/s/AKfycby8UhzZe_RrUCtFSpTdAtV9QzggMmKUWiywaVaU3jW6dX2hMg7E6-6xHl6MUVomJwfDCw/exec'
  general = 'https://script.google.com/macros/s/AKfycbwskwjtX9e6CjmhP6tgMUuWNLWKbVAEb55EL_QnW7CsEkiVh9aipEt4BjMAXi0heTWhdQ/exec'
}

# 普段使いの Chrome と分けるため、表示専用のプロファイルを使う
$profileName = 'RepairBoardChrome'
$profileDir = Join-Path $env:LOCALAPPDATA $profileName

Add-Type -AssemblyName System.Windows.Forms
$screens = [System.Windows.Forms.Screen]::AllScreens

function Get-TargetScreen {
  if ($Monitor -ge 0 -and $Monitor -lt $screens.Length) { return $screens[$Monitor] }
  $portrait = $screens | Where-Object { $_.Bounds.Height -gt $_.Bounds.Width } | Select-Object -First 1
  if ($portrait) { return $portrait }
  return [System.Windows.Forms.Screen]::PrimaryScreen
}

function Show-Screens {
  $target = Get-TargetScreen
  for ($i = 0; $i -lt $screens.Length; $i++) {
    $s = $screens[$i]
    $mark = ''
    if ($s.Primary) { $mark += '（メイン）' }
    if ($s.DeviceName -eq $target.DeviceName) { $mark += ' ← 表示先' }
    '  {0}: {1}x{2}  位置 {3},{4} {5}' -f $i, $s.Bounds.Width, $s.Bounds.Height, $s.Bounds.X, $s.Bounds.Y, $mark
  }
}

function Stop-BoardChrome {
  Get-CimInstance Win32_Process -Filter "Name = 'chrome.exe'" |
    Where-Object { $_.CommandLine -like "*$profileName*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

function Get-Links {
  $startup = [Environment]::GetFolderPath('Startup')
  $desktop = [Environment]::GetFolderPath('Desktop')
  @(
    @{ Path = Join-Path $startup '予定表ディスプレイ.lnk'; App = 'repair' },
    @{ Path = Join-Path $desktop '修理入庫予定表を表示.lnk'; App = 'repair' },
    @{ Path = Join-Path $desktop '一般修理管理表を表示.lnk'; App = 'general' }
  )
}

if ($List) {
  'モニター一覧'
  Show-Screens
  return
}

if ($Install) {
  $powershell = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
  $shell = New-Object -ComObject WScript.Shell
  foreach ($link in Get-Links) {
    $arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`" -App $($link.App)"
    if ($Monitor -ge 0) { $arguments += " -Monitor $Monitor" }
    $shortcut = $shell.CreateShortcut($link.Path)
    $shortcut.TargetPath = $powershell
    $shortcut.Arguments = $arguments
    $shortcut.WorkingDirectory = $PSScriptRoot
    $shortcut.WindowStyle = 7
    $shortcut.Save()
  }
  '起動時の表示を登録しました'
  '  スタートアップ: 予定表ディスプレイ'
  '  デスクトップ  : 修理入庫予定表を表示 / 一般修理管理表を表示'
  ''
  'モニター一覧'
  Show-Screens
  return
}

if ($Remove) {
  Get-Links | ForEach-Object { Remove-Item $_.Path -ErrorAction SilentlyContinue }
  Stop-BoardChrome
  Start-Sleep -Seconds 2
  Remove-Item -Recurse -Force $profileDir -ErrorAction SilentlyContinue
  '登録を解除しました'
  '  ショートカット3つと、表示専用の Chrome プロファイルを消しました'
  return
}

$target = Get-TargetScreen

$chrome = @(
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
  "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $chrome) { throw 'Google Chrome が見つかりません' }

Stop-BoardChrome

if (-not $Setup) {
  # 起動直後はネットワークがまだ無いことがあるので、最大2分待つ
  for ($i = 0; $i -lt 60; $i++) {
    try {
      [System.Net.Dns]::GetHostAddresses('script.google.com') | Out-Null
      break
    } catch {
      Start-Sleep -Seconds 2
    }
  }
}

$chromeArgs = @(
  "--user-data-dir=`"$profileDir`"",
  '--no-first-run',
  '--no-default-browser-check',
  '--disable-session-crashed-bubble',
  '--noerrdialogs',
  "--window-position=$($target.Bounds.X + 50),$($target.Bounds.Y + 50)"
)

if ($Setup) {
  $chromeArgs += @('--new-window', $urls[$App])
} else {
  $chromeArgs += @('--kiosk', $urls[$App])
}

Start-Process -FilePath $chrome -ArgumentList $chromeArgs
