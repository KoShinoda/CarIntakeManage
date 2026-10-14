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

# 普段使いのブラウザと分けるため、表示専用のプロファイルを使う
$profileName = 'RepairBoardChrome'
$profileDir = Join-Path $env:LOCALAPPDATA $profileName
$logPath = Join-Path $PSScriptRoot '実行ログ.txt'

function Write-BoardLog {
  param([string]$Message)
  $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
  Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
}

Add-Type -AssemblyName System.Windows.Forms

# バッチやショートカットからはウィンドウなしで動くので、失敗したらログとダイアログで知らせる
$ErrorActionPreference = 'Stop'
trap {
  $text = $_.Exception.Message
  try { Write-BoardLog "エラー: $text" } catch { }
  [System.Windows.Forms.MessageBox]::Show(
    "予定表ディスプレイでエラーが発生しました。`n`n$text`n`n詳しくは $logPath",
    '予定表ディスプレイ', 'OK', 'Error') | Out-Null
  exit 1
}

Write-BoardLog ('開始 App={0} Setup={1} Install={2} Remove={3} Monitor={4} User={5}' -f $App, $Setup, $Install, $Remove, $Monitor, $env:USERNAME)

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

function Stop-BoardBrowser {
  Get-CimInstance Win32_Process -Filter "Name = 'chrome.exe' OR Name = 'msedge.exe'" |
    Where-Object { $_.CommandLine -like "*$profileName*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

# Chrome を優先し、無ければ Edge を使う
function Find-Browser {
  $candidates = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
  )
  foreach ($key in @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe'
  )) {
    $item = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
    if ($item -and $item.'(default)') { $candidates += $item.'(default)' }
  }
  $candidates += @(
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
  )
  $candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
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
  Write-BoardLog '登録しました'
  return
}

if ($Remove) {
  Get-Links | ForEach-Object { Remove-Item $_.Path -ErrorAction SilentlyContinue }
  Stop-BoardBrowser
  Start-Sleep -Seconds 2
  Remove-Item -Recurse -Force $profileDir -ErrorAction SilentlyContinue
  '登録を解除しました'
  '  ショートカット3つと、表示専用のブラウザのプロファイルを消しました'
  Write-BoardLog '解除しました'
  return
}

$target = Get-TargetScreen

$browser = Find-Browser
if (-not $browser) { throw 'Google Chrome も Microsoft Edge も見つかりません。どちらかをインストールしてください。' }
Write-BoardLog "ブラウザ: $browser"

Stop-BoardBrowser

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

$browserArgs = @(
  "--user-data-dir=`"$profileDir`"",
  '--no-first-run',
  '--no-default-browser-check',
  '--disable-session-crashed-bubble',
  '--noerrdialogs',
  "--window-position=$($target.Bounds.X + 50),$($target.Bounds.Y + 50)"
)

if ($Setup) {
  $browserArgs += @('--new-window', $urls[$App])
} else {
  $browserArgs += @('--kiosk', $urls[$App])
}

Start-Process -FilePath $browser -ArgumentList $browserArgs
Write-BoardLog ('起動しました Setup={0} URL={1}' -f $Setup, $urls[$App])
