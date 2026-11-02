# Size of the session history that Get-History shows (cf. HISTSIZE in
# .zshrc). 32767 is the largest value allowed; the default is 4096.
$MaximumHistoryCount = 32767

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
    ViModeIndicator     = 'Cursor'
    BellStyle           = 'None'
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
  # one line at a time, and Ctrl-P/Ctrl-N aren't bound. These make Tab show a
  # completion menu, and the others search for earlier lines that begin with
  # the text already typed.
  Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
  Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
  Set-PSReadLineKeyHandler -Chord Ctrl+p -ViMode Insert -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Chord Ctrl+n -ViMode Insert -Function HistorySearchForward
  Set-PSReadLineKeyHandler -Chord k -ViMode Command -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Chord j -ViMode Command -Function HistorySearchForward
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

Invoke-Expression (& { (zoxide init powershell | Out-String) })
