# ~/.zshrc
#
# https://github.com/agkozak/dotfiles
#
# This dotfile is increasingly arranged according to the order of chapters in
# the Z Shell Manual

# Begin .zshrc benchmarks {{{1

# To run zprof, execute
#
#   env ZSH_PROF='' zsh -ic zprof
(( $+ZSH_PROF )) && zmodload zsh/zprof

# For simple script running times, execute
#
#     AGKDOT_BENCHMARKS=1
#
# before sourcing.

if (( AGKDOT_BENCHMARKS )); then
  if (( $+AGKDOT_ZSHENV_BENCHMARK )); then
    print ".zshenv loaded in ${AGKDOT_ZSHENV_BENCHMARK}ms total."
    unset AGKDOT_ZSHENV_BENCHMARK
  fi
  typeset -F SECONDS=0
fi

# }}}1

# Source ~/.shrc {{{1

if [[ -f ${HOME}/.shrc ]];then
  if (( AGKDOT_BENCHMARKS )); then
    # Try to use zsh's $EPOCHREALTIME to get the benchmarks here rather than
    # using date inside of .shrc
    (( $+EPOCHREALTIME )) || zmodload zsh/datetime
    typeset -g AGKDOT_ZSHRC_START=$(( EPOCHREALTIME * 1000 ))
    AGKDOT_ZSHRC_LOADING=1 source "${HOME}/.shrc"
    printf '.shrc loaded in %dms.\n' $(( (EPOCHREALTIME * 1000) - AGKDOT_ZSHRC_START ))
    unset AGKDOT_ZSHRC_START
  else
    source "${HOME}/.shrc"
  fi
fi

: ${AGKDOT_SYSTEMINFO:=$(uname -a)}

# }}}1

# 6.8 ZSH-specific aliases - POSIX aliases are in .shrc {{{1

# Disable echo escape sequences in MSys2 or Cygwin - variables inherited from
# Windows may have backslashes in them
[[ $OSTYPE == (msys|cygwin) ]] && alias echo='echo -E'
alias hgrep='fc -fl 0 | grep'
alias ls='ls ${=LS_OPTIONS}'

# which should not be aliased in ZSH
alias which &> /dev/null && unalias which

# Global Aliases {{{2

# alias -g CA='2>&1 | cat -A'
alias -g G='| grep'
alias -g H='| head'
alias -g L='| less'
alias -g LL='2>&1 | less'
# alias -g M='| most'
alias -g NE='2> /dev/null'
alias -g NUL='&> /dev/null'
alias -g T='| tail'
alias -g V='|& vim -'

# }}}2

# }}}1

# 14.7 Filename Generation {{{1

# 14.7.1 Dynamic Named Directories {{{2

# https://superuser.com/questions/751523/dynamic-directory-hash
if [[ -d '/c/wamp64/www' ]]; then
  zsh_directory_name() {
    emulate -L zsh
    setopt extendedglob

    local -a match mbegin mend
    local pp1=/c/wamp64/www/
    local pp2=wp-content

    if [[ $1 = d ]]; then
      if [[ $2 = (#b)($pp1/)([^/]##)(/$pp2)* ]]; then
        typeset -ga reply
        reply=(wp-content:$match[2] $(( ${#match[1]} + ${#match[2]} + ${#match[3]} )) )
      else
        return 1
      fi
    elif [[ $1 = n ]]; then
      [[ $2 != (#b)wp-content:(?*) ]] && return 1
      typeset -ga reply
      reply=($pp1/$match[1]/$pp2)
    elif [[ $1 = c ]]; then
      local expl
      local -a dirs
      dirs=($pp1/*/$pp2)
      for (( i=1; i<=$#dirs; i++ )); do
        dirs[$i]=wp-content:${${dirs[$i]#$pp1/}%/$pp2}
      done
      _wanted dynamic-dirs expl 'user specific directory' compadd -S\] -a dirs
      return
    else
      return 1
    fi
    return 0
  }
fi

# }}}2

# 14.7.2 Static Named Directories {{{2

# Static named directories
[[ -d ${HOME}/public_html/wp-content ]] \
  && hash -d wp-content="$HOME/public_html/wp-content"
[[ -d ${HOME}/.zplugin/plugins/agkozak---agkozak-zsh-prompt ]] \
  && hash -d agk="$HOME/.zplugin/plugins/agkozak---agkozak-zsh-prompt"
[[ -d ${HOME}/.zplugin/plugins/agkozak---zsh-z ]] \
  && hash -d z="$HOME/.zplugin/plugins/agkozak---zsh-z"

# }}}2

# }}}1

# 15.6 Parameters Used by the Shell {{{1

# History environment variables
HISTFILE=${HOME}/.zsh_history
HISTSIZE=120000  # Larger than $SAVEHIST for HIST_EXPIRE_DUPS_FIRST to work
SAVEHIST=100000

# 10ms for key sequences
KEYTIMEOUT=1

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

unsetopt LIST_BEEP        # Don't beep on an ambiguous completion

# }}}2

# 16.2.4 History {{{2

setopt EXTENDED_HISTORY       # Save time stamps and durations
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicates first

# Enable history on CloudLinux for a custom build of zsh in ~/bin
# with HAVE_SYMLINKS=0 set at compile time
# See https://gist.github.com/agkozak/50a9bf7da14b9f060c68124418ac5217
if [[ -f '/var/.cagefs/.cagefs.token' ]]; then
  if [[ =zsh != '/bin/zsh' ]]; then
    setopt HIST_FCNTL_LOCK
  else
    # Otherwise, just disable persistent history
    unset HISTFILE
  fi
fi

setopt HIST_IGNORE_DUPS     # Do not enter 2 consecutive duplicates into history
setopt HIST_IGNORE_SPACE    # Ignore command lines with leading spaces
setopt HIST_VERIFY          # Reload results of history expansion before executing
setopt INC_APPEND_HISTORY   # Constantly update $HISTFILE
setopt SHARE_HISTORY        # Constantly share history between shell instances

# }}}2

# 16.2.6 Input/Output {{{2

unsetopt FLOW_CONTROL       # Free up Ctrl-Q and Ctrl-S 
setopt INTERACTIVE_COMMENTS # Allow comments in interactive mode

# }}}2

# 16.2.7 Job Control {{{2

# Disable nice for background processes in WSL
[[ ${AGKDOT_SYSTEMINFO} == *Microsoft* ]] && unsetopt BG_NICE

# }}}2

# 16.2.12 Zle {{{2

unsetopt BEEP

# }}}2

# }}}1

# # The Debian solution to Del/Home/End/etc. keybindings {{{1

# No need to load the following code if I'm using Debian
if [[ ! -f '/etc/debian-version' ]] && [[ ! -f '/etc/zsh/zshrc' ]]; then

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

    while [[ "$1" != "--" ]]; do
      maps+=( "$1" )
      shift
    done
    shift

    sequence="${key[$1]}"
    widget="$2"

    [[ -z "$sequence" ]] && return 1

    for i in "${maps[@]}"; do
      bindkey -M "$i" "$sequence" "$widget"
    done
    unset i
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
  if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
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

# zplugin for zsh v5.0+, along with provisions for zsh v4.3.11+ {{{1

# 26.12.1 Test for minimal ZSH version {{{2

autoload -Uz is-at-least

# }}}2

# export AGKDOT_NO_ZPLUGIN=1 to circumvent zplugin
if (( AGKDOT_NO_ZPLUGIN != 1 )) && is-at-least 5; then

  # Optional binary module
  if [[ -f "${HOME}/.zplugin/bin/zmodules/Src/zdharma/zplugin.so" ]]; then
    if [[ -z ${module_path[(re)"${HOME}/.zplugin/bin/zmodules/Src"]} ]]; then
      module_path=( "${HOME}/.zplugin/bin/zmodules/Src" ${module_path[@]} )
    fi
    zmodload zdharma/zplugin
  fi

  if whence -w git &> /dev/null; then

    if [[ ! -d ${HOME}/.zplugin/bin ]]; then
      print 'Installing zplugin...'
      mkdir -p "${HOME}/.zplugin"
      git clone https://github.com/zdharma/zplugin.git "${HOME}/.zplugin/bin"
    fi

    # Configuration hash
    typeset -A ZPLGM

    # Location of .zcompdump file
    ZPLGM[ZCOMPDUMP_PATH]="${HOME}/.zcompdump_${ZSH_VERSION}"

    # zplugin and its plugins and snippets
    source "${HOME}/.zplugin/bin/zplugin.zsh"

    # Load plugins and snippets {{{2

    # agkozak-zsh-prompt {{{3

    # AGKOZAK_COLORS_PROMPT_CHAR='magenta'
    # AGKOZAK_CUSTOM_SYMBOLS=( '⇣⇡' '⇣' '⇡' '+' 'x' '!' '>' '?' 'S' )
    # AGKOZAK_LEFT_PROMPT_ONLY=1
    # AGKOZAK_MULTILINE=0
    # AGKOZAK_PROMPT_CHAR=( '❯' '❯' '❮' )
    AGKOZAK_PROMPT_DEBUG=1

    if (( ! $+VIM_TERMINAL )) && (( ! $+INSIDE_EMACS )); then
      AGKOZAK_COLORS_USER_HOST=108
      AGKOZAK_COLORS_PATH=116
      AGKOZAK_COLORS_BRANCH_STATUS=228
      AGKOZAK_COLORS_EXIT_STATUS=174
    fi
    # Username and hostname
    AGKOZAK_CUSTOM_PROMPT='%(!.%S%B.%B%F{${AGKOZAK_COLORS_USER_HOST}})%n%1v%(!.%b%s.%f%b) '
    # Path
    AGKOZAK_CUSTOM_PROMPT+='%B%F{${AGKOZAK_COLORS_PATH}}%2v%f%b'
    # Git status
    AGKOZAK_CUSTOM_PROMPT+=$'%(3V.%F{${AGKOZAK_COLORS_BRANCH_STATUS}}%3v%f.)\n'
    # Exit status
    AGKOZAK_CUSTOM_PROMPT+='%(?..%B%F{${AGKOZAK_COLORS_EXIT_STATUS}}(%?%)%f%b )'
    # SHLVL and prompt character
    AGKOZAK_CUSTOM_PROMPT+='[%L] %(4V.:.%#) '
    AGKOZAK_COLORS_BRANCH_STATUS=228

    AGKOZAK_CUSTOM_RPROMPT=''

    # if [[ $OSTYPE != (msys|cygwin) ]] \
    #   && [[ $AGKDOT_SYSTEMINFO != *Microsoft* ]] \
    #   && (( ! $+INSIDE_EMACS )) \
    #   && is-at-least 5.3; then
      PROMPT='%m%# '
      zplugin ice atload'!_agkozak_precmd' nocd silent \
        wait ver'develop'
    # else
    #   zplugin ice ver'develop'
    # fi
    zplugin load agkozak/agkozak-zsh-prompt

    # }}}3

    # zplugin light agkozak/polyglot
    # if which kubectl &> /dev/null; then
    #   zplugin light jonmosco/kube-ps1
    #   zplugin light agkozak/polyglot-kube-ps1
    # fi

    # agkozak/zsh-z
    # In FreeBSD, /home is /usr/home
    ZSHZ_DEBUG=1
    [[ $OSTYPE == freebsd* ]] && typeset -g ZSHZ_NO_RESOLVE_SYMLINKS=1
    is-at-least 5.3 && zplugin ice lucid ver'develop' wait
    zplugin load agkozak/zsh-z

    is-at-least 5.3 && zplugin ice lucid wait ver'develop'
    zplugin load agkozak/zhooks

    if is-at-least 5.3; then
    zplugin ice atinit'zpcompinit; compdef mosh=ssh; zpcdreplay' atload"
      HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='underline'
      HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND=''
      zle -N history-substring-search-up
      zle -N history-substring-search-down
      bindkey '^[OA' history-substring-search-up
      bindkey '^[OB' history-substring-search-down
      bindkey -M vicmd 'k' history-substring-search-up
      bindkey -M vicmd 'j' history-substring-search-down
      bindkey '^P' history-substring-search-up
      bindkey '^N' history-substring-search-down" nocd silent wait
    fi
    zplugin load zsh-users/zsh-history-substring-search

    # zsh-titles causes dittography in Emacs (Eshell/term/ansi-term
    # and Vim terminal
    if (( ! $+INSIDE_EMACS )) && [[ $TERM != eterm* ]] && (( ! $+VIM_TERMINAL )); then
      is-at-least 5.3 && zplugin ice lucid wait
      zplugin load jreese/zsh-titles
    fi

    if [[ $AGKDOT_SYSTEMINFO != *ish* ]]; then
      is-at-least 5.3 && zplugin ice lucid wait
      zplugin load zdharma/zui
      is-at-least 5.3 && zplugin ice lucid wait'1'
      zplugin load zdharma/zbrowse
    fi

    zplugin snippet OMZ::plugins/extract/extract.plugin.zsh

    is-at-least 5.3 && zplugin ice silent wait
    zplugin load romkatv/zsh-prompt-benchmark

    if ! is-at-least 5.3; then
      autoload -Uz compinit
      compinit -u -d "${HOME}/.zcompdump_${ZSH_VERSION}"
      compdef mosh=ssh
      HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='underline'
      HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND=''
      zle -N history-substring-search-up
      zle -N history-substring-search-down
      bindkey '^[OA' history-substring-search-up
      bindkey '^[OB' history-substring-search-down
      bindkey -M vicmd 'k' history-substring-search-up
      bindkey -M vicmd 'j' history-substring-search-down
      bindkey '^P' history-substring-search-up
      bindkey '^N' history-substring-search-down
    fi

  else
    print 'Please install git.'
  fi

  # }}}2

elif is-at-least 4.3.11; then

  () {
    local i
    for i in agkozak/agkozak-zsh-prompt \
             agkozak/zsh-z \
             agkozak/zhooks; do

      if whence -w git &> /dev/null \
        && [[ ! -d "$HOME/.zplugin/plugins/${i%/*}---${i#*/}" ]]; then
        (
          git clone  "https://github.com/${i%/*}/${i#*/}" \
            "$HOME/.zplugin/plugins/${i%/*}---${i#*/}"
          cd "$HOME/.zplugin/plugins/${i%/*}---${i#*/}"
          git checkout develop
        )
      fi
      source "$HOME/.zplugin/plugins/${i%/*}---${i#*/}/${i#*/}.plugin.zsh"
    done
  }

  autoload -Uz compinit
  compinit -u -d "${HOME}/.zcompdump_${ZSH_VERSION}"

  # Allow SSH tab completion for mosh hostnames
  compdef mosh=ssh

fi

# }}}1

# 20 Completion System {{{1

# https://www.zsh.org/mla/users/2015/msg00467.html
zstyle -e ':completion:*:*:ssh:*:my-accounts' users-hosts \
	'[[ -f ${HOME}/.ssh/config && $key = hosts ]] && key=my_hosts reply=()'
zstyle -e ':completion:*:*:mosh:*:my-accounts' users-hosts \
	'[[ -f ${HOME}/.ssh/config && $key = hosts ]] && key=my_hosts reply=()'

# rationalise-dot() {{{2
# https://grml.org/zsh/zsh-lovers.html

rationalise-dot() {
  if [[ $LBUFFER = *.. ]]; then
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

# Menu-style completion
zstyle ':completion:*' menu select

# Use dircolors $LS_COLORS for completion when possible
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Use Esc-K for run-help
bindkey -M vicmd 'K' run-help

# Allow v to edit the command line
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# Fuzzy matching of completions
# https://grml.org/zsh/zsh-lovers.html
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle -e ':completion:*:approximate:*' \
  max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'

# Have the completion system announce what it is completing
zstyle ':completion:*' format 'Completing %d'

# In menu-style completion, give a status bar
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'

# vi mode exceptions {{{2

# bindkey -v    # `set -o vi` is in .shrc

# Borrowed from emacs mode
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward   # FLOW_CONTROL must be off

# }}}2

# Show completion "waiting dots" {{{2
expand-or-complete-with-dots() {
  print -n '...'
  zle expand-or-complete
  zle .redisplay
}
zle -N expand-or-complete-with-dots
bindkey '^I' expand-or-complete-with-dots

# }}}2

# }}}1

# 22.7 The zsh/complist Module {{{1
# use the vi navigation keys (hjkl) besides cursor keys in menu completion
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char        # left
bindkey -M menuselect 'k' vi-up-line-or-history   # up
bindkey -M menuselect 'l' vi-forward-char         # right
bindkey -M menuselect 'j' vi-down-line-or-history # bottom

# }}}1

# 26 User Contributions {{{1

# 26.7.1 Allow pasting URLs as CLI arguments
if [[ $ZSH_VERSION != '5.1.1' ]] && [[ $TERM != 'dumb' ]] \
  && (( ! $+INSIDE_EMACS )); then
  if is-at-least 5.1; then
    autoload -Uz bracketed-paste-magic
    zle -N bracketed-paste bracketed-paste-magic
  fi
  autoload -Uz url-quote-magic
  zle -N self-insert url-quote-magic
elif [[ $TERM == 'dumb' ]]; then
  unset zle_bracketed_paste # Avoid ugly control sequences in dumb terminal
fi

# 26.12.1 Function for batch moving and renaming of files
autoload -Uz zmv

# }}}1

# Miscellaneous {{{1

# While tinkering with ZSH-z

if (( SHLVL == 1 )) && (( ! $+TMUX )); then
  [[ ! -d ${HOME}/.zbackup ]] && mkdir -p "${HOME}/.zbackup"
  cp "${HOME}/.z" "${HOME}/.zbackup/.z_${EPOCHSECONDS}" 2> /dev/null
fi

zsh_update() {
  update_dotfiles
  zplugin self-update
  zplugin update --all
}

# }}}1

# End .zshrc benchmark {{{1

if (( AGKDOT_BENCHMARKS )); then
  print ".zshrc loaded in ${$(( SECONDS * 1000 ))%.*}ms total."
  typeset -i SECONDS
fi

# }}}1

# Source ~/.zshrc.local, if present {{{1

if [[ -f ${HOME}/.zshrc.local ]]; then
  source "${HOME}/.zshrc.local"
fi

# }}}1

# vim: ai:fdm=marker:ts=2:et:sts=2:sw=2
