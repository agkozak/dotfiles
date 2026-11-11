# Microsoft.VSCode_profile.ps1: profile of the VS Code PowerShell extension
#
# https://github.com/agkozak/dotfiles
#
# The PowerShell extension's own terminal ("PowerShell Extension") runs
# PowerShell in a different host from pwsh in an ordinary terminal, and each
# host has its own current-user profile. There, PowerShell runs profile.ps1
# (all hosts) and then this file, but not Microsoft.PowerShell_profile.ps1,
# which is the console host's profile. So without this file the extension's
# terminal would get the prompt (from profile.ps1) but none of the
# interactive settings: vi mode and the other PSReadLine settings, AUTO_CD,
# the global aliases, the vi alias, zoxide and the rest.
#
# Dot-sourcing (the leading '. ') runs the console profile in this scope, as
# if its contents were written here. $PSScriptRoot is the directory of this
# file, which is the same directory as the console profile.
. "$PSScriptRoot\Microsoft.PowerShell_profile.ps1"
