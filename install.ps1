#Requires -Version 7
# install.ps1: install the Windows-specific dotfiles
#
# https://github.com/agkozak/dotfiles
#
# install.sh runs this script with Windows' pwsh.exe (PowerShell 7) when it
# runs in Cygwin, MSYS2, Git Bash or WSL. It can also be run by itself:
#
#   pwsh -File install.ps1            install the files
#   pwsh -File install.ps1 -WhatIf    only show what would be done
#
# What it installs:
#
# - The PowerShell profile files go in the directory of the current user's
#   PowerShell 7 profiles, <Documents>\PowerShell. The Documents folder may
#   have been moved (OneDrive moves it into the OneDrive folder, for
#   example), so the directory is taken from $PROFILE, which reflects
#   where it actually is.
# - .psmux.conf goes in the home directory, if psmux is installed. It is
#   looked for on PATH and where WinGet installs it, since a pwsh started
#   from MSYS2 with a minimal PATH might not find it on PATH.
#
# As conditional_install in install.sh does, each file is copied with its
# modification time, and the message says whether the file is new
# (Installing), out of date (Upgrading: the file here is newer than the
# installed one), or neither (Replacing).
#
# The profile depends on Windows (WinGet, Git for Windows, Windows' tar.exe
# and so on), so on Linux and macOS, where PowerShell 7 also runs, the
# script does nothing. #Requires stops it with an error in Windows
# PowerShell 5.1, whose profile directory is a different one.

[CmdletBinding(SupportsShouldProcess)]
param()

if (-not $IsWindows) {
  Write-Host 'install.ps1: not Windows; nothing to install.'
  return
}

function Install-DotFile {
  param([string]$Name, [string]$Destination)
  $source = Join-Path $PSScriptRoot $Name
  $target = Join-Path $Destination $Name
  $verb = if (-not (Test-Path -LiteralPath $target)) { 'Installing' }
          elseif ((Get-Item -LiteralPath $source).LastWriteTimeUtc -gt
                  (Get-Item -LiteralPath $target).LastWriteTimeUtc) { 'Upgrading' }
          else { 'Replacing' }
  Write-Host "$verb $target"
  if (-not (Test-Path -LiteralPath $Destination)) {
    New-Item -ItemType Directory -Path $Destination | Out-Null
  }
  # Copy-Item keeps the source's modification time, as cp -p does.
  Copy-Item -LiteralPath $source -Destination $target -Force
}

$profileDir = Split-Path $PROFILE.CurrentUserAllHosts
foreach ($name in 'profile.ps1', 'Microsoft.PowerShell_profile.ps1',
                  'Microsoft.VSCode_profile.ps1', 'polyglot-prompt.ps1') {
  Install-DotFile -Name $name -Destination $profileDir
}

if ((Get-Command psmux -CommandType Application -ErrorAction Ignore) -or
    (Test-Path "$env:LOCALAPPDATA\Microsoft\WinGet\Links\psmux.exe")) {
  Install-DotFile -Name '.psmux.conf' -Destination $HOME
}
