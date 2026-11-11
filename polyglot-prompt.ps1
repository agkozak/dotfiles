###########################################################################
# Polyglot-style prompt for PowerShell
#
# https://github.com/agkozak/dotfiles
#
# A PowerShell approximation of Polyglot Prompt (polyglot.sh):
#
#   (1) (venv) user@host ~/.../foo/bar (main &*+x!>?) $
#
# with three additions taken from the agkozak-zsh-prompt configuration in
# .zshrc, and that configuration's Zenburn 256-color palette:
#
#   12s (1) (venv) user@host ~/.../foo/bar 1j (main &*+x!>?) $
#
#   12s  how long the last command ran, if it took long enough
#   1j   number of PowerShell background jobs that haven't finished
#
# In PSReadLine's vi command mode, the prompt character becomes ':', as
# agkozak-zsh-prompt shows it in vicmd mode. That requires a
# ViModeChangeHandler that sets $PolyglotViMode and redraws the prompt; the
# profile defines one (see "Vi mode and redraws" below).
#
# A path on a named drive, such as HKLM:\ or Temp:\ or one created with
# New-PSDrive, keeps the drive name in front when abbreviated, as '~' is kept
# for the home directory: Temp:\...\c\d.
#
# Plus, in Windows Terminal, an invisible escape sequence that tells the
# terminal the current directory (see the end of the prompt function).
#
# Usage: either paste this into profile.ps1, or keep it as a separate file
# next to your profile and dot-source it from there:
#
#   . "$PSScriptRoot\polyglot-prompt.ps1"
#
# ("Dot-sourcing" runs a script in the caller's scope, like `. file` in sh,
# so the functions and variables defined here stay available afterward.)
#
# Settings (environment variables, as in polyglot.sh):
#   $env:POLYGLOT_PROMPT_DIRTRIM   number of trailing path elements to show
#                                  (default 2; 0 disables abbreviation)
#   $env:POLYGLOT_SHOW_UNTRACKED   set to 0 to ignore untracked files
#                                  (faster in very large repos)
#   $env:POLYGLOT_CMD_EXEC_TIME    show the last command's running time if it
#                                  took at least this many seconds (default 5,
#                                  as AGKOZAK_CMD_EXEC_TIME; 0 disables). This
#                                  setting is specific to this file; polyglot.sh
#                                  doesn't have it.
###########################################################################


# -------------------------------------------------------------------------
# One-time setup (runs once, when the profile loads)
# -------------------------------------------------------------------------

# Python's venv Activate.ps1 normally redefines the prompt function to add
# "(venv) ". This tells it not to; we display the venv ourselves below.
$env:VIRTUAL_ENV_DISABLE_PROMPT = 1

# Default the dirtrim setting to 2 if the user hasn't set it.
# (-not on an unset/empty variable is $true, much like [ -z "$VAR" ].)
if (-not $env:POLYGLOT_PROMPT_DIRTRIM) { $env:POLYGLOT_PROMPT_DIRTRIM = 2 }

# Default the execution-time threshold to 5 seconds if the user hasn't set it.
# Environment variables are always strings, and any non-empty string is
# truthy, so a user's '0' would survive a -not test too; comparing with $null
# just states the intent (apply the default only when unset) directly.
if ($null -eq $env:POLYGLOT_CMD_EXEC_TIME) { $env:POLYGLOT_CMD_EXEC_TIME = 5 }

# The Id of the last history entry whose running time the prompt has
# considered. Pressing Enter on an empty line runs no command and adds
# nothing to the history, so without this the prompt would keep showing the
# previous command's time.
$PolyglotLastHistoryId = 0

# Vi mode and redraws. PSReadLine starts in vi insert mode. A
# ViModeChangeHandler (in the profile) stores 'Insert' or 'Command' here
# whenever the mode changes, sets $PolyglotPromptRedraw, and calls
# [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt(), which calls the
# prompt function again. On such a redraw nothing but the vi mode can have
# changed, so the prompt function reuses $PolyglotPromptPrefix, everything it
# built before the prompt character the last time it ran, rather than running
# git again. A redraw also must not recompute the exit status, because $? by
# then describes the handler, not the last command.
#
# Only the handler changes $PolyglotViMode. PSReadLine also leaves vi mode
# unchanged from one line to the next: Enter in command mode runs
# ViAcceptLine, which switches to insert mode (and so calls the handler)
# before accepting the line, while Ctrl-C (CancelLine) in command mode leaves
# the next line in command mode too.
$PolyglotViMode = 'Insert'
$PolyglotPromptRedraw = $false
$PolyglotPromptPrefix = $null

# Colors, as SGR parameters: the part of an escape sequence ESC[...m between
# '[' and 'm'. '1' is bold; '38;5;N' selects foreground color N from the
# 256-color palette. The numbers are the AGKOZAK_COLORS_* values in .zshrc.
# polyglot.sh's own colors were bold green (1;32) for user@host, bold blue
# (1;34) for the path, yellow (33) for Git and bold red (1;31) for the exit
# status; substitute those to go back to them.
$PolyglotColors = @{
  ExecTime   = '38;5;245'     # AGKOZAK_COLORS_CMD_EXEC_TIME
  ExitStatus = '1;38;5;174'   # AGKOZAK_COLORS_EXIT_STATUS
  Venv       = '38;5;188'     # AGKOZAK_COLORS_VIRTUALENV
  UserHost   = '1;38;5;108'   # AGKOZAK_COLORS_USER_HOST
  Path       = '1;38;5;116'   # AGKOZAK_COLORS_PATH
  Jobs       = '38;5;223'     # AGKOZAK_COLORS_BG_STRING
  Git        = '38;5;228'     # AGKOZAK_COLORS_BRANCH_STATUS
}

# Are we running elevated? This is the equivalent of polyglot's
# _polyglot_is_superuser, computed once rather than on every prompt.
#
# - $IsWindows exists only in PowerShell 6+. In Windows PowerShell 5.1 it's
#   undefined (so $null, i.e. false), which is why we also check for the
#   'Desktop' edition, which only 5.1 reports.
# - On Windows we ask .NET whether the current identity is in the
#   Administrators role. Note that `if` in PowerShell is an expression, so
#   its result can be assigned directly to a variable.
# - Elsewhere we just shell out to `id -u`, as polyglot does.
$PolyglotIsAdmin = if ($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop') {
  ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} else {
  (id -u) -eq 0   # `id` outputs a string; -eq coerces the 0 to match
}

# Like polyglot, show "@host" only over SSH or when running as admin/root.
# The SSH_* variables are set by sshd; an unset $env: variable is $null.
# MachineName may be fully qualified, so keep only the part before the
# first dot (cf. ${HOST%%.*}). -split takes a regex, hence '\.'.
$PolyglotHost = if ($env:SSH_CONNECTION -or $env:SSH_CLIENT -or $env:SSH_TTY -or $PolyglotIsAdmin) {
  '@' + ([Environment]::MachineName -split '\.')[0]
} else {
  ''
}


# -------------------------------------------------------------------------
# Get-PolyglotDir: abbreviated working directory
#
# PowerShell's version of _polyglot_prompt_dirtrim / bash's PROMPT_DIRTRIM:
#   $HOME              -> ~
#   $HOME/a/b/c/d      -> ~/.../c/d
#   /usr/local/share   -> .../local/share
#   Temp:\a\b\c\d      -> Temp:\...\c\d
#
# Parameters:
#   $Trim  number of trailing path elements to keep (0 = no abbreviation)
# -------------------------------------------------------------------------
function Get-PolyglotDir([int]$Trim = 2) {
  # The native separator: '\' on Windows, '/' elsewhere.
  $sep = [IO.Path]::DirectorySeparatorChar

  # $PWD is a PathInfo object, not a string; .Path is the string form.
  $path = $PWD.Path

  # Exactly at home: just '~'. (`return` exits the function early; any
  # value given to it becomes the function's output.)
  if ($path -eq $HOME) { return '~' }

  # Under home: strip the $HOME prefix and remember to put '~' back.
  # The comparison is case-insensitive, which is right for Windows paths
  # (slightly loose on Linux, but harmless in practice). We match
  # "$HOME$sep" rather than "$HOME" so that /home/alexander doesn't count
  # as being under /home/alex.
  $prefix = ''
  if ($path.StartsWith("$HOME$sep", [StringComparison]::OrdinalIgnoreCase)) {
    $path   = $path.Substring($HOME.Length)   # leaves e.g. '\a\b\c'
    $prefix = '~'
  }
  # On a drive whose name is longer than one letter (HKLM:, Temp:, or a
  # drive made with New-PSDrive), $PWD.Path begins with that name, e.g.
  # 'Temp:\a\b'. Treat 'Temp:' the way '~' is treated above, so that it is
  # kept when the rest is abbreviated. Single-letter drives such as C: are
  # left as they were. (In PowerShell on Linux and macOS the file system
  # drive is named '/', so this doesn't apply to it.)
  elseif ($PWD.Drive -and $PWD.Drive.Name.Length -gt 1 -and
          $path.StartsWith("$($PWD.Drive.Name):", [StringComparison]::OrdinalIgnoreCase)) {
    $prefix = "$($PWD.Drive.Name):"
    $path   = $path.Substring($prefix.Length)  # leaves e.g. '\a\b'
  }

  # Split into elements, dropping the empty string before the leading
  # separator (the equivalent of polyglot's `shift` after `set --`).
  $parts = $path.Split($sep, [StringSplitOptions]::RemoveEmptyEntries)

  # Nothing to abbreviate: return the path as is.
  if ($Trim -le 0 -or $parts.Count -le $Trim) { return "$prefix$path" }

  # Keep the last $Trim elements. Negative indices count from the end, and
  # -2..-1 is a range, so $parts[-2..-1] yields the last two elements.
  # -join glues them back together with the separator.
  $tail = $parts[-$Trim..-1] -join $sep

  # The last expression's value is the function's output (no `return`
  # needed); this is an if/else expression yielding one string or the other.
  if ($prefix) { "$prefix$sep...$sep$tail" } else { "...$sep$tail" }
}


# -------------------------------------------------------------------------
# Get-PolyglotGit: branch name and status symbols
#
# Returns ' (branch SYMBOLS)', or '' outside a Git repository.
#
# Symbols, in polyglot's order:
#   &   behind the upstream        *   ahead of the upstream
#   &*  diverged (both of the above)
#   +   new file staged            x   file deleted
#   !   file modified              >   file renamed
#   ?   untracked files
#
# Instead of parsing human-readable `git status` output, as polyglot.sh
# must for portability, this uses the machine-readable porcelain v2
# format, which is locale-independent and stable across Git versions.
# Sample output:
#
#   # branch.oid 3f2a9c1e...
#   # branch.head main
#   # branch.upstream origin/main
#   # branch.ab +1 -2
#   1 .M N... 100644 100644 100644 <hash> <hash> file.txt
#   2 R. N... 100644 100644 100644 <hash> <hash> R100 new.txt	old.txt
#   ? scratch.txt
#
# Lines starting with '1' are ordinary changes and '2' are renames or
# copies. The two characters after the type ("XY") give the status in the
# index (X) and the working tree (Y); '.' means unchanged.
# -------------------------------------------------------------------------
function Get-PolyglotGit {
  # Honor POLYGLOT_SHOW_UNTRACKED=0, like polyglot's `git status -uno`.
  $u = if ($env:POLYGLOT_SHOW_UNTRACKED -eq '0') { 'no' } else { 'normal' }

  # Output from a native command arrives as an array of strings, one per
  # line. --no-optional-locks is the flag form of GIT_OPTIONAL_LOCKS=0, so
  # the prompt never fights with other git processes for the index lock.
  # 2>$null discards stderr ("not a git repository", etc.).
  $status = git --no-optional-locks status --porcelain=v2 --branch --untracked-files=$u 2>$null

  # $LASTEXITCODE holds the exit code of the last native command (like $?
  # in sh). Non-zero means no repository here, or git isn't installed.
  if ($LASTEXITCODE -ne 0) { return '' }

  # Initialize state. Chained assignment works as in C: a = b = value.
  $branch = $oid = ''
  $ahead = $behind = 0
  $new = $del = $mod = $ren = $untracked = $false

  # When given an array, `switch` loops over every element (here, every
  # line of git's output). -Regex makes each case a regular expression,
  # and after a successful match the automatic $Matches hashtable holds the
  # capture groups: $Matches[1], $Matches[2], and so on.
  #
  # Unlike sh's `case`, a PowerShell switch keeps testing the remaining
  # cases after a match. That's harmless here because these patterns are
  # mutually exclusive.
  switch -Regex ($status) {
    # Commit hash, needed only for a detached HEAD.
    '^# branch\.oid (\S+)' { $oid = $Matches[1] }

    # Branch name, or the literal '(detached)'.
    '^# branch\.head (.+)' { $branch = $Matches[1] }

    # Ahead/behind counts. This line appears only if the branch has an
    # upstream. The [int] casts convert the captured strings to numbers.
    '^# branch\.ab \+(\d+) -(\d+)' {
      $ahead  = [int]$Matches[1]
      $behind = [int]$Matches[2]
    }

    # A changed tracked file. Group 1 is the line type (1 or 2); groups 2
    # and 3 are X and Y. `$x, $y = a, b` is multiple assignment.
    '^([12]) (.)(.)' {
      $x, $y = $Matches[2], $Matches[3]

      # 'A' only makes sense in the index: a newly added, staged file
      # (polyglot's "new file:").
      if ($x -eq 'A') { $new = $true }

      # Deleted or modified, whether staged (X) or not (Y).
      if ($x -eq 'D' -or $y -eq 'D') { $del = $true }
      if ($x -eq 'M' -or $y -eq 'M') { $mod = $true }

      # Type 2 lines are always renames/copies.
      if ($Matches[1] -eq '2') { $ren = $true }
    }

    # An untracked file.
    '^\?' { $untracked = $true }
  }

  # Detached HEAD: show the abbreviated commit hash instead, as polyglot
  # does with `git rev-parse --short HEAD`.
  if ($branch -eq '(detached)') { $branch = $oid.Substring(0, 7) }

  # Build the symbol string. Integers are truthy when non-zero, so
  # `if ($behind)` means "behind by at least one commit". Because behind
  # is tested before ahead, a diverged branch naturally gets '&*'.
  $sym = ''
  if ($behind)    { $sym += '&' }
  if ($ahead)     { $sym += '*' }
  if ($new)       { $sym += '+' }
  if ($del)       { $sym += 'x' }
  if ($mod)       { $sym += '!' }
  if ($ren)       { $sym += '>' }
  if ($untracked) { $sym += '?' }

  # This string is the function's output.
  if ($sym) { " ($branch $sym)" } else { " ($branch)" }
}


# -------------------------------------------------------------------------
# Format-PolyglotDuration: a number of seconds as e.g. 7s, 3m12s, 1h0m5s
#
# Parameters:
#   $Seconds  whole seconds (the [int] cast rounds a fractional value)
# -------------------------------------------------------------------------
function Format-PolyglotDuration([int]$Seconds) {
  # [Math]::Floor because PowerShell's / always produces a fractional result
  # when the division isn't exact (7 / 2 is 3.5, not 3 as in sh's $(( ))).
  # % is the remainder, as in sh.
  $h = [Math]::Floor($Seconds / 3600)
  $m = [Math]::Floor(($Seconds % 3600) / 60)
  $s = $Seconds % 60

  # ${h} rather than $h, because "$hh" would be read as a variable named hh.
  $r = ''
  if ($h)       { $r += "${h}h" }
  if ($h -or $m) { $r += "${m}m" }
  "$r${s}s"
}


# -------------------------------------------------------------------------
# prompt: called by PowerShell before every command line
#
# Defining a function named `prompt` is how you customize the prompt in
# PowerShell; whatever string it outputs is displayed. It plays the role of
# PS1 + PROMPT_COMMAND (or a zsh precmd hook) combined.
#
# PSReadLine measures ANSI escape sequences itself, so there's no need for
# bash's \[ \] or the \001 markers polyglot needs for mksh/pdksh.
# -------------------------------------------------------------------------
function prompt {
  # $? is $true/$false: did the last command succeed? It has to be read on
  # the very first line, because every statement after this resets it.
  $ok = $?

  # A redraw after a vi mode change (see "Vi mode and redraws" at the top of
  # the file): reuse the saved prefix and add the new prompt character. The
  # flag is cleared first, so that the next ordinary prompt is built anew.
  if ($global:PolyglotPromptRedraw) {
    $global:PolyglotPromptRedraw = $false
    if ($null -ne $global:PolyglotPromptPrefix) {
      return $global:PolyglotPromptPrefix + (Get-PolyglotPromptEnd)
    }
  }

  # Save the last native exit code too. Calling git below will overwrite
  # $LASTEXITCODE, so we restore it at the end. The $global: scope
  # modifier is needed because we're inside a function, and an assignment
  # without it would create a local variable instead.
  $code = $global:LASTEXITCODE

  # The ESC character, for ANSI color sequences. PowerShell 7 also accepts
  # "`e", but [char]27 works in Windows PowerShell 5.1 as well.
  $e = [char]27

  # The prompt is assembled in this string.
  $out = ''

  # A shorter name for the color table defined at the top of the file.
  $c = $PolyglotColors

  # --- Running time of the last command, if it reached the threshold ---
  # Get-History -Count 1 returns the most recent history entry, or nothing
  # if no command has run yet. Its start and end times are [DateTime]s, and
  # subtracting them gives a [TimeSpan]. (PowerShell 7 also has a Duration
  # property, but Windows PowerShell 5.1 doesn't.)
  $last = Get-History -Count 1
  if ($last -and $last.Id -ne $global:PolyglotLastHistoryId) {
    $global:PolyglotLastHistoryId = $last.Id
    $secs = [Math]::Floor(($last.EndExecutionTime - $last.StartExecutionTime).TotalSeconds)
    $min = [int]$env:POLYGLOT_CMD_EXEC_TIME
    if ($min -gt 0 -and $secs -ge $min) {
      $out += "$e[$($c.ExecTime)m$(Format-PolyglotDuration $secs)$e[0m "
    }
  }

  # --- Exit status, in bold, only after a failure ---
  # A failed native command has a non-zero $LASTEXITCODE. A failed cmdlet
  # has no exit code, so we show (1) instead.
  #
  # Note on "$e[$($c.ExitStatus)m": in a double-quoted string, PowerShell
  # expands $e and treats the following '[' as literal text, not an array
  # index. (An index inside a string would need $($e[1]).) $(...) inside a
  # string runs arbitrary code, like $(...) in sh, but in-process; it is
  # needed here because "$c.ExitStatus" would expand only $c and leave
  # '.ExitStatus' as literal text.
  if (-not $ok) {
    $out += "$e[$($c.ExitStatus)m($(if ($code) { $code } else { 1 }))$e[0m "
  }

  # --- Python virtual environment name (cf. _polyglot_venv) ---
  $v = ''
  if ($env:VIRTUAL_ENV) {
    # Split-Path -Leaf is like basename; plain Split-Path is like dirname.
    $v = Split-Path $env:VIRTUAL_ENV -Leaf

    # pipenv/poetry with an in-project .venv: use the project directory's
    # name instead.
    if ($v -eq '.venv') {
      $v = Split-Path (Split-Path $env:VIRTUAL_ENV) -Leaf
    }
    # pipenv elsewhere: names look like project-AbC123xy, so strip the
    # final hyphen and hash (cf. ${VIRTUAL_ENV%-*}). -replace is a regex
    # substitution; with no replacement string, it deletes the match.
    elseif ($env:PIPENV_ACTIVE) {
      $v = $v -replace '-[^-]*$'
    }
  }
  elseif ($env:CONDA_DEFAULT_ENV) {
    $v = $env:CONDA_DEFAULT_ENV
  }
  if ($v) { $out += "$e[$($c.Venv)m($v)$e[0m " }

  # --- user[@host]: bold, or reverse video when elevated ---
  $user = [Environment]::UserName + $PolyglotHost
  $out += if ($PolyglotIsAdmin) { "$e[7m$user$e[0m " } else { "$e[$($c.UserHost)m$user$e[0m " }

  # --- Working directory, in bold ---
  # The environment variable is a string; Get-PolyglotDir's [int]
  # parameter converts it automatically.
  $out += "$e[$($c.Path)m$(Get-PolyglotDir $env:POLYGLOT_PROMPT_DIRTRIM)$e[0m"

  # --- Number of unfinished background jobs (cf. %j in zsh prompts) ---
  # Start-Job, Start-ThreadJob and `command &` create jobs. A finished job
  # stays in Get-Job's list until Remove-Job, so count only those in a state
  # other than Completed, Failed or Stopped. @(...) makes the result an array
  # even when there are zero or one jobs, so that .Count is always correct.
  $jobs = @(Get-Job | Where-Object { $_.State -notin 'Completed', 'Failed', 'Stopped' }).Count
  if ($jobs) { $out += " $e[$($c.Jobs)m${jobs}j$e[0m" }

  # --- Git branch and status ('' outside a repository) ---
  $out += "$e[$($c.Git)m$(Get-PolyglotGit)$e[0m"

  # Everything so far is what a vi mode redraw reuses.
  $global:PolyglotPromptPrefix = $out

  # Undo the damage git did to $LASTEXITCODE, so that scripts (and the next
  # prompt) see the exit code of *your* last command.
  $global:LASTEXITCODE = $code

  # Output the finished string. A bare expression on a line by itself is
  # written to the output stream, which makes it the function's result.
  $out + (Get-PolyglotPromptEnd)
}


# -------------------------------------------------------------------------
# Get-PolyglotPromptEnd: the prompt character and what follows it
#
# Called by the prompt function both when it builds the prompt and when it
# redraws it after a vi mode change.
# -------------------------------------------------------------------------
function Get-PolyglotPromptEnd {
  $e = [char]27

  # --- Prompt character: ':' in vi command mode, else # when elevated and
  # $ otherwise (cf. %(4V.:.%#) in .zshrc's AGKOZAK_CUSTOM_PROMPT) ---
  # Single quotes are literal, so '$' needs no escaping.
  $end = if ($global:PolyglotViMode -eq 'Command') { ' : ' }
         elseif ($PolyglotIsAdmin) { ' # ' }
         else { ' $ ' }

  # --- Report the current directory to Windows Terminal ---
  # The sequence ESC ] 9 ; 9 ; "path" ESC \ is a Windows Terminal extension
  # that prints nothing. It records the directory, so that "Duplicate Tab"
  # and new split panes start there. Windows Terminal sets WT_SESSION in
  # every shell it starts; other terminals don't get the sequence. Only
  # FileSystem locations have a directory to report: in HKLM:\ or Env:\,
  # $PWD.ProviderPath isn't a directory.
  if ($env:WT_SESSION -and $PWD.Provider.Name -eq 'FileSystem') {
    $end += "$e]9;9;`"$($PWD.ProviderPath)`"$e\"
  }

  $end
}
