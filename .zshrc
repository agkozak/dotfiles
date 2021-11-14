# ~/.zshrc
#
# https://github.com/agkozak/dotfiles
#
# This dotfile is increasingly arranged according to the order of chapters in
# the Z Shell Manual

# Begin .zshrc benchmarks {{{1

# zprof {{{2
#
# To run zprof, execute
#
#   env ZSH_PROF=1 zsh -ic zprof
(( ZSH_PROF )) && zmodload zsh/zprof
# }}}2

# xtrace {{{2
#
# To run xtrace, execute
#
# AGKDOT_XTRACE=1 zsh
if (( AGKDOT_XTRACE )); then
  (( ${+EPOCHREALTIME} )) || zmodload zsh/datetime
  setopt PROMPT_SUBST
  PS4='+$EPOCHREALTIME %N:%i> '

  logfile=$(mktemp zsh_profile.XXXXXXXX)
  echo "Logging to $logfile"
  exec 3>&2 2>$logfile

  setopt XTRACE
fi
# }}}2

# For simple script running times, execute
#
#     AGKDOT_BENCHMARKS=1
#
# before sourcing.

############################################################
# Print a benchmark message (in red, if possible) to STDERR
#
# Arguments:
#   $1 The message
############################################################
_agkdot_benchmark_message() {
  (( ${terminfo[colors]:-0} >= 8 )) && >&2 print -Pn '%F{red}'
  >&2 print -n -- $@
  (( ${terminfo[colors]:-0} >= 8 )) && >&2 print -Pn '%f'
  >&2 print
}

if (( AGKDOT_BENCHMARKS )); then
  if (( $+AGKDOT_ZSHENV_BENCHMARK )); then
    _agkdot_benchmark_message \
      ".zshenv: ${AGKDOT_ZSHENV_BENCHMARK}ms"
    unset AGKDOT_ZSHENV_BENCHMARK
  fi
fi

# }}}1

autoload -Uz is-at-least

# powerlevel10k Instant Prompt {{{1

# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if is-at-least 5.1 &&
   (( AGKDOT_P10K )) &&
   [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# }}}1

# Source .profile, if necessary {{{1

if [[ $- == *l* && -z $ENV && -f ${HOME}/.profile ]]; then
  if (( AGKDOT_BENCHMARKS )); then
    typeset -g AGKDOT_PROFILE_TOTAL
    typeset -F SECONDS=0
    source "${HOME}/.profile" &&
        print -z -f '%.*f' 1 $(( SECONDS * 1000 )) &&
        read -z AGKDOT_PROFILE_TOTAL &&
        _agkdot_benchmark_message ".profile: ${AGKDOT_PROFILE_TOTAL}ms"
    unset AGKDOT_PROFILE_TOTAL
  else
    source "${HOME}/.profile"
  fi
fi
typeset -F SECONDS=0

# }}}1

# AGKDOT_TERM_COLORS {{{1

AGKDOT_TERM_COLORS=${terminfo[colors]:-0}

# }}}1

# Source ~/.shrc {{{1

if [[ -f ${HOME}/.shrc ]];then
  if (( AGKDOT_BENCHMARKS )); then
    # Try to use zsh's $EPOCHREALTIME to get the benchmarks here rather than
    # using date inside of .shrc
    (( $+EPOCHREALTIME )) || zmodload zsh/datetime
    typeset -g AGKDOT_ZSHRC_START=$(( EPOCHREALTIME * 1000 ))
    AGKDOT_ZSHRC_LOADING=1 source "${HOME}/.shrc"
    typeset -g AGKDOT_SHRC_TOTAL
    print -z -f '%.*f' \
        1 $(( (EPOCHREALTIME * 1000) - AGKDOT_ZSHRC_START ))
    read -z AGKDOT_SHRC_TOTAL
    _agkdot_benchmark_message \
      ".shrc: ${AGKDOT_SHRC_TOTAL}ms"
    unset AGKDOT_ZSHRC_START
  else
    source "${HOME}/.shrc"
  fi
fi

export AGKDOT_SYSTEMINFO
: ${AGKDOT_SYSTEMINFO:=$(uname -a)}

# }}}1

# 6.8 Zsh-specific aliases - POSIX aliases are in .shrc {{{1

# Disable echo escape sequences in MSys2 or Cygwin - variables inherited from
# Windows may have backslashes in them
# [[ $OSTYPE == (msys|cygwin) ]] && alias echo='echo -E'

alias hgrep='fc -fl 0 | grep'
alias ls='ls ${=LS_OPTIONS}'

# which should not be aliased in Zsh
(( ${+aliases[which]} )) && unalias which

# Global Aliases {{{2

# alias -g CA='2>&1 | cat -A'
# alias -g G='| grep' # Interferes with some versions of bashcompinit
alias -g H='| head'

# Prevent pipes to `less' from being pushed into the background on MSYS2 and
# Cygwin

if [[ $OSTYPE == (msys|cygwin) ]] && is-at-least 5.6; then
  less() {
    if [[ -p /dev/fd/0 ]]; then
      (command less $@)
    else
      command less $@
    fi
  }
fi

alias -g L='| less'

alias -g LL='2>&1 | less'
alias -g NE='2> /dev/null'
alias -g NUL='&> /dev/null'
alias -g T='| tail'
alias -g V='|& vim - +AnsiEsc'

# }}}2

# }}}1

# 9.1 Autoloading Functions {{{1

autoload -Uz edit-command-line zmv

# }}}1

# 15.6 Parameters Used by the Shell {{{1

# History environment variables
HISTFILE="${HOME}/.zsh_history"
HISTSIZE=1200000000  # Larger than $SAVEHIST for HIST_EXPIRE_DUPS_FIRST to work
SAVEHIST=1000000000

# In the line editor, number of matches to show before asking permission
LISTMAX=9999

# }}}1

# 16 Options {{{1

# 16.2.1 Changing Directories {{{2

setopt AUTO_CD            # Change to a directory just by typing its name
setopt AUTO_PUSHD         # Make cd push each old directory onto the stack
setopt CDABLE_VARS        # Like AUTO_CD, but for named directories
setopt PUSHD_IGNORE_DUPS  # Don't push duplicates onto the stack

# }}}2

# 16.2.2 Completion {{{2

setopt NO_LIST_BEEP       # Don't beep on an ambiguous completion
setopt LIST_PACKED        # Use columns of varying widths

# }}}2

# 16.2.4 History {{{2

setopt EXTENDED_HISTORY       # Save time stamps and durations

# Old installments of CloudLinux have a /bin/zsh whose history file will not
# work because of CageFS and SecureLinks. When necessary, disable the history
# file rather than experience constant error messages.
() {
  setopt EQUALS

  if [[ -f '/var/.cagefs/.cagefs.token' && $ZSH_VERSION == 4.3.11 ]]; then
    unset HISTFILE
  # A custom build of Zsh on CloudLinux may require HIST_FCNTL_LOCK
  # See https://gist.github.com/agkozak/50a9bf7da14b9f060c68124418ac5217
  elif [[ =zsh == '/bin/zsh' ]]; then
    setopt HIST_FCNTL_LOCK
  fi
}

setopt HIST_IGNORE_SPACE    # Ignore command lines with leading spaces
setopt HIST_VERIFY          # Reload results of history expansion before executing
setopt SHARE_HISTORY        # Constantly share history between shell instances

# }}}2

# 16.2.6 Input/Output {{{2

setopt NO_FLOW_CONTROL      # Free up Ctrl-Q and Ctrl-S
setopt INTERACTIVE_COMMENTS # Allow comments in interactive mode

# }}}2

# 16.2.7 Job Control {{{2

# Do not run background jobs at a lower priority
setopt NO_BG_NICE

# }}}2

# 16.2.12 Zle {{{2

setopt NO_BEEP

# }}}2

# }}}1

# # The Debian solution to Del/Home/End/etc. keybindings {{{1

# No need to run the following code if I'm using a Debian-based distro
if [[ ! -f /etc/debian_version ]]; then

  typeset -A key
  key=(
    BackSpace  "${terminfo[kbs]}"
    Home       "${terminfo[khome]}"
    End        "${terminfo[kend]}"
    Insert     "${terminfo[kich1]}"
    Delete     "${terminfo[kdch1]}"
    Up         "${terminfo[kcuu1]}"
    Down       "${terminfo[kcud1]}"
    Left       "${terminfo[kcub1]}"
    Right      "${terminfo[kcuf1]}"
    PageUp     "${terminfo[kpp]}"
    PageDown   "${terminfo[knp]}"
  )

  function bind2maps() {
    local i sequence widget
    local -a maps

    while [[ $1 != '--' ]]; do
      maps+=( "$1" )
      shift
    done
    shift

    sequence="${key[$1]}"
    widget="$2"

    [[ -z $sequence ]] && return 1

    for i in "${maps[@]}"; do
      bindkey -M "$i" "$sequence" "$widget"
    done
  }

  bind2maps emacs             -- BackSpace   backward-delete-char
  bind2maps       viins       -- BackSpace   vi-backward-delete-char
  bind2maps             vicmd -- BackSpace   vi-backward-char
  bind2maps emacs             -- Home        beginning-of-line
  bind2maps       viins vicmd -- Home        vi-beginning-of-line
  bind2maps emacs             -- End         end-of-line
  bind2maps       viins vicmd -- End         vi-end-of-line
  bind2maps emacs viins       -- Insert      overwrite-mode
  bind2maps             vicmd -- Insert      vi-insert
  bind2maps emacs             -- Delete      delete-char
  bind2maps       viins vicmd -- Delete      vi-delete-char
  bind2maps emacs viins vicmd -- Up          up-line-or-history
  bind2maps emacs viins vicmd -- Down        down-line-or-history
  bind2maps emacs             -- Left        backward-char
  bind2maps       viins vicmd -- Left        vi-backward-char
  bind2maps emacs             -- Right       forward-char
  bind2maps       viins vicmd -- Right       vi-forward-char

  # Make sure the terminal is in application mode, when zle is
  # active. Only then are the values from $terminfo valid.
  if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
    function zle-line-init() {
      emulate -L zsh
      printf '%s' "${terminfo[smkx]}"
    }
    function zle-line-finish() {
      emulate -L zsh
      printf '%s' "${terminfo[rmkx]}"
    }
    zle -N zle-line-init
    zle -N zle-line-finish
  else
    for i in {s,r}mkx; do
      (( ${+terminfo[$i]} )) || debian_missing_features+=("$i")
    done
    unset i
  fi

  unfunction bind2maps

fi

# }}}1

# 20 Completion System {{{1

# https://www.zsh.org/mla/users/2015/msg00467.html
zstyle -e ':completion:*:*:(ssh|mosh):*:my-accounts' users-hosts \
	'[[ -f ${HOME}/.ssh/config && $key = hosts ]] && key=my_hosts reply=()'

# rationalise-dot() {{{2
# https://grml.org/zsh/zsh-lovers.html

rationalise-dot() {
  if [[ $LBUFFER == *.. ]]; then
    LBUFFER+=/..
  else
    LBUFFER+=.
  fi
}

zle -N rationalise-dot
bindkey . rationalise-dot
# Without the following, typing a period aborts incremental history search
bindkey -M isearch . self-insert

# }}}2

# Use dircolors $LS_COLORS for completion when possible
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Use Esc-K for run-help
bindkey -M vicmd 'K' run-help

# Allow v to edit the command line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# Fuzzy matching of completions
# https://grml.org/zsh/zsh-lovers.html
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle -e ':completion:*:approximate:*' \
  max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'

# Have the completion system announce what it is completing
zstyle ':completion:*' format '%BCompleting %d%b'

# List different kinds of completions separately
zstyle ':completion:*' group-name ''

# In menu-style completion, give a status bar
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'

# vi mode exceptions {{{2

[[ -o vi ]] || bindkey -v

# Borrowed from emacs mode
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward   # FLOW_CONTROL must be off

# }}}2

# Show completion "waiting dots" {{{2

# zle bug before Zsh 5.7.1
if is-at-least 5.7.1; then
  expand-or-complete-with-dots() {
    print -n '...'
    zle expand-or-complete
    zle .redisplay
  }
  zle -N expand-or-complete-with-dots
  bindkey '^I' expand-or-complete-with-dots
fi

# }}}2

# }}}1

# 22.7 The zsh/complist Module {{{1
# use the vi navigation keys (hjkl) besides cursor keys in menu completion
(( ${+modules[zsh/complist]} )) || zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char        # left
bindkey -M menuselect 'k' vi-up-line-or-history   # up
bindkey -M menuselect 'l' vi-forward-char         # right
bindkey -M menuselect 'j' vi-down-line-or-history # bottom

# }}}1

# 26 User Contributions {{{1

# 26.7.1 history-search-end {{{2

autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey '^P' history-beginning-search-backward-end
bindkey '^N' history-beginning-search-forward-end
if [[ $TERM != 'dumb' ]]; then
  bindkey '^[[A' history-beginning-search-backward-end
  bindkey '^[[B' history-beginning-search-forward-end
fi
bindkey -M vicmd 'k' history-beginning-search-backward-end
bindkey -M vicmd 'j' history-beginning-search-forward-end

# }}}2

# 26.7.1 Allow pasting URLs as CLI arguments
# if [[ $ZSH_VERSION != '5.1.1' && $TERM != 'dumb' ]] &&
#   (( ! $+INSIDE_EMACS )); then
#   autoload -Uz url-quote-magic
#   zle -N self-insert url-quote-magic
#   if is-at-least 5.1; then
#     autoload -Uz bracketed-paste-magic
#     zle -N bracketed-paste bracketed-paste-magic
#   fi
# elif [[ $TERM == 'dumb' ]]; then
#   unset zle_bracketed_paste # Avoid ugly control sequences in dumb terminal
# fi
[[ $TERM == 'dumb' ]] && unset zle_bracketed_paste

# }}}1

# Miscellaneous {{{1

# While tinkering with ZSH-z

if (( SHLVL == 1  && ! $+TMUX )) || [[ $OSTYPE == (msys|cygwin) ]]; then
  [[ ! -d ${HOME}/.zbackup ]] && mkdir -p "${HOME}/.zbackup"
  cp "${HOME}/.z" "${HOME}/.zbackup/z_${EPOCHSECONDS}" 2> /dev/null
fi

# }}}1

# zcomet {{{1

if (( ${+commands[git]} )); then

  if [[ ! -f ${HOME}/.zcomet/bin/zcomet.zsh ]]; then
    command git clone --branch develop https://github.com/agkozak/zcomet.git \
        ${HOME}/.zcomet/bin
  fi
  source ~/.zcomet/bin/zcomet.zsh

  # agkozak/zsh-z {{{2

  ZSHZ_DEBUG=1
  zcomet load agkozak/zsh-z@develop
  ZSHZ_CASE='smart'
  ZSHZ_ECHO=1
  # In FreeBSD, /home is /usr/home
  [[ $OSTYPE == freebsd* ]] && typeset -g ZSHZ_NO_RESOLVE_SYMLINKS=1
  # ZSHZ_TILDE=1
  ZSHZ_TRAILING_SLASH=1
  ZSHZ_UNCOMMON=1

  # }}}2

  # Other plugins {{{2

  zcomet trigger zhooks agkozak/zhooks@develop

  if [[ $TERM != 'cons25' ]]; then
    # zcomet load jreese/zsh-titles
    zcomet snippet https://github.com/jreese/zsh-titles/blob/master/titles.plugin.zsh
  fi

  zcomet load ohmyzsh plugins/gitfast
  zcomet load ohmyzsh plugins/docker
  zcomet trigger zsh-prompt-benchmark romkatv/zsh-prompt-benchmark

  zcomet trigger --no-submodules archive unarchive lsarchive \
    prezto modules/archive
  alias x='unarchive' extract='unarchive'

  # # fzf does not run on a number of platforms and its install script requires
  # # bash
  # if [[ $OSTYPE != (msys|cygwin|solaris*) ]] &&
  #    (( ${+commands[bash]} )) &&
  #    is-at-least 5; then
  #   zcomet load junegunn/fzf shell completion.zsh key-bindings.zsh
  #   (( ${+commands[fzf]} )) || ~[fzf]/install --bin
  # fi

  # }}}2

  # Other {{{2

  # For when I'm testing the Polyglot Prompt in Zsh
  # zcomet load agkozak/polyglot@develop
  # if which kubectl &> /dev/null; then
  #   zcomet load jonmosco/kube-ps1
  #   zcomet load agkozak/polyglot-kube-ps1
  # fi

  zcomet trigger clip open pbcopy pbpaste zpm-zsh/clipboard

  # if is-at-least 5 && [[ $AGKDOT_SYSTEMINFO != *ish* ]]; then
  #   zcomet load agkozak/zui
  #   zcomet load agkozak/zbrowse
  # fi

  # zcomet load marlonrichert/zsh-autocomplete

  zcomet fpath zsh-users/zsh-completions src

  [[ -o KSH_ARRAYS ]] || {
    ZSH_AUTOSUGGEST_MANUAL_REBIND=1
    ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(history-beginning-search-backward-end history-beginning-search-forward-end)
    [[ $OSTYPE == (msys|cygwin) ]] && ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
    zcomet load zsh-users/zsh-autosuggestions
  }

  # }}}2

  if [[ $OSTYPE != (msys|cygwin) ]]; then     # They're too slow
    zcomet load zsh-users/zsh-syntax-highlighting
  fi

  # agkozak-zsh-prompt {{{2

  # AGKOZAK_PROMPT_DEBUG=1
  if ! is-at-least 5.1 ||
     (( ! AGKDOT_P10K )); then
    zcomet load agkozak/agkozak-zsh-prompt@develop
  fi

  # # An optional way of loading agkozak-zsh-prompt using promptinit
  # zcomet fpath agkozak/agkozak-zsh-prompt@develop
  # autoload promptinit; promptinit
  # prompt agkozak-zsh-prompt

  # Configuration

  # AGKOZAK_COLORS_PROMPT_CHAR='magenta'
  # AGKOZAK_CUSTOM_SYMBOLS=( '⇣⇡' '⇣' '⇡' '+' 'x' '!' '>' '?' 'S' )
  # AGKOZAK_LEFT_PROMPT_ONLY=1
  # AGKOZAK_MULTILINE=0
  # AGKOZAK_PROMPT_CHAR=( '❯' '❯' '❮' )

  # # Zenburn prompt {{{3

  # Make sure the zsh/terminfo module is loaded
  (( ${+modules[zsh/terminfo]} )) || zmodload zsh/terminfo
  # If there are 256 colors, use the following colors; otherwise use the defaults
  if (( ${terminfo[colors]:-0} >= 256 )); then
    AGKOZAK_COLORS_USER_HOST=108
    AGKOZAK_COLORS_PATH=116
    AGKOZAK_COLORS_BRANCH_STATUS=228
    AGKOZAK_COLORS_EXIT_STATUS=174
    AGKOZAK_COLORS_CMD_EXEC_TIME=245
    AGKOZAK_COLORS_VIRTUALENV=188
    AGKOZAK_COLORS_BG_STRING=223
  fi
  AGKOZAK_CUSTOM_PROMPT=''
  # Command execution time
  AGKOZAK_CUSTOM_PROMPT+='%(9V.%F{${AGKOZAK_COLORS_CMD_EXEC_TIME}}%b%9v%b%f .)'
  # Exit status
  AGKOZAK_CUSTOM_PROMPT+='%(?..%B%F{${AGKOZAK_COLORS_EXIT_STATUS}}(%?%)%f%b )'
  # pipestatus
  AGKOZAK_CUSTOM_PROMPT+='%(13V.%B%F{${AGKOZAK_COLORS_EXIT_STATUS}\}(%13v%)%f%b .%(12V.%F{${AGKOZAK_COLORS_USER_HOST}\}(%12v%)%f .))'
  # Username and hostname
  AGKOZAK_CUSTOM_PROMPT+='%(!.%S%B.%B%F{${AGKOZAK_COLORS_USER_HOST}})%n%1v%(!.%b%s.%f%b) '
  # Virtual environment indicator
  AGKOZAK_CUSTOM_PROMPT+='%(10V.%F{${AGKOZAK_COLORS_VIRTUALENV}}[%10v]%f .)'
  # Path
  AGKOZAK_CUSTOM_PROMPT+='%B%F{${AGKOZAK_COLORS_PATH}}%2v%f%b'
  # Background job status
  AGKOZAK_CUSTOM_PROMPT+='%(1j. %F{${AGKOZAK_COLORS_BG_STRING}}%jj%f.)'
  # Git status
  AGKOZAK_CUSTOM_PROMPT+=$'%(3V.%F{${AGKOZAK_COLORS_BRANCH_STATUS}}%3v%f.)\n'
  # SHLVL and prompt character
  AGKOZAK_CUSTOM_PROMPT+='[%L] %(4V.:.%#) '
  AGKOZAK_COLORS_BRANCH_STATUS=228

  # No right prompt
  AGKOZAK_CUSTOM_RPROMPT=''

  # }}}3

  # }}}2

  (( AGKDOT_P10K )) && is-at-least 5.1 && zcomet load romkatv/powerlevel10k

else

  >&2 print 'Please install Git.'

fi

# }}}1

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh. {{{1
if (( AGKDOT_P10K)) && is-at-least 5.1; then
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
fi
# }}}1

# compinit {{{1

if (( ${+functions[zcomet]} )); then

  # I'm doing this here just to prove that `zcomet compinit' can handle it
  compdef mosh=ssh

  [[ $OSTYPE == (msys|cygwin) || $AGKDOT_SYSTEMINFO == *[Mm]icrosoft* ]] &&
    zstyle ':zcomet:compinit' arguments -u
  zcomet compinit

else

  if [[ $TERM != 'dumb' ]]; then
    autoload -Uz compinit
    compinit -d "${HOME}/.zcompdump_${EUID}_${OSTYPE}_${ZSH_VERSION}"
    compdef mosh=ssh
  fi
fi

# }}}1

# 14.7 Filename Generation {{{1

# 14.7.2 Static Named Directories {{{2

# Static named directories
[[ -d ${HOME}/public_html/wp-content ]] &&
  hash -d wp-content="${HOME}/public_html/wp-content"
[[ -d ${HOME}/.zcomet/repos/agkozak/agkozak-zsh-prompt ]] &&
  hash -d agk="${HOME}/.zcomet/repos/agkozak/agkozak-zsh-prompt"
[[ -d ${HOME}/.zcomet/repos/agkozak/zsh-z ]] &&
  hash -d z="${HOME}/.zcomet/repos/agkozak/zsh-z"
[[ -d ${HOME}/.zcomet/bin ]] &&
  hash -d zc="${HOME}/.zcomet/bin"

# }}}2

# }}}1

# Must come after plugin loadin {{{1

# Menu-style completion (clashes with zsh-autocomplete)
(( ${+functions[.autocomplete.async.stop]} )) ||
  zstyle ':completion:*' menu select

# }}}1

# zsh_update {{{1

############################################################
# Download the latest dotfiles, then the latest version of
# zcomet, then the latest zcomet plugins and snippets, and
# restart .zshrc
############################################################
zsh_update() {
  update_dotfiles
  if (( ${+functions[zcomet]} )); then
    zcomet self-update
    zcomet update
  fi
  exec zsh
}

# }}}1

# Source ~/.zshrc.local, if present {{{1

if [[ -f ${HOME}/.zshrc.local ]]; then
  source "${HOME}/.zshrc.local"
fi

# }}}1

# End .zshrc benchmark {{{1

if (( AGKDOT_BENCHMARKS )); then
  typeset -g AGKDOT_ZSHRC_TOTAL
  print -z -f '%.*f' 1 $(( SECONDS * 1000 ))
  read -z AGKDOT_ZSHRC_TOTAL
  _agkdot_benchmark_message \
    ".zshrc: ${AGKDOT_ZSHRC_TOTAL}ms TOTAL (inc. .profile, .shrc., etc.)"
  unset AGKDOT_ZSHRC_TOTAL
  typeset -i SECONDS
fi

unfunction _agkdot_benchmark_message

# }}}1

# xtrace {{{1
if (( AGKDOT_XTRACE )); then
  unsetopt XTRACE
  exec 2>&3 3>&-
fi
# }}}1

# vim: ai:fdm=marker:ts=2:et:sts=2:sw=2
