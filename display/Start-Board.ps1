<#
  予定表ウェブアプリを指定モニターにキオスク（全画面）表示する。

  -App      repair = 修理入庫予定表（既定） / general = 一般修理管理表
  -Monitor  表示するモニター番号（-List で確認）。省略時は縦向きのモニター、なければメイン
  -Setup    初回の Google ログイン用に通常ウィンドウで開く
  -List     モニター一覧を表示して終了

  キオスク表示は Alt+F4 で閉じる。
#>
param(
  [ValidateSet('repair', 'general')]
  [string]$App = 'repair',
  [int]$Monitor = -1,
  [switch]$Setup,
  [switch]$List
)

$urls = @{
  repair  = 'https://script.google.com/macros/s/AKfycby8UhzZe_RrUCtFSpTdAtV9QzggMmKUWiywaVaU3jW6dX2hMg7E6-6xHl6MUVomJwfDCw/exec'
  general = 'https://script.google.com/macros/s/AKfycbwskwjtX9e6CjmhP6tgMUuWNLWKbVAEb55EL_QnW7CsEkiVh9aipEt4BjMAXi0heTWhdQ/exec'
}

Add-Type -AssemblyName System.Windows.Forms
$screens = [System.Windows.Forms.Screen]::AllScreens

if ($List) {
  for ($i = 0; $i -lt $screens.Length; $i++) {
    $s = $screens[$i]
    $mark = if ($s.Primary) { '（メイン）' } else { '' }
    '{0}: {1}x{2}  位置 {3},{4} {5}' -f $i, $s.Bounds.Width, $s.Bounds.Height, $s.Bounds.X, $s.Bounds.Y, $mark
  }
  return
}

if ($Monitor -ge 0 -and $Monitor -lt $screens.Length) {
  $target = $screens[$Monitor]
} else {
  $target = $screens | Where-Object { $_.Bounds.Height -gt $_.Bounds.Width } | Select-Object -First 1
  if (-not $target) { $target = [System.Windows.Forms.Screen]::PrimaryScreen }
}

$chrome = @(
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
  "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $chrome) { throw 'Google Chrome が見つかりません' }

# 普段使いの Chrome と分けるため、表示専用のプロファイルを使う
$profileName = 'RepairBoardChrome'
$profileDir = Join-Path $env:LOCALAPPDATA $profileName

Get-CimInstance Win32_Process -Filter "Name = 'chrome.exe'" |
  Where-Object { $_.CommandLine -like "*$profileName*" } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

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
