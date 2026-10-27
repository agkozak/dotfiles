# vi editing mode
Set-PSReadLineOption -EditMode vi
Set-PSReadLineOption -ViModeIndicator Cursor

# Zsh-like conveniences
Set-PSReadLineOption -HistoryNoDuplicates -BellStyle None
Set-PSReadLineOption -PredictionSource History          # fish-style suggestions, 7.2+
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete  # zsh-style completion menu
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path $ChocolateyProfile) { Import-Module $ChocolateyProfile }

if (Get-Command vim -ErrorAction Ignore) { Set-Alias vi vim }

Invoke-Expression (& { (zoxide init powershell | Out-String) })
