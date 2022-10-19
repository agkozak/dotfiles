# vi editing mode
Import-Module PSReadline
Set-PSReadlineOption -EditMode vi

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

Set-Alias -Name vi -Value vim
