###########################################################################
# Microsoft.PowerShell_profile.ps1: interactive settings for PowerShell 7
#
# https://github.com/agkozak/dotfiles
#
# Many of these settings carry over features of the Zsh setup in ~/.zshrc,
# ~/.shrc and ~/.inputrc, which the comments cite with "cf.".
#
# Which profile files run: PowerShell runs profile.ps1 (all hosts) first,
# then this file, which is the profile of the console host only (pwsh in a
# terminal, Windows Terminal, psmux, or the VS Code terminal when its
# profile is plain pwsh). The PowerShell extension's own terminal in VS Code
# ("PowerShell Extension") is a different host, which runs profile.ps1 and
# then Microsoft.VSCode_profile.ps1 instead of this file. That file
# dot-sources this one, so both hosts get the same settings. profile.ps1
# dot-sources polyglot-prompt.ps1, which defines the prompt, and in an
# interactive console session that isn't already inside tmux or psmux, it
# starts psmux or attaches to its session "main" (cf. .zprofile).
#
# Quick reference (each feature is explained where it is defined below):
#
#   Line editing (PSReadLine, vi mode)
#     Esc / i, a ...   vi command / insert mode. The cursor is a block in
#                      command mode, and the prompt character becomes ':'
#     Up/Down, Ctrl-P/Ctrl-N, k/j (command mode)
#                      history substring search: earlier/later lines that
#                      contain the typed text anywhere, ignoring case
#     Ctrl-R / Ctrl-S  incremental history search (PSReadLine default)
#     Ctrl-W           delete the word before the cursor (insert mode)
#     Tab              completion menu (arrow keys move in it); up to 9999
#                      completions are listed without asking first
#     K, F1            help for the command under the cursor
#     v                edit the line in $VISUAL (vim)
#     ...              typed after a word start: becomes ..\.. (and so on)
#     Enter            expands global aliases, then runs the line
#     leading space    keeps a line out of the history file
#
#   Global aliases (words expanded when Enter is pressed)
#     H    | Select-Object -First 10      T    | Select-Object -Last 10
#     L    | less                         LL   2>&1 | less
#     NE   2>$null                        NUL  *>$null
#     V    2>&1 | vim - +AnsiEsc
#
#   Directories
#     <dir>            typing a directory's name or path changes to it
#                      (AUTO_CD); so does a drive name such as agk:
#     agk: zshz: zc:   named directories (cf. hash -d), as PowerShell
#                      drives: cd agk:\functions, ls zc:
#     z <words>, zi    jump to a frequently used directory (zoxide), and
#                      print where it went
#     z foo<Tab>       choose from zoxide's directories matching foo
#     zoxide <Tab>     zoxide's subcommands and options, loaded on first use
#     dirs [-v|-p|-l|-c]   directory stack (cf. AUTO_PUSHD)
#     cd +N / cd -N    go to stack entry N (from the top / the bottom)
#     cd - / cd +      back / forward in PowerShell's location history
#
#   Listing files (all with the Zenburn colors of ~/.dircolors)
#     ls, dir, gci     Get-ChildItem      l     names in columns (ls -CF)
#     la, ll           include hidden     lt    newest first
#     lrt, lart        oldest first       ldot  dotfiles only
#     lr               recursive, newest first in each directory
#
#   Other
#     hgrep <regex>    search the command history, newest last
#                      (-CaseSensitive to stop ignoring case)
#     which [-a] <name>    what a name runs: alias, function, cmdlet or path
#     open <path|URL>  open with the default program; 'open .' -> Explorer
#     x, extract <archive>...  unpack (unarchive); -r deletes the archive
#     ssh, scp, sftp, mosh <Tab>   host names from ~/.ssh/config
#     less             Git for Windows' less, with LESS=-FiRX
#     vi               vim
#     git <Tab>        completion from posh-git, loaded on first use
#     choco <Tab>, refreshenv   Chocolatey's profile, loaded on first use
#     vivid78s <Tab>   (and vivid78s-declick, vivid78s-declick-lab)
#                      completion generated from the installed program,
#                      loaded on first use
#
#   Generated files, all safe to delete (they are rebuilt when needed):
#     ~\.cache\agkdot\zoxide-init.ps1          zoxide's init script
#     ~\.cache\agkdot\completions\<name>.ps1   Vivid 78s completions
#
#   psmux: in an interactive terminal, profile.ps1 starts psmux or attaches
#   to its session "main", and closes the terminal's pwsh when psmux exits
#   or you detach (cf. `exec tmux` in .zprofile).
###########################################################################

# Size of the session history that Get-History shows (cf. HISTSIZE in
# .zshrc). 32767 is the largest value allowed; the default is 4096.
$MaximumHistoryCount = 32767

# less, from Git for Windows, which installs it but doesn't put it on PATH
# (it is in Git's usr\bin, next to GNU versions of find, sort and others that
# would shadow the Windows commands of the same names if that directory were
# added to PATH). An alias can name a program by its full path. LESS is the
# value .profile exports: -F quits if the text fits on one screen, -i makes
# searches case-insensitive unless the pattern has capitals, -R passes color
# escape sequences through, and -X leaves the text on the screen at exit.
#
# PAGER is deliberately not set. PowerShell's help function would accept
# PAGER=less, because it looks the name up with Get-Command and so finds the
# alias, but other programs that read PAGER, such as gh, would look for
# less.exe on PATH and not find it.
$gitLess = "$env:ProgramFiles\Git\usr\bin\less.exe"
if (Test-Path -LiteralPath $gitLess) {
  Set-Alias less $gitLess
  if (-not $env:LESS) { $env:LESS = '-FiRX' }
}
Remove-Variable gitLess

# PSReadLine settings. An interactive session loads PSReadLine before running
# the profile. A non-interactive one (pwsh -Command or -File without
# -NoProfile) doesn't, and there the first Set-PSReadLineOption would load it
# for nothing (about 100 ms), and -PredictionSource would fail with "The
# predictive suggestion feature cannot be enabled because the console output
# doesn't support virtual terminal processing or it's redirected."
if (Get-Module PSReadLine) {
  # Splatting (@options) passes each key of the hashtable as a parameter of
  # the same name, so this is one Set-PSReadLineOption call.
  $options = @{
    EditMode            = 'Vi'
    BellStyle           = 'None'
    # PSReadLine calls ViModeChangeHandler with 'Insert' or 'Command' each
    # time the vi mode changes. This one does two things:
    #
    # - It sets the cursor shape with the DECSCUSR escape sequence ESC [ n
    #   SP q: 1 is a blinking block, and 0 is the terminal's configured
    #   default. (ViModeIndicator 'Cursor', which 'Script' replaces, instead
    #   set the console cursor size: 100% in command mode and the normal size
    #   in insert mode. With 'Script', PSReadLine leaves the cursor alone and
    #   the handler has to change it.)
    #
    # - If polyglot-prompt.ps1 is loaded, it stores the mode in
    #   $PolyglotViMode and has PSReadLine redraw the prompt, whose
    #   character then becomes ':' in command mode (cf. agkozak-zsh-prompt).
    #   $PolyglotPromptRedraw tells the prompt function to reuse the rest of
    #   the prompt rather than run git again; see "Vi mode and redraws" in
    #   polyglot-prompt.ps1.
    ViModeIndicator     = 'Script'
    ViModeChangeHandler = {
      param($mode)
      Write-Host -NoNewline $(if ($mode -eq 'Command') { "`e[1 q" } else { "`e[0 q" })
      $changed = "$mode" -ne $global:PolyglotViMode
      $global:PolyglotViMode = "$mode"
      if ($changed -and $null -ne $global:PolyglotPromptPrefix) {
        $global:PolyglotPromptRedraw = $true
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
      }
    }
    # Show up to this many completions without first asking "Display all N
    # possibilities?" (cf. LISTMAX=9999 in .zshrc; the default is 100).
    CompletionQueryItems = 9999
    # Suggestions from history shown after the cursor as you type (cf.
    # zsh-autosuggestions). Requires PSReadLine 2.1 or later.
    PredictionSource    = 'History'
    # Size of PSReadLine's history file and of the history that Up/Down and
    # Ctrl-R search (cf. SAVEHIST). 32767 is the largest value allowed.
    MaximumHistoryCount = 32767
    # Lines that begin with a space are kept for the current session but not
    # written to the history file, a looser version of Zsh's
    # HIST_IGNORE_SPACE (Zsh drops such a line as soon as the next command is
    # entered). Other lines go through PSReadLine's default check, which keeps
    # lines that look like they contain passwords or tokens out of the file.
    AddToHistoryHandler = {
      param([string]$line)
      if ($line -match '^\s') { return [Microsoft.PowerShell.AddToHistoryOption]::MemoryOnly }
      [Microsoft.PowerShell.PSConsoleReadLine]::GetDefaultAddToHistoryOption($line)
    }
  }
  Set-PSReadLineOption @options
  Remove-Variable options

  # Key bindings from .zshrc and .inputrc. Without -ViMode, a binding applies
  # to vi insert mode. In vi mode PSReadLine's defaults are different: Tab
  # cycles through completions in place, Up/Down and j/k step through history
  # one line at a time, and Ctrl-P/Ctrl-N aren't bound. Tab is made to show a
  # completion menu; the history keys are bound below.
  Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

  # Ctrl-W deletes the word before the cursor, as in Zsh's viins keymap
  # (vi-backward-kill-word). PSReadLine's vi mode leaves it unbound.
  # BackwardKillWord decides where a word begins using PSReadLine's
  # WordDelimiters option.
  Set-PSReadLineKeyHandler -Chord Ctrl+w -ViMode Insert -Function BackwardKillWord

  # History substring search (cf. zsh-history-substring-search, which
  # .zshrc binds to Up/Down, Ctrl-P/Ctrl-N, and k/j in vicmd mode). These keys
  # find earlier and later history lines that contain the text typed so far
  # anywhere, ignoring case, rather than only at the beginning as
  # PSReadLine's HistorySearchBackward does. With nothing typed, they step
  # through all of history.
  #
  # The first keypress of a search collects the matching lines, newest first,
  # each distinct line once, and leaving out a line identical to the typed
  # text, which would otherwise look like a keypress that did nothing. (Zsh's
  # plugin keeps duplicates unless HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE is
  # set.) Later keypresses move through that list. Moving forward past the
  # newest match puts back the text that was typed. A search starts over when
  # the buffer no longer holds the line the search last put there (because
  # it has been edited), or when a new line has been added to the history.
  #
  # As in the Zsh plugin, in a buffer of several lines the keys first move
  # the cursor between lines, and search only from the first line (backward)
  # or the last line (forward).
  #
  # The search state is kept in a hashtable that the handlers share.
  # GetNewClosure() gives each script block its own copy of the variables
  # it uses, but a copied hashtable variable still refers to the same
  # hashtable, so changes made by one handler are seen by the others.
  $hss = @{ Query = ''; Last = $null; Newest = $null; Found = @(); Pos = -1 }
  $hssMove = {
    param([int]$Step)   # 1: an older match; -1: a newer one
    $rl = [Microsoft.PowerShell.PSConsoleReadLine]
    $line = $null; $cursor = $null
    $rl::GetBufferState([ref]$line, [ref]$cursor)

    if ($Step -gt 0 -and $line.Substring(0, $cursor).Contains("`n")) {
      $rl::PreviousLine(); return
    }
    if ($Step -lt 0 -and $line.Substring($cursor).Contains("`n")) {
      $rl::NextLine(); return
    }

    # GetHistoryItems() returns the history oldest first. The newest item is
    # compared by reference, not by text, so that a new line identical to the
    # previous one still counts as new.
    $items = $rl::GetHistoryItems()
    $newest = if ($items.Count) { $items[-1] } else { $null }
    if ($line -cne $hss.Last -or -not [object]::ReferenceEquals($newest, $hss.Newest)) {
      $hss.Query = $line
      $hss.Newest = $newest
      $hss.Pos = -1
      # The comparison operators work on a whole array at once and loop in
      # compiled code, which matters with up to 32767 history lines.
      # -match ignores case, and [regex]::Escape makes the typed text match
      # literally. Distinct() keeps the first, here the newest, occurrence of
      # each line.
      $lines = @($items.CommandLine)
      [array]::Reverse($lines)
      if ($line) { $lines = @($lines -match [regex]::Escape($line)) }
      $lines = [Linq.Enumerable]::Distinct([string[]]$lines, [StringComparer]::Ordinal)
      $hss.Found = @([Linq.Enumerable]::ToArray($lines) -cne $line)
    }

    $pos = $hss.Pos + $Step
    if ($pos -lt -1 -or $pos -ge $hss.Found.Count) { $rl::Ding(); return }
    $new = if ($pos -eq -1) { $hss.Query } else { $hss.Found[$pos] }
    $hss.Pos = $pos
    $hss.Last = $new
    $rl::Replace(0, $line.Length, $new)
    # The cursor goes to the end of the line, which in command mode is on
    # the last character rather than after it.
    $end = $new.Length
    if ($end -gt 0 -and $rl::InViCommandMode()) { $end-- }
    $rl::SetCursorPosition($end)
  }.GetNewClosure()
  $hssBackward = { & $hssMove 1 }.GetNewClosure()
  $hssForward  = { & $hssMove -1 }.GetNewClosure()
  foreach ($binding in @(
      @{ Chord = 'UpArrow';   ScriptBlock = $hssBackward }
      @{ Chord = 'DownArrow'; ScriptBlock = $hssForward }
      @{ Chord = 'Ctrl+p';    ScriptBlock = $hssBackward }
      @{ Chord = 'Ctrl+n';    ScriptBlock = $hssForward }
      @{ Chord = 'k'; ViMode = 'Command'; ScriptBlock = $hssBackward }
      @{ Chord = 'j'; ViMode = 'Command'; ScriptBlock = $hssForward })) {
    $up = $binding.ScriptBlock -eq $hssBackward
    Set-PSReadLineKeyHandler @binding `
      -BriefDescription $(if ($up) { 'HistorySubstringSearchUp' } else { 'HistorySubstringSearchDown' }) `
      -Description $(if ($up) { 'Find an earlier history line containing the typed text' }
                     else { 'Find a later history line containing the typed text' })
  }
  Remove-Variable hss, hssMove, hssBackward, hssForward, binding, up

  # Global aliases (cf. alias -g in .zshrc). When Enter is pressed, each of
  # these words that appears in the line as a separate word is replaced by
  # its expansion before the line is accepted, so
  #
  #   git log H        becomes  git log | Select-Object -First 10
  #   Get-Process L    becomes  Get-Process | less
  #   $list T NE       becomes  $list | Select-Object -Last 10 2>$null
  #
  # The table of words and expansions is $globalAliases below; adding an
  # entry there adds a global alias.
  #
  # The words are matched case-sensitively, and only where they are unquoted
  # and not a command name, so 'H' at the start of a line still runs
  # Get-History (its built-in alias), and "H" in quotes is left alone. A word
  # is expanded in two places, both found by parsing the line:
  #
  # - as an argument of a command: one of the elements of a CommandAst after
  #   the first, which is the command name ('git log H');
  # - after an expression, where the parser reports it as an unexpected
  #   token ('$x H', '(Get-Date) L'). Such a line couldn't run anyway, so
  #   rewriting it can't change the meaning of a line that could.
  #
  # The parser reports only the first unexpected token, and an expansion can
  # turn a later word into a command argument ('$x H NE' becomes
  # '$x | Select-Object -First 10 NE'), so the line is parsed and expanded
  # again until nothing changes. Unlike Zsh, which keeps the line as typed,
  # the history receives the expanded line.
  #
  # PowerShell output piped to a native program such as less or vim is
  # formatted as text without colors, because $PSStyle.OutputRendering is
  # 'Host'. A native program's own output (git log --color, say) keeps its
  # colors. Vim's +AnsiEsc runs the AnsiEsc plugin, which renders them.
  $globalAliases = [Collections.Generic.Dictionary[string, string]]::new([StringComparer]::Ordinal)
  $pager = if (Get-Alias less -ErrorAction Ignore) { 'less' } else { 'Out-Host -Paging' }
  $globalAliases['H']   = '| Select-Object -First 10'
  $globalAliases['T']   = '| Select-Object -Last 10'
  $globalAliases['L']   = "| $pager"
  $globalAliases['LL']  = "2>&1 | $pager"
  $globalAliases['NE']  = '2>$null'
  $globalAliases['NUL'] = '*>$null'
  $globalAliases['V']   = '2>&1 | vim - +AnsiEsc'
  $expandAndAccept = {
    param($key, $arg)
    $rl = [Microsoft.PowerShell.PSConsoleReadLine]
    # Each pass finds the extents (positions in the line) of the words to
    # expand. At most ten passes, as a guard against an endless loop.
    for ($pass = 0; $pass -lt 10; $pass++) {
      $line = $cursor = $tokens = $errors = $null
      $rl::GetBufferState([ref]$line, [ref]$cursor)
      $ast = [Management.Automation.Language.Parser]::ParseInput($line, [ref]$tokens, [ref]$errors)
      $extents = @(
        foreach ($command in $ast.FindAll({ $args[0] -is [Management.Automation.Language.CommandAst] }, $true)) {
          $elements = $command.CommandElements
          for ($i = 1; $i -lt $elements.Count; $i++) {
            $word = $elements[$i]
            if ($word -is [Management.Automation.Language.StringConstantExpressionAst] -and
                $word.StringConstantType -eq 'BareWord' -and $globalAliases.ContainsKey($word.Value)) {
              $word.Extent
            }
          }
        }
        foreach ($e in $errors) {
          if ($e.ErrorId -eq 'UnexpectedToken' -and $globalAliases.ContainsKey($e.Extent.Text)) { $e.Extent }
        })
      if (-not $extents) { break }
      # Replace from the end of the line backward, so that each replacement
      # leaves the offsets of the words before it unchanged.
      foreach ($x in ($extents | Sort-Object StartOffset -Descending)) {
        $rl::Replace($x.StartOffset, $x.EndOffset - $x.StartOffset, $globalAliases[$x.Text])
      }
    }
    # Enter's default functions: AcceptLine in insert mode, ViAcceptLine in
    # command mode (which also switches back to insert mode).
    if ($rl::InViCommandMode()) { $rl::ViAcceptLine($key, $arg) } else { $rl::AcceptLine($key, $arg) }
  }.GetNewClosure()
  foreach ($mode in 'Insert', 'Command') {
    Set-PSReadLineKeyHandler -Chord Enter -ViMode $mode -ScriptBlock $expandAndAccept `
      -BriefDescription ExpandGlobalAliasesAndAccept `
      -Description 'Expand global aliases (H, T, L, LL, NE, NUL, V), then accept the line'
  }
  Remove-Variable globalAliases, pager, expandAndAccept, mode

  # K shows help for the command under the cursor (cf. run-help); F1 also works.
  Set-PSReadLineKeyHandler -Chord K -ViMode Command -Function ShowCommandHelp

  # rationalise-dot (from zsh-lovers): typing a dot after '..' inserts '\..'
  # instead, so '...' becomes '..\..' and '....' becomes '..\..\..'. Unlike
  # the Zsh version, this happens only when the '..' begins a word: at the
  # start of the line, or after whitespace, a quote or a path separator. So
  # 'cd ...' still becomes 'cd ..\..', but git's three-dot syntax, as in
  # 'git diff main...feature', is typed as is. Only bound in insert mode; '.'
  # in command mode still repeats the last change.
  Set-PSReadLineKeyHandler -Chord . -ViMode Insert -ScriptBlock {
    $line = $null; $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($cursor -ge 2 -and $line.Substring($cursor - 2, 2) -eq '..' -and
        ($cursor -eq 2 -or $line[$cursor - 3] -match '[\s''"\\/]')) {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert([IO.Path]::DirectorySeparatorChar + '..')
    } else {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert('.')
    }
  }
}

# AUTO_CD: typing the name or path of a directory as a command changes to it.
# PowerShell calls CommandNotFoundAction after it fails to find a command by
# that name. If the name is an existing directory, the handler supplies a
# script block to run in place of the command and stops the search.
# CommandOrigin is 'Runspace' only for commands typed at the prompt; inside
# scripts it is 'Internal', so scripts still get the usual "not recognized"
# error rather than a silent change of directory. (The second parameter isn't
# called $EventArgs because that is the name of an automatic variable.)
$ExecutionContext.InvokeCommand.CommandNotFoundAction = {
  param([string]$CommandName, [Management.Automation.CommandLookupEventArgs]$LookupArgs)
  if ($LookupArgs.CommandOrigin -ne 'Runspace') { return }
  if (Test-Path -LiteralPath $CommandName -PathType Container) {
    $LookupArgs.CommandScriptBlock = { Set-Location -LiteralPath $CommandName }.GetNewClosure()
    $LookupArgs.StopSearch = $true
  }
}

# Chocolatey profile, loaded on first use
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path $ChocolateyProfile) {
  function Import-ChocolateyProfile {
    Import-Module $ChocolateyProfile -Global
    Get-Module chocolateyProfile
  }

  # The module defines refreshenv as an alias. Aliases take precedence over
  # functions, so once the module is loaded this stub is never called again.
  function refreshenv {
    $null = Import-ChocolateyProfile
    Update-SessionEnvironment
  }

  # The module registers its own completer for choco, which replaces this one.
  # For the first completion, call the module's internal ChocolateyTabExpansion
  # by running a script block in the module's scope (& $module { ... }).
  Register-ArgumentCompleter -Native -CommandName choco -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorColumn)
    $m = Import-ChocolateyProfile
    # Same preparation the module's completer does: cut the command line at
    # the cursor and restore trailing spaces that the AST string drops.
    $line = [string]$commandAst
    $line = $line.Substring(0, [Math]::Min($line.Length, $cursorColumn))
    $line += ' ' * ($cursorColumn - $line.Length)
    & $m { ChocolateyTabExpansion $args[0] } $line
  }
}

# posh-git tab completion, loaded the first time Tab is pressed after git.
# Importing posh-git takes about 390 ms, so it isn't imported at startup.
# posh-git replaces the prompt function only if the current one is
# PowerShell's default, so the Polyglot prompt is left alone.
#
# In PowerShell 7, importing posh-git registers its own completer for these
# commands, which replaces this one. In Windows PowerShell 5.1, posh-git
# instead defines the older TabExpansion function, so this completer stays
# registered and keeps calling posh-git's Expand-GitCommand, which is what
# posh-git's own completer calls.
#
# There is no check here that posh-git is installed: Get-Module -ListAvailable
# takes 30-50 ms, longer than registering the completer. Instead, if the
# import fails, the completer returns nothing and PowerShell falls back to
# its ordinary completion; -ErrorAction Ignore keeps the import error from
# being printed over the command line.
Register-ArgumentCompleter -Native -CommandName git, tgit, gitk -ScriptBlock {
  param($wordToComplete, $commandAst, $cursorPosition)
  if (-not (Get-Module posh-git)) {
    Import-Module posh-git -Global -ErrorAction Ignore
    if (-not (Get-Module posh-git)) { return }
  }
  # As in posh-git's completer: cut the command line at the cursor and pad it
  # with spaces, because the AST string drops the trailing space that tells
  # Expand-GitCommand a new argument has started.
  $padLength = $cursorPosition - $commandAst.Extent.StartOffset
  $text = $commandAst.ToString().PadRight($padLength, ' ').Substring(0, $padLength)
  Expand-GitCommand $text
}

if (Get-Command vim -ErrorAction Ignore) {
  Set-Alias vi vim
  # As in .profile. Pressing v in vi command mode (ViEditVisually) opens the
  # command line in $env:VISUAL, falling back to $env:EDITOR.
  if (-not $env:EDITOR) { $env:EDITOR = 'vim' }
  if (-not $env:VISUAL) { $env:VISUAL = $env:EDITOR }
}

# File colors from ~/.dircolors, the Zenburn colors that .shrc gives GNU ls
# through dircolors and LS_COLORS. PowerShell 7.2 and later color the names in
# Get-ChildItem's output according to $PSStyle.FileInfo, which has a color
# for directories, one for symbolic links, one for executables (on Windows,
# files whose extension is in PATHEXT), and one per file extension.
#
# Each color in .dircolors is the inside of an SGR escape sequence, so it is
# wrapped in ESC [ ... m here. Only the DIR, LINK and EXEC lines and the lines
# for extensions ('.zip 01;38;5;174') have a counterpart in $PSStyle.FileInfo.
# File types that Windows doesn't have (FIFO, SOCK, SETUID and the like) and
# patterns such as '*rc' or '*~' are skipped. PowerShell's own default
# extension colors (for .zip, .ps1 and a few more) are removed first, so that
# all colors come from .dircolors, as they do for ls in Zsh.
#
# The extension table ignores case, and .dircolors lists some extensions in
# both cases (.jpg and .JPG), so an existing entry is removed before adding.
if ($PSStyle -and (Test-Path -LiteralPath "$HOME\.dircolors")) {
  $fileInfo = $PSStyle.FileInfo
  $fileInfo.Extension.Clear()
  switch -Regex -File "$HOME\.dircolors" {
    '^DIR\s+([\d;]+)'  { $fileInfo.Directory    = "`e[$($Matches[1])m" }
    '^LINK\s+([\d;]+)' { $fileInfo.SymbolicLink = "`e[$($Matches[1])m" }
    '^EXEC\s+([\d;]+)' { $fileInfo.Executable   = "`e[$($Matches[1])m" }
    '^(\.\S+)\s+([\d;]+)' {
      if ($fileInfo.Extension.ContainsKey($Matches[1])) { $fileInfo.Extension.Remove($Matches[1]) }
      $fileInfo.Extension.Add($Matches[1], "`e[$($Matches[2])m")
    }
  }
  Remove-Variable fileInfo
}

# ls aliases from .shrc, as functions over Get-ChildItem, so that they output
# file objects rather than text. Arguments are passed to Get-ChildItem, so
# 'lt C:\Windows' and 'll -Recurse' work.
#
# - Get-ChildItem's usual table already gives the long format of ls -l, so
#   'la' (ls -A) and 'll' (ls -alF) are the same command: -Force includes
#   hidden files.
# - 'l' (ls -CF) lists names in columns. It uses NameString, which holds the
#   name with its $PSStyle.FileInfo color; the Name property has no color.
# - The time-sorted ones sort by LastWriteTime. lrt and lart use ls -c,
#   which sorts by the inode change time, but PowerShell doesn't expose
#   NTFS's equivalent, so these sort by modification time too.
# - lS (ls -1FSsh) is left out: PowerShell command names ignore case, and ls
#   is a built-in alias, which takes precedence over a function named lS.
function l    { Get-ChildItem @args | Format-Wide -Property NameString -AutoSize }
function la   { Get-ChildItem -Force @args }
function ll   { Get-ChildItem -Force @args }
function lt   { Get-ChildItem @args | Sort-Object LastWriteTime -Descending }
function lrt  { Get-ChildItem @args | Sort-Object LastWriteTime }
function lart { Get-ChildItem -Force @args | Sort-Object LastWriteTime }
function ldot { Get-ChildItem -Force @args | Where-Object Name -like '.*' }
# ls -tRFh: recursive, newest first within each directory. Sorting by the
# parent directory first keeps each directory's files together, and
# Get-ChildItem's table prints a "Directory:" heading wherever the parent
# changes.
function lr {
  Get-ChildItem -Recurse @args |
    Sort-Object { $_.PSParentPath }, @{ Expression = 'LastWriteTime'; Descending = $true }
}

# Named directories (cf. hash -d in .zshrc), as PowerShell drives. After
# 'New-PSDrive agk FileSystem <dir>', the path agk:\functions means
# <dir>\functions, 'cd agk:' changes to <dir>, and because of AUTO_CD above,
# typing just 'agk:' does too. polyglot-prompt.ps1 shows such a location as
# agk:\..., as Zsh shows ~agk/.... The names are the ones in .zshrc, except
# that ~z becomes zshz: because a one-letter name would look like (and could
# collide with) a Windows drive letter. ~w isn't needed, because $WINHOME
# in Zsh is $HOME here. A drive is created only if its directory exists.
#
# The drives are created through the session state API that New-PSDrive
# itself uses. For these three drives that took about 9 ms here, against
# about 37 ms for three New-PSDrive calls.
#
# A drive that already exists is left alone, because Drive.New throws "A
# drive with the name 'agk' already exists" when the profile is run a second
# time in the same session (. $PROFILE).
$fileSystem = $ExecutionContext.SessionState.Provider.GetOne('FileSystem')
$existingDrives = @($ExecutionContext.SessionState.Drive.GetAllAtScope('Global').Name)
foreach ($namedDir in @(
    @{ Name = 'agk';        Root = "$HOME\.zcomet\repos\agkozak\agkozak-zsh-prompt" }
    @{ Name = 'zshz';       Root = "$HOME\.zcomet\repos\agkozak\zsh-z" }
    @{ Name = 'zc';         Root = "$HOME\.zcomet\bin" }
    @{ Name = 'wp-content'; Root = "$HOME\public_html\wp-content" })) {
  if ($namedDir.Name -notin $existingDrives -and [IO.Directory]::Exists($namedDir.Root)) {
    $drive = [Management.Automation.PSDriveInfo]::new($namedDir.Name, $fileSystem, $namedDir.Root, '', $null)
    $null = $ExecutionContext.SessionState.Drive.New($drive, 'Global')
  }
}
Remove-Variable fileSystem, existingDrives, namedDir, drive -ErrorAction Ignore

# Directory stack (cf. AUTO_PUSHD and PUSHD_IGNORE_DUPS in .zshrc).
# $DirStack holds the previous locations, most recent first, as Zsh's
# $dirstack does. It is updated each time the prompt is drawn: if the current
# location differs from the one at the previous prompt, the previous one is
# put at the front, and any other copies of it or of the current location
# are removed. Recording at the prompt, rather than in cd, means every way of
# changing directory counts (cd, z, AUTO_CD, Set-Location in a function),
# while a script that changes directory and changes back before the next
# prompt leaves no entries.
#
#   dirs        the current location and the stack on one line
#   dirs -v     the same, one per line, numbered from 0 (the current one)
#   dirs -p     one per line, unnumbered;  -l: without ~ abbreviation
#   dirs -c     clear the stack
#   cd +N       go to entry N of 'dirs -v'
#   cd -N       go to entry N counting from the end of the list (0 = last)
#
# Differences from Zsh: 'cd +N' moves entry N to the front rather than
# rotating the stack, and a plain 'cd -' or 'cd +' is PowerShell's own
# location history (each 'cd -' goes one step further back, instead of
# alternating between two directories as in Zsh); 'cd +1' alternates.
# Everything else given to cd is passed to Set-Location, except pipeline
# input ('Get-Item x | cd' needs Set-Location). cd is a built-in alias with the
# AllScope option, so it must be removed with -Force before a function of
# that name can be called. When the profile is run again in the same session,
# the alias is already gone, hence -ErrorAction Ignore on the removal.
#
# When the profile is run again in the same session (. $PROFILE), the
# existing stack is kept rather than replaced by an empty one.
if ($DirStack -isnot [Collections.Generic.List[string]]) {
  $DirStack = [Collections.Generic.List[string]]::new()
  $DirStackPwd = $PWD.Path
}

function Update-DirStack {
  $here = $PWD.Path
  $old = $global:DirStackPwd
  if ($here -eq $old) { return }
  $global:DirStackPwd = $here
  # RemoveAll takes a Predicate[string]; PowerShell converts the script
  # block. -eq ignores case, as Windows paths do.
  $null = $global:DirStack.RemoveAll({ param($p) $p -eq $here -or $p -eq $old })
  $global:DirStack.Insert(0, $old)
}

# Add Update-DirStack to the prompt by wrapping the prompt function, as
# zoxide's init script does below. The old prompt runs first, so that it
# still sees $? from the last command.
#
# $DirStackHooked records that the prompt has been wrapped, as zoxide's
# $__zoxide_hooked does. Without it, each further run of the profile in the
# same session would wrap the already wrapped prompt again, and
# Update-DirStack would run once more per prompt for every run.
if (-not $DirStackHooked) {
  $DirStackHooked = $true
  $dirStackPrompt = $function:prompt
  $function:prompt = {
    & $dirStackPrompt
    Update-DirStack
  }.GetNewClosure()
  Remove-Variable dirStackPrompt
}

function dirs {
  $flags = -join ($args | ForEach-Object { "$_".TrimStart('-') })
  if ($flags.Contains('c')) { $global:DirStack.Clear(); return }
  $list = @($PWD.Path) + $global:DirStack
  if (-not $flags.Contains('l')) {
    $list = foreach ($p in $list) {
      if ($p -eq $HOME) { '~' }
      elseif ($p.StartsWith("$HOME\", [StringComparison]::OrdinalIgnoreCase)) { '~' + $p.Substring($HOME.Length) }
      else { $p }
    }
  }
  if ($flags.Contains('v')) {
    for ($i = 0; $i -lt $list.Count; $i++) { "$i`t$($list[$i])" }
  } elseif ($flags.Contains('p')) {
    $list
  } else {
    $list -join ' '
  }
}

Remove-Item Alias:cd -Force -ErrorAction Ignore
function cd {
  # The parameters are declared, rather than all arguments being taken from
  # $args, so that the completer registered below can complete -Path.
  # Arguments that match no parameter (-PassThru, -ErrorAction) end up in
  # $args and are passed on. That works only because this is a simple
  # function: a [Parameter()] or [CmdletBinding()] attribute would make it an
  # advanced function, which rejects parameters it doesn't declare.
  param([string]$Path, [string]$LiteralPath)
  if ($Path -match '^([+-])(\d+)$') {
    $list = @($PWD.Path) + $global:DirStack
    $n = [int]$Matches[2]
    $i = if ($Matches[1] -eq '+') { $n } else { $list.Count - 1 - $n }
    if ($i -lt 0 -or $i -ge $list.Count) {
      Write-Error "cd: no such entry in dir stack: $Path"
      return
    }
    Set-Location -LiteralPath $list[$i]
    return
  }
  Set-Location @PSBoundParameters @args
}

# PowerShell completes only directories after Set-Location and its aliases,
# but after a function it completes every file name. This completer restores
# the directories-only behavior: CompleteFilename returns the same matches
# (quoted where necessary) as ordinary path completion, and only the
# containers among them are kept.
Register-ArgumentCompleter -CommandName cd -ParameterName Path -ScriptBlock {
  param($commandName, $parameterName, $wordToComplete)
  [Management.Automation.CompletionCompleters]::CompleteFilename($wordToComplete) |
    Where-Object ResultType -eq ProviderContainer
}

# hgrep: search the command history (cf. alias hgrep='fc -fl 0 | grep' in
# .zshrc). The pattern is a regular expression and, like -match, ignores
# case unless -CaseSensitive is given: 'hgrep git.*push'.
#
# The history searched is PSReadLine's: the commands it read from its
# history file at startup (up to its MaximumHistoryCount, set to 32767
# above) and those entered since, apart from the hgrep command itself.
# These are the same commands that Up, Ctrl-R and the substring search go
# through. A command that was run more than once is listed once, in the
# place of its latest use. The list runs from oldest to newest, so the
# newest match is just above the prompt.
#
# When hgrep is the last command of its pipeline, so that its output goes to
# the screen, each match is highlighted in the color that GREP_COLORS (in
# .shrc) gives grep's matches. When it is piped to another command, the
# lines are plain text without escape sequences. (Assigning its output to a
# variable, as in '$x = hgrep foo', counts as the last command, so the
# variable gets the escape sequences.)
function hgrep {
  param([Parameter(Mandatory)][string]$Pattern, [switch]$CaseSensitive)
  $regex = [regex]::new($Pattern, $(if ($CaseSensitive) { 'None' } else { 'IgnoreCase' }))
  $commands = @([Microsoft.PowerShell.PSConsoleReadLine]::GetHistoryItems().CommandLine)
  $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  $found = [Collections.Generic.List[string]]::new()
  # PSReadLine adds a command line to the history before running it, so the
  # newest item is normally the line that called hgrep. It is skipped, as
  # fc -l leaves out the current command, if it contains the line of the
  # call ($MyInvocation.Line).
  $last = $commands.Count - 1
  if ($last -ge 0 -and $MyInvocation.Line -and $commands[$last].Contains($MyInvocation.Line)) { $last-- }
  for ($i = $last; $i -ge 0; $i--) {
    if ($regex.IsMatch($commands[$i]) -and $seen.Add($commands[$i])) { $found.Add($commands[$i]) }
  }
  $found.Reverse()
  if ($MyInvocation.PipelinePosition -lt $MyInvocation.PipelineLength) { return $found }
  $on = "`e[48;5;22;38;5;230;1m"; $off = "`e[0m"
  foreach ($command in $found) { $regex.Replace($command, { param($m) "$on$($m.Value)$off" }) }
}

# which: what a command name runs (cf. Zsh's which). PowerShell's
# Get-Command finds it; this prints the result in the style of Zsh's which:
#
#   alias        'll: aliased to Get-ChildItem'
#   function     its definition, 'function l { ... }'
#   cmdlet       'Get-ChildItem: cmdlet from Microsoft.PowerShell.Management'
#   program or script   its path
#
# Without -All (-a), only the command that PowerShell would run is shown.
# The order of precedence is alias, then function, then cmdlet, then
# programs and scripts on PATH in PATH order. With -a, every command of that
# name is shown in that order. A name that matches nothing gives the error
# '<name> not found', and $? is then false. Wildcards work as they do in
# Get-Command: 'which -a *zoxide*'.
function which {
  param([switch]$All, [Parameter(ValueFromRemainingArguments)][string[]]$Name)
  foreach ($n in $Name) {
    $found = @(Get-Command -Name $n -All:$All -ErrorAction Ignore)
    if (-not $found) {
      # $PSCmdlet.WriteError, unlike Write-Error, also sets the caller's $?
      # to false.
      $PSCmdlet.WriteError([Management.Automation.ErrorRecord]::new(
        [Exception]::new("$n not found"), 'NotFound', 'ObjectNotFound', $n))
      continue
    }
    foreach ($c in $found) {
      switch ($c.CommandType) {
        'Alias'  { "$($c.Name): aliased to $($c.Definition)"; break }
        'Cmdlet' { "$($c.Name): cmdlet from $($c.Source)"; break }
        { $_ -in 'Function', 'Filter' } { "function $($c.Name) {$($c.Definition)}"; break }
        default  { if ($c.Source) { $c.Source } else { $c.Definition } }
      }
    }
  }
}

# open: open files, directories and URLs with their default programs (cf.
# open() in .zshrc, which calls explorer.exe on WSL and MSYS2). A directory
# opens in Explorer, so 'open .' shows the current directory there; with no
# arguments, Explorer opens at its start page, as explorer.exe does in Zsh.
#
# An argument that exists as a path (including PowerShell drive paths such as
# agk:\README.md) is opened with Invoke-Item. Otherwise an argument that
# begins with a URL scheme ('https:', 'mailto:') is passed to Start-Process,
# which opens it with the program registered for the scheme. A scheme is at
# least two characters long and is not the name of a PowerShell drive, so
# 'C:\x' and 'agk:\x' never count as URLs. Anything else goes to Invoke-Item
# as a wildcard pattern, so 'open *.pdf' opens every PDF in the directory
# (and a name that matches nothing gives Invoke-Item's error).
function open {
  if (-not $args) { Start-Process explorer.exe; return }
  foreach ($item in $args) {
    $item = "$item"
    if (Test-Path -LiteralPath $item) {
      Invoke-Item -LiteralPath $item
    } elseif ($item -match '^([a-z][a-z0-9+.-]+):' -and
              -not (Get-PSDrive -Name $Matches[1] -ErrorAction Ignore)) {
      Start-Process $item
    } else {
      Invoke-Item -Path $item
    }
  }
}

# unarchive, x, extract: unpack archives (cf. prezto's unarchive, which
# .zshrc loads with the aliases x and extract). It follows prezto's choices
# of where things go:
#
# - tar archives, compressed or not (.tar, .tar.gz, .tgz, .tar.bz2, .tbz,
#   .tbz2, .tar.xz, .txz, .tar.lzma, .tlz, .tar.zst, .tzst) and .7z archives
#   are unpacked into the current directory.
# - .zip, .jar and .rar archives are unpacked into a new directory in the
#   current directory, named after the archive without its extension
#   (foo.zip -> foo\).
# - A .deb package is unpacked into <name>\control and <name>\data.
# - A single compressed file (.gz, .Z, .bz2, .xz, .lzma, .zst) is
#   decompressed next to itself, and the compressed file is removed, as
#   gunzip does (foo.txt.gz -> foo.txt). Prezto doesn't handle a lone .zst;
#   it is added here.
#
# -Remove (-r) deletes each archive after it has been unpacked without
# errors. Wildcards work: 'x *.zip'.
#
# Archives are unpacked by Windows' own tar.exe (bsdtar, built on
# libarchive), which reads all of the archive formats and compression
# methods above. The tar.exe of Git or MSYS2 isn't used, because it can't
# read .zip, .7z or .rar. bsdtar doesn't decompress a file that isn't an
# archive, so for single files gzip, bzip2, xz or zstd is run instead. Each
# is looked for on PATH and then in Git for Windows' usr\bin and MSYS2's
# usr\bin, which aren't on PATH. As installed here, Git has gzip and bzip2,
# and MSYS2 has all four. These MSYS programs accept Windows paths.
function unarchive {
  param([switch]$Remove, [Parameter(ValueFromRemainingArguments)][string[]]$Path)
  if (-not $Path) {
    Write-Host 'usage: unarchive [-Remove] <archive>...   (aliases x and extract; -r for -Remove)'
    return
  }
  $tar = "$env:SystemRoot\System32\tar.exe"
  # $PSCmdlet.WriteError, unlike Write-Error, also sets the caller's $? to
  # false, so '$?' after x is false if any archive failed.
  $fail = {
    param($message, $target)
    $PSCmdlet.WriteError([Management.Automation.ErrorRecord]::new(
      [Exception]::new($message), 'UnarchiveFailed', 'InvalidData', $target))
  }
  $findTool = {
    param($name)
    $cmd = Get-Command $name -CommandType Application -ErrorAction Ignore | Select-Object -First 1
    if ($cmd) { return $cmd.Source }
    foreach ($dir in "$env:ProgramFiles\Git\usr\bin", 'C:\msys64\usr\bin') {
      if ([IO.File]::Exists("$dir\$name.exe")) { return "$dir\$name.exe" }
    }
  }
  foreach ($p in $Path) {
    $files = if (Test-Path -LiteralPath $p -PathType Leaf) { Get-Item -LiteralPath $p }
             else { Get-Item -Path $p -ErrorAction Ignore | Where-Object { -not $_.PSIsContainer } }
    if (-not $files) { & $fail "file not valid: $p" $p; continue }
    foreach ($file in $files) {
      if ($file.Length -eq 0) { & $fail "file not valid: $($file.Name)" $file.FullName; continue }
      $full = $file.FullName
      $dir = Join-Path $PWD.ProviderPath $file.BaseName
      # $ok stays $null if no program was run, and is otherwise whether the
      # programs ran without errors.
      $ok = $null
      # switch -Regex ignores case, so .ZIP and .Tar.Gz match too.
      switch -Regex ($file.Name) {
        '\.(tar(\.(gz|bz2|xz|lzma|zst))?|tgz|tbz2?|txz|tlz|tzst|7z)$' {
          & $tar -xvf $full; $ok = $LASTEXITCODE -eq 0; break
        }
        '\.(zip|jar|rar)$' {
          New-Item -ItemType Directory -Force -Path $dir | Out-Null
          & $tar -xvf $full -C $dir; $ok = $LASTEXITCODE -eq 0; break
        }
        '\.deb$' {
          # A .deb is an ar archive of debian-binary, control.tar.* and
          # data.tar.*; the two tar archives are unpacked into their own
          # directories and then deleted, as prezto does.
          New-Item -ItemType Directory -Force -Path "$dir\control", "$dir\data" | Out-Null
          & $tar -xf $full -C $dir; $ok = $LASTEXITCODE -eq 0
          foreach ($part in 'control', 'data') {
            foreach ($inner in Get-ChildItem -LiteralPath $dir -Filter "$part.tar.*") {
              & $tar -xvf $inner.FullName -C "$dir\$part"; $ok = $ok -and $LASTEXITCODE -eq 0
              Remove-Item -LiteralPath $inner.FullName
            }
          }
          Remove-Item -LiteralPath "$dir\debian-binary" -ErrorAction Ignore
          break
        }
        '\.(gz|bz2|xz|lzma|zst|Z)$' {
          # The first word is the program, the rest its arguments.
          $tool, $toolArgs = switch -Regex ($file.Extension) {
            '^\.(gz|Z)$'    { 'gzip', '-d' }
            '^\.bz2$'       { 'bzip2', '-d' }
            '^\.(xz|lzma)$' { 'xz', '-d' }
            '^\.zst$'       { 'zstd', '-d', '--rm' }
          }
          $exe = & $findTool $tool
          if (-not $exe) { & $fail "$tool not found, needed for $($file.Name)" $full; break }
          & $exe $toolArgs $full; $ok = $LASTEXITCODE -eq 0; break
        }
        default { & $fail "cannot extract: $($file.Name)" $full }
      }
      if ($ok -eq $false) { & $fail "errors while extracting $($file.Name)" $full }
      if ($ok -and $Remove -and (Test-Path -LiteralPath $full)) { Remove-Item -LiteralPath $full }
    }
  }
}
Set-Alias x unarchive
Set-Alias extract unarchive

# Host name completion for ssh, scp, sftp and mosh from the Host lines of
# ~/.ssh/config (cf. the users-hosts style for ssh and mosh in .zshrc, and
# compdef mosh=ssh). Patterns such as 'Host *' are skipped. The file is read
# at each Tab, so a new Host entry can be completed at once. Files named in
# Include lines aren't read (the config has none at present).
#
# Which word gets host names:
#
# - ssh, sftp and mosh: the first argument that isn't an option. A word that
#   follows ssh's destination is part of the remote command, so it gets the
#   ordinary file name completion.
# - scp: any argument, since each one may be remote. A host is completed as
#   'host:', ready for the remote path, and local file names are offered
#   after the hosts. A word that already contains ':', '\' or '/' is left to
#   file name completion.
# - The argument of -J (the jump host) also gets host names. The argument of
#   any other option that takes one (such as -i identity_file or -p port) is
#   left to file name completion. Which options take an argument is listed
#   per command below, from their OpenSSH manual pages.
#
# A word that starts with 'user@' keeps that prefix: 'ssh me@ser<Tab>'.
Register-ArgumentCompleter -Native -CommandName ssh, ssh.exe, scp, scp.exe, sftp, sftp.exe, mosh -ScriptBlock {
  param($wordToComplete, $commandAst, $cursorPosition)
  $config = "$HOME\.ssh\config"
  if (-not [IO.File]::Exists($config)) { return }
  $command = [IO.Path]::GetFileNameWithoutExtension($commandAst.GetCommandName())
  $takesArgument = switch ($command) {
    'ssh'   { 'BbcDEeFIiJLlmOoPpQRSWw' }
    'scp'   { 'cDFiJloPSX' }
    'sftp'  { 'BbcDFiJloPRSX' }
    default { 'p' }   # mosh; its other options are long ones such as --ssh=
  }

  # Go through the words before the one being completed. $pending is the
  # option letter whose argument is still to come, and $positionals counts
  # the arguments that aren't options. In a group of letters such as -vp,
  # only the last letter can take the next word as its argument; an earlier
  # one takes the rest of the word ('-p22').
  $pending = $null; $positionals = 0
  foreach ($element in $commandAst.CommandElements | Select-Object -Skip 1) {
    if ($element.Extent.EndOffset -ge $cursorPosition) { break }
    $text = $element.Extent.Text
    if ($pending) { $pending = $null }
    elseif ($text -match '^-(\w+)$') {
      $letters = $Matches[1]
      for ($i = 0; $i -lt $letters.Length; $i++) {
        if ($takesArgument.Contains($letters[$i])) {
          if ($i -eq $letters.Length - 1) { $pending = $letters[$i] }
          break
        }
      }
    }
    elseif (-not $text.StartsWith('-')) { $positionals++ }
  }
  if ($pending -and $pending -cne 'J') { return }
  if ($wordToComplete.StartsWith('-')) { return }
  $scp = $command -eq 'scp' -and -not $pending
  if (-not $scp -and -not $pending -and $positionals -gt 0) { return }
  if ($scp -and $wordToComplete -match '[:\\/]') { return }

  $user = ''; $word = $wordToComplete
  if ($word -match '^(.*@)(.*)$') { $user = $Matches[1]; $word = $Matches[2] }
  $hosts = foreach ($line in [IO.File]::ReadLines($config)) {
    if ($line -match '^\s*Host(?:\s*=\s*|\s+)(.*)$') {
      -split $Matches[1] | Where-Object { $_ -notmatch '[*?!]' }
    }
  }
  foreach ($h in $hosts | Sort-Object -Unique) {
    if ($h.StartsWith($word, [StringComparison]::OrdinalIgnoreCase)) {
      $text = $user + $h + $(if ($scp) { ':' } else { '' })
      [Management.Automation.CompletionResult]::new($text, $h, 'ParameterValue', $h)
    }
  }
  if ($scp -and -not $user) {
    [Management.Automation.CompletionCompleters]::CompleteFilename($wordToComplete)
  }
}

# Cached program output. Some programs print PowerShell code that sets them
# up (zoxide's init script, the Vivid 78s completion scripts). Running such a
# program at every startup costs a process launch, so its output is kept in a
# file under ${XDG_CACHE_HOME:-~/.cache}/agkdot, the directory .profile uses
# for its own cache, and regenerated only when it may be out of date.
$AgkdotCache = Join-Path $(if ($env:XDG_CACHE_HOME) { $env:XDG_CACHE_HOME } else { "$HOME\.cache" }) 'agkdot'

# Update-CommandOutputCache: make sure a cache file holds a program's current
# output, as .zshrc.local does for the Vivid 78s Zsh completions.
#
# The file is regenerated when it is missing or empty, or when the program
# or any of the -DependsOn files was modified after it. For a program
# installed as a symbolic link (as WinGet installs zoxide), the newer of the
# link's and its target's modification times counts. The output is written
# to a temporary file that replaces the cache only if the program exits with
# code 0 and prints something, so a failed run leaves an older cache in
# place. Returns $true if a usable cache file exists afterwards.
#
# The program's output is decoded as UTF-8: [Console]::OutputEncoding, which
# PowerShell uses to decode a native program's output, is switched to UTF-8
# while it runs (as zoxide's own __zoxide_bin does). The file is written as
# UTF-8 without a byte order mark, which PowerShell 7 reads as UTF-8.
function Update-CommandOutputCache {
  param(
    [string]$Path,
    [string]$Program,
    [string[]]$Arguments,
    [string[]]$DependsOn
  )
  function Get-WriteTime([string]$File) {
    $info = [IO.FileInfo]::new($File)
    if (-not $info.Exists) { return [datetime]::MinValue }
    $time = $info.LastWriteTimeUtc
    if ($info.LinkTarget) {
      $target = $info.ResolveLinkTarget($true)
      if ($target -and $target.Exists -and $target.LastWriteTimeUtc -gt $time) { $time = $target.LastWriteTimeUtc }
    }
    $time
  }

  $cache = [IO.FileInfo]::new($Path)
  $stale = -not $cache.Exists -or $cache.Length -eq 0
  if (-not $stale) {
    foreach ($file in @($Program) + $DependsOn) {
      if ($file -and (Get-WriteTime $file) -gt $cache.LastWriteTimeUtc) { $stale = $true; break }
    }
  }
  if (-not $stale) { return $true }

  $null = [IO.Directory]::CreateDirectory($cache.DirectoryName)
  $encoding = [Console]::OutputEncoding
  try {
    [Console]::OutputEncoding = [Text.UTF8Encoding]::new()
    $output = & $Program @Arguments
    $code = $LASTEXITCODE
  } finally {
    [Console]::OutputEncoding = $encoding
  }
  if ($code -ne 0 -or -not $output) { return $cache.Exists -and $cache.Length -gt 0 }
  $temp = "$Path.tmp.$PID"
  [IO.File]::WriteAllLines($temp, [string[]]$output)
  Move-Item -LiteralPath $temp -Destination $Path -Force
  $true
}

# Register-ClapCompleterOnFirstUse: load a completion script generated by
# clap (the Rust argument parser used by zoxide and Vivid 78s) the first time
# Tab is pressed after one of the commands, like the posh-git and Chocolatey
# completions above.
#
# Such a script is a single Register-ArgumentCompleter call whose
# -ScriptBlock argument is the completer. This function registers a small
# completer under -CommandName (both the plain and .exe names, say) that, on
# the first Tab:
#
# 1. runs -GetScript, which returns the path of the completion script, or
#    nothing if there is none (it may create or update the script first);
# 2. takes the completer script block out of the parsed script, the argument
#    after -ScriptBlock. Taking the block, rather than running the script,
#    lets this completer register it under all of -CommandName (the script
#    names only one command) and call it for the current Tab;
# 3. registers that block in place of itself, so later Tabs go straight to
#    it, and returns its completions.
#
# If any step fails, the completer returns nothing, and PowerShell falls
# back to its ordinary file name completion. GetNewClosure() makes the
# completer keep this call's $CommandName and $GetScript.
function Register-ClapCompleterOnFirstUse {
  param([string[]]$CommandName, [scriptblock]$GetScript)
  Register-ArgumentCompleter -Native -CommandName $CommandName -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $file = & $GetScript
    if (-not $file) { return }
    $tokens = $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$errors)
    $register = $ast.Find({
        $args[0] -is [Management.Automation.Language.CommandAst] -and
        $args[0].GetCommandName() -eq 'Register-ArgumentCompleter' }, $true)
    if (-not $register) { return }
    $elements = $register.CommandElements
    $completer = $null
    for ($i = 0; $i -lt $elements.Count - 1; $i++) {
      if ($elements[$i] -is [Management.Automation.Language.CommandParameterAst] -and
          $elements[$i].ParameterName -eq 'ScriptBlock') {
        $completer = $elements[$i + 1].ScriptBlock.GetScriptBlock()
      }
    }
    if (-not $completer) { return }
    Register-ArgumentCompleter -Native -CommandName $CommandName -ScriptBlock $completer
    & $completer $wordToComplete $commandAst $cursorPosition
  }.GetNewClosure()
}

# Vivid 78s completions (cf. the Vivid 78s section of .zshrc.local). For each
# program that exists in ~/.cargo/bin, the completion script is the
# program's output for --completions powershell, cached by
# Update-CommandOutputCache, so it is regenerated on the first Tab after the
# program is reinstalled. GetNewClosure() makes each -GetScript block keep
# its own $exe and $file; without it, all three would see the values of the
# loop's last pass.
foreach ($name in 'vivid78s', 'vivid78s-declick', 'vivid78s-declick-lab') {
  $exe = "$HOME\.cargo\bin\$name.exe"
  if (-not [IO.File]::Exists($exe)) { continue }
  $file = Join-Path $AgkdotCache "completions\$name.ps1"
  Register-ClapCompleterOnFirstUse -CommandName $name, "$name.exe" -GetScript {
    if (Update-CommandOutputCache -Path $file -Program $exe -Arguments '--completions', 'powershell') { $file }
  }.GetNewClosure()
}
Remove-Variable name, exe, file -ErrorAction Ignore

# zoxide: z and zi (cf. zsh-z in .zshrc). _ZO_ECHO=1 makes z print the
# directory it changes to (cf. ZSHZ_ECHO=1).
#
# 'zoxide init powershell' prints the script that defines z and zi and hooks
# zoxide into the prompt. Its output depends on the zoxide version and on
# settings such as _ZO_ECHO, which zoxide writes into the script rather than
# reading when z runs. So the cached copy is regenerated when zoxide.exe is
# newer than it, and also when this profile is (the settings are here).
#
# zoxide.exe is looked for first where WinGet installs it, because checking
# whether a file exists is much faster than Get-Command's search of PATH
# (about 16 ms in one measurement here).
$env:_ZO_ECHO = '1'
$zoxide = "$env:LOCALAPPDATA\Microsoft\WinGet\Links\zoxide.exe"
if (-not [IO.File]::Exists($zoxide)) {
  $zoxide = (Get-Command zoxide -CommandType Application -ErrorAction Ignore | Select-Object -First 1).Source
}
if ($zoxide -and (Update-CommandOutputCache -Path "$AgkdotCache\zoxide-init.ps1" -Program $zoxide `
                    -Arguments 'init', 'powershell' -DependsOn $PSCommandPath)) {
  . "$AgkdotCache\zoxide-init.ps1"

  # Completion for the zoxide command itself (its subcommands and options,
  # as in 'zoxide query --list'), from the clap-generated script that the
  # zoxide package ships in completions\_zoxide.ps1 next to zoxide.exe. The
  # WinGet zoxide.exe is a symbolic link into the package's directory, so the
  # link is followed to find that directory. Loaded on first use; see
  # Register-ClapCompleterOnFirstUse above.
  Register-ClapCompleterOnFirstUse -CommandName zoxide, zoxide.exe -GetScript {
    $info = [IO.FileInfo]::new($zoxide)
    $target = if ($info.LinkTarget) { $info.ResolveLinkTarget($true) } else { $info }
    $script = Join-Path $target.DirectoryName 'completions\_zoxide.ps1'
    if ([IO.File]::Exists($script)) { $script }
  }.GetNewClosure()

  # Completion for z from zoxide's database (cf. the completion that zsh-z
  # gives z). zoxide's PowerShell integration has none, so without this,
  # 'z <Tab>' completes file names in the current directory.
  #
  # 'z foo<Tab>' offers the directories that 'zoxide query --list foo'
  # returns, best match first; 'z <Tab>' offers every directory in the
  # database. The current directory is left out, as z leaves it out. A
  # chosen directory replaces the word, so the line becomes 'z <directory>',
  # which z changes to directly, because its one argument is an existing
  # directory.
  #
  # Only the first argument is completed this way. A word after it is left
  # to file name completion (by returning nothing), because replacing only
  # the last of several keywords with a full path would give z a list of
  # keywords that no longer matches anything. Words that look like a path
  # ('..', '.\x', 'C:\x', '~\x') are also left to file name completion, as
  # are completions after z's own options.
  #
  # __zoxide_pwd and __zoxide_bin come from zoxide's init script:
  # __zoxide_pwd gives the current directory in the form zoxide stores
  # (nothing outside the file system), and __zoxide_bin runs zoxide with its
  # output read as UTF-8, so names such as 'Ζοζεφίνα Γενοβέζου' arrive intact.
  # Directories with spaces or characters special to PowerShell are inserted
  # in single quotes, with any single quote doubled.
  Register-ArgumentCompleter -Native -CommandName z -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $elements = $commandAst.CommandElements
    $firstArgument = $elements.Count -eq 1 -or ($elements.Count -eq 2 -and $wordToComplete)
    if (-not $firstArgument) { return }
    $word = $wordToComplete.Trim("'", '"')
    if ($word -match '[\\/:~]' -or $word -match '^\.{1,2}$' -or $word.StartsWith('-')) { return }
    $queryArgs = @('query', '--list')
    $here = __zoxide_pwd
    if ($here) { $queryArgs += '--exclude', $here }
    if ($word) { $queryArgs += '--', $word }
    foreach ($dir in __zoxide_bin @queryArgs) {
      $text = if ($dir -match "[\s'`"``$&(){}@#;,|<>]") { "'" + ($dir -replace "'", "''") + "'" } else { $dir }
      [Management.Automation.CompletionResult]::new($text, $dir, 'ProviderContainer', $dir)
    }
  }
}
Remove-Variable zoxide
