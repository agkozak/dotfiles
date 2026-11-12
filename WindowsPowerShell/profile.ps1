# Shim for Windows PowerShell 5.1. The real file is ..\PowerShell\profile.ps1,
# which PowerShell 7 loads directly. Dot-sourcing it runs it in this scope,
# so its functions, aliases and settings stay defined after it finishes.
#
# https://github.com/agkozak/dotfiles
#
. (Join-Path (Split-Path $PSScriptRoot) 'PowerShell\profile.ps1')
