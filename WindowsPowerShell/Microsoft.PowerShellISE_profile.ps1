# Profile of the Windows PowerShell ISE host. ISE runs profile.ps1 (all
# hosts) and then this file, but not Microsoft.PowerShell_profile.ps1, which
# is the console host's profile. Without this file, ISE would get the prompt
# (from profile.ps1) but none of the interactive settings, zoxide included.
#
# Like the other shims in this directory, this dot-sources the real file in
# ..\PowerShell, so its functions, aliases and settings stay defined after it
# finishes. ISE does not load PSReadLine, so the console profile skips its
# PSReadLine section (vi mode, key bindings, global aliases) here.
#
# https://github.com/agkozak/dotfiles
#
. (Join-Path (Split-Path $PSScriptRoot) 'PowerShell\Microsoft.PowerShell_profile.ps1')
