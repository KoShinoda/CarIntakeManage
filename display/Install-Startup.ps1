<#
  PC 起動時に予定表を表示するショートカットをスタートアップに登録する。
  あわせて、表示を切り替えるショートカットをデスクトップに置く。

  -App      起動時に出す表示。repair（既定） / general
  -Monitor  表示するモニター番号。省略時は縦向きのモニター
  -Remove   登録したショートカットを消す
#>
param(
  [ValidateSet('repair', 'general')]
  [string]$App = 'repair',
  [int]$Monitor = -1,
  [switch]$Remove
)

$startScript = Join-Path $PSScriptRoot 'Start-Board.ps1'
$powershell = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
$startup = [Environment]::GetFolderPath('Startup')
$desktop = [Environment]::GetFolderPath('Desktop')

$links = @(
  @{ Path = Join-Path $startup '予定表ディスプレイ.lnk'; App = $App },
  @{ Path = Join-Path $desktop '修理入庫予定表を表示.lnk'; App = 'repair' },
  @{ Path = Join-Path $desktop '一般修理管理表を表示.lnk'; App = 'general' }
)

if ($Remove) {
  $links | ForEach-Object { Remove-Item $_.Path -ErrorAction SilentlyContinue }
  '削除しました'
  return
}

$shell = New-Object -ComObject WScript.Shell
foreach ($link in $links) {
  $arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$startScript`" -App $($link.App)"
  if ($Monitor -ge 0) { $arguments += " -Monitor $Monitor" }
  $shortcut = $shell.CreateShortcut($link.Path)
  $shortcut.TargetPath = $powershell
  $shortcut.Arguments = $arguments
  $shortcut.WorkingDirectory = $PSScriptRoot
  $shortcut.WindowStyle = 7
  $shortcut.Save()
  "作成: $($link.Path)"
}
