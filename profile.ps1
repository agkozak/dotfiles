# profile.ps1: runs in every PowerShell host, before the host's own profile
# (Microsoft.PowerShell_profile.ps1 for the console, Microsoft.VSCode_profile.ps1
# for the VS Code extension). See the header of Microsoft.PowerShell_profile.ps1
# for an overview of all the files.

# The Polyglot-style prompt.
. "$PSScriptRoot\polyglot-prompt.ps1"

# The Vivid 78s completions are generated from the installed programs and
# loaded on first use by the console profile (see "Vivid 78s completions"
# there).

# Start psmux, or attach to its session "main" if that already exists (cf.
# `exec tmux` in .zprofile). This file runs in every PowerShell host and also
# when pwsh runs a command or a script without -NoProfile, so, like
# .zprofile, it starts psmux only in an interactive terminal session:
#
# - The host is the console host. The VS Code PowerShell extension's
#   terminal, for example, is a different host ('Visual Studio Code Host').
# - Neither stdin nor stdout is redirected (cf. `-t 0` and `-t 1`).
# - pwsh wasn't asked to run a command (-Command, -c, -EncodedCommand, -ec)
#   or a script (-File, -f), unless -NoExit (-noe) keeps it running
#   interactively afterwards (cf. ZSH_EXECUTION_STRING and ZSH_SCRIPT). The
#   check matches only these spellings of the options, not abbreviations
#   such as -Comm, and not a script given without -File ('pwsh script.ps1').
# - pwsh wasn't started with -NonInteractive (-noni).
# - The session isn't inside Vim (whose :terminal sets VIM) or Emacs
#   (INSIDE_EMACS), or already inside tmux or psmux.
#
# pwsh accepts options beginning with -, -- or /, and ignores their case,
# as -match does.
#
# Zsh's `exec tmux` replaces the shell, so detaching from tmux ends the
# terminal session. PowerShell can't replace itself with another program, so
# when psmux returns, this pwsh exits instead. psmux 3.4.0 returned exit code
# 0 after a detach, after its session ended, and after its server was killed
# (measured), so $? is true in all of those cases. $? is false if psmux
# returned a non-zero code or couldn't be run at all (not installed, for
# example), and then the pwsh session continues, rather than closing a
# terminal whose psmux never started.
#
# The exit uses [Environment]::Exit, which ends the process at once. The
# exit keyword would not do: in a profile it ends only the profile script,
# and pwsh goes on to its interactive prompt (tested). Ending the process
# this early loses nothing, since no command has run yet and PSReadLine
# saves the history after each command anyway.
$cmdArgs = @([Environment]::GetCommandLineArgs() | Select-Object -Skip 1)
$runsCommand = @($cmdArgs -match '^(-{1,2}|/)(c|command|ec|encodedcommand|f|file)$').Count -gt 0 -and
               @($cmdArgs -match '^(-{1,2}|/)(noe|noexit)$').Count -eq 0
$nonInteractive = @($cmdArgs -match '^(-{1,2}|/)(noni|noninteractive)$').Count -gt 0
if ($Host.Name -eq 'ConsoleHost' -and
    -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected -and
    -not $runsCommand -and -not $nonInteractive -and
    -not $env:VIM -and -not $env:INSIDE_EMACS -and
    -not $env:TMUX -and -not $env:PSMUX_SESSION -and -not $env:PSMUX_ACTIVE) {
  psmux new -A -s main
  if ($?) { [Environment]::Exit(0) }
}
Remove-Variable cmdArgs, runsCommand, nonInteractive
