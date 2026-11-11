. "$PSScriptRoot\polyglot-prompt.ps1"
. "$PSScriptRoot\vivid78s.ps1"
. "$PSScriptRoot\vivid78s-declick.ps1"
. "$PSScriptRoot\vivid78s-declick-lab.ps1"

if (-not $env:TMUX -and -not $env:PSMUX_SESSION -and -not $env:PSMUX_ACTIVE) {
	psmux new -A -s main
}
