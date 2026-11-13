#Requires -Version 7
# install.ps1: install the PowerShell dotfiles
#
# https://github.com/agkozak/dotfiles
#
# install.sh runs this script with Windows' pwsh.exe (PowerShell 7) when it
# runs in Cygwin, MSYS2, Git Bash or WSL. It can also be run by itself, on
# Windows, Linux or macOS:
#
#   pwsh -File install.ps1            install the files
#   pwsh -File install.ps1 -WhatIf    only show what would be done
#
# What it installs:
#
# - The PowerShell profile files go in the directory of the current user's
#   PowerShell 7 profiles. On Windows that is <Documents>\PowerShell; the
#   Documents folder may have been moved (OneDrive moves it into the
#   OneDrive folder, for example). On Linux and macOS it is
#   ~/.config/powershell, or $XDG_CONFIG_HOME/powershell if that variable
#   is set. Either way the directory is taken from $PROFILE, which reflects
#   where it actually is.
# - On Windows only, the files in WindowsPowerShell\ go in
#   <Documents>\WindowsPowerShell, the profile directory of Windows
#   PowerShell 5.1 (the console host and ISE). They are shims: each
#   dot-sources the PowerShell 7 file of the same name, or for ISE the
#   console profile, from ..\PowerShell. That relative path only works
#   because the two profile directories are both in <Documents>, so this
#   directory is taken as the sibling of the PowerShell 7 one rather than
#   looked up separately.
# - .psmux.conf goes in the home directory, if psmux is installed. It is
#   looked for on PATH and, on Windows, where WinGet installs it, since a
#   pwsh started from MSYS2 with a minimal PATH might not find it on PATH.
#
# As conditional_install in install.sh does, each file is copied with its
# modification time, and the message says whether the file is new
# (Installing), out of date (Upgrading: the file here is newer than the
# installed one), or neither (Replacing).
#
# The profile files are installed on every platform, so they must cope with
# running outside Windows themselves (guarding WinGet, Git for Windows,
# Windows' tar.exe and so on with $IsWindows). #Requires stops this script
# with an error in Windows PowerShell 5.1, in which $PROFILE names the 5.1
# profile directory rather than the PowerShell 7 one.

[CmdletBinding(SupportsShouldProcess)]
param()

# Install-DotFile: copy the file $Name from $SourceDir (by default the
# directory of this script) to $Destination, under the same name.
function Install-DotFile {
  param([string]$Name, [string]$Destination, [string]$SourceDir = $PSScriptRoot)
  $source = Join-Path $SourceDir $Name
  $target = Join-Path $Destination $Name
  $sourceTime = (Get-Item -LiteralPath $source).LastWriteTimeUtc
  $verb = if (-not (Test-Path -LiteralPath $target)) { 'Installing' }
          elseif ($sourceTime -gt (Get-Item -LiteralPath $target).LastWriteTimeUtc) { 'Upgrading' }
          else { 'Replacing' }
  Write-Host "$verb $target"
  if (-not (Test-Path -LiteralPath $Destination)) {
    New-Item -ItemType Directory -Path $Destination | Out-Null
  }
  Copy-Item -LiteralPath $source -Destination $target -Force
  # Set the modification time explicitly, as cp -p does: Copy-Item keeps it
  # on Windows, but can't be relied on to elsewhere. Under -WhatIf nothing
  # was copied, so there is nothing to set.
  if (-not $WhatIfPreference) {
    (Get-Item -LiteralPath $target).LastWriteTimeUtc = $sourceTime
  }
}

$profileDir = Split-Path $PROFILE.CurrentUserAllHosts
foreach ($name in 'profile.ps1', 'Microsoft.PowerShell_profile.ps1',
                  'Microsoft.VSCode_profile.ps1', 'polyglot-prompt.ps1') {
  Install-DotFile -Name $name -Destination $profileDir
}

# The Windows PowerShell 5.1 shims (see the top of this file).
if ($IsWindows) {
  $shimDir = Join-Path (Split-Path $profileDir) 'WindowsPowerShell'
  foreach ($name in 'profile.ps1', 'Microsoft.PowerShell_profile.ps1',
                    'Microsoft.PowerShellISE_profile.ps1') {
    Install-DotFile -Name $name -Destination $shimDir -SourceDir (Join-Path $PSScriptRoot 'WindowsPowerShell')
  }
}

$hasPsmux = [bool](Get-Command psmux -CommandType Application -ErrorAction Ignore)
if (-not $hasPsmux -and $IsWindows) {
  $hasPsmux = Test-Path (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\psmux.exe')
}
if ($hasPsmux) {
  Install-DotFile -Name '.psmux.conf' -Destination $HOME
}