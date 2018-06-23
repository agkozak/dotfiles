# ~/.zshrc
#
# https://github.com/agkozak/dotfiles
#
# shellcheck disable=SC1090,SC2034,SC2128,SC2148,SC2154

# Begin .zshrc benchmark {{{1

if (( AGKOZAK_RC_BENCHMARKS )); then
  case $OSTYPE in
    freebsd*) ;;                        #BSD `date` can't handle nanoseconds
    *) ((start=$(date +%s%N)/1000000)) ;;
  esac
fi

# }}}1

# compile_or_recompile() {{{1

###########################################################
# If files do not have compiled forms, compile them;
# if they have been compiled, recompile them when necessary
#
# Arguments:
#   $1, etc.  Shell scripts to be compiled
###########################################################
compile_or_recompile() {
  local file
  for file in "$@"; do
    if [[ ! -f "${file}.zwc" ]]; then
      zcompile "$file"
    else
      [[ $file -nt "${file}.zwc" ]] && zcompile "$file"
    fi
  done
}

# }}}1

# (Compile and) source ~/.shrc {{{1

# Recompile ~/.shrc when necessary
compile_or_recompile "${HOME}/.shrc"

# Source ~/.shrc
if [[ -f ${HOME}/.shrc ]]; then
  # emulate sh
  source "${HOME}/.shrc"
  # emulate zsh
fi

# }}}1

# Options {{{1
#
# Arranged according to `man zshoptions`

# Changing Directories {{{2

setopt AUTO_CD            # Change to a directory just by typing its name
setopt AUTO_PUSHD         # Make cd push each old directory onto the stack
setopt PUSHD_IGNORE_DUPS  # Don't push duplicates onto the stack

# }}}2

# History {{{2

# History environment variables
HISTFILE=${HOME}/.zsh_history
HISTSIZE=12000  # Larger than $SAVEHIST for HIST_EXPIRE_DUPS_FIRST to work
SAVEHIST=10000

setopt EXTENDED_HISTORY       # Save time stamps and durations
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicates first

# Enable history on CloudLinux for a custom build of zsh in ~/bin
# with HAVE_SYMLINKS=0 set at compile time
if [[ -f /var/.cagefs/.cagefs.token ]]; then
  if [[ $(which zsh) != "/bin/zsh" ]]; then
    setopt HIST_FCNTL_LOCK
  else
    # Otherwise, just disable persistent history
    unset HISTFILE
  fi
fi

setopt HIST_IGNORE_DUPS     # Do not enter 2 consecutive duplicates into history
setopt HIST_IGNORE_SPACE    # Ignore command lines with leading spaces
setopt HIST_VERIFY        # Reload results of history expansion before executing
setopt INC_APPEND_HISTORY   # Constantly update $HISTFILE
setopt SHARE_HISTORY        # Constantly share history between shell instances

# }}}2

# Input/Output {{{2

setopt INTERACTIVE_COMMENTS # Allow comments in interactive mode

# }}}2

# Job Control {{{2

# Disable nice for background processes in WSL
[[ -z $AGKOZAK_SYSTEMINFO ]] && AGKOZAK_SYSTEMINFO="$(uname -a)"
case $AGKOZAK_SYSTEMINFO in
  *Microsoft*) unsetopt BG_NICE ;;
esac

# }}}2

# }}}1

# zsh-specific aliases - POSIX aliases are in .shrc {{{1

alias -g CA='2>&1 | cat -A'
alias -g G='| grep'
alias -g H='| head'
alias -g L='| less'
alias -g LL='2>&1 | less'
alias -g M='| most'
alias -g NE='2> /dev/null'
alias -g NUL='> /dev/null 2>&1'
alias -g T='| tail'
alias -g V='|& vim -'

# }}}1

# Styles and completions {{{1

autoload -Uz compinit
compinit -u -d "${HOME}/.zcompdump_${ZSH_VERSION}"

# https://www.zsh.org/mla/users/2015/msg00467.html
# shellcheck disable=SC2016
zstyle -e ':completion:*:*:ssh:*:my-accounts' users-hosts \
	'[[ -f ${HOME}/.ssh/config && $key = hosts ]] && key=my_hosts reply=()'

# Allow SSH tab completion for mosh hostnames
compdef mosh=ssh

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

# Menu-style completion
zstyle ':completion:*' menu select

# use the vi navigation keys (hjkl) besides cursor keys in menu completion
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char        # left
bindkey -M menuselect 'k' vi-up-line-or-history   # up
bindkey -M menuselect 'l' vi-forward-char         # right
bindkey -M menuselect 'j' vi-down-line-or-history # bottom

# Use dircolors $LS_COLORS for completion when possible
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Allow pasting URLs as CLI arguments
autoload -Uz url-quote-magic bracketed-paste-magic
zle -N self-insert url-quote-magic
zle -N bracketed-paste bracketed-paste-magic

# Use Esc-K for run-help
bindkey -M vicmd 'K' run-help

# Allow v to edit the command line
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# }}}1

# The Debian solution to Del/Home/End/etc. keybindings {{{1

typeset -A key
# shellcheck disable=SC2190
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

function bind2maps () {
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
#
# shellcheck disable=SC2004
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
	function zle-line-init () {
		emulate -L zsh
		printf '%s' "${terminfo[smkx]}"
	}
	function zle-line-finish () {
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

# }}}1

# .zplugin {{{1

autoload -Uz is-at-least

if (( AGKOZAK_NO_ZPLUGIN != 1 )) && is-at-least 5; then

  if whence git &> /dev/null; then

    if [[ ! -d ${HOME}/.zplugin ]]; then
      echo "Installing zplugin..."
      mkdir "${HOME}/.zplugin"
      git clone https://github.com/zdharma/zplugin.git "${HOME}/.zplugin/bin"
    fi

    # Recomple *.zsh files in ~/.zplugin/bin when necessary
    for file in $HOME/.zplugin/bin/*.zsh; do
      compile_or_recompile "$file"
    done
    unset file

    # In FreeBSD, /home is /usr/home
    case $OSTYPE in
      freebsd*) typeset -g _Z_NO_RESOLVE_SYMLINKS=1;;
    esac

    # zplugin and its plugins and snippets
    source "${HOME}/.zplugin/bin/zplugin.zsh"

    autoload -Uz _zplugin

    # shellcheck disable=SC2004
    (( ${+_comps} )) && _comps[zplugin]=_zplugin

    # Load plugins and snippets {{{2

    # AGKOZAK_THEME_DEBUG=1
    zplugin ice ver"develop"
    zplugin light agkozak/agkozak-zsh-theme

    zplugin ice ver"develop"
    zplugin light agkozak/zhooks
 
    zplugin light agkozak/z

    # zsh-titles causes dittography in Emacs shell and Vim terminal
    if [[ -z $EMACS ]] && [[ ! $TERM = 'dumb' ]] && [[ -z $VIM ]]; then
      zplugin light jreese/zsh-titles
    fi

    zplugin light zdharma/zui
    zplugin light zdharma/zbrowse
    CRASIS_THEME="safari-256"
    # zplugin light zdharma/zplugin-crasis

    zplugin snippet OMZ::plugins/extract/extract.plugin.zsh
    # zplugin light zdharma/fast-syntax-highlighting # Must be loaded last

  else
    echo 'Please install git.'
  fi

  # }}}2

elif is-at-least 4.3.11; then

  source "$HOME/dotfiles/themes/agkozak-zsh-theme/agkozak-zsh-theme.plugin.zsh"

fi

# }}}1

# Miscellaneous {{{1

# Disable echo escape sequences in MSys2 or Cygwin
case $OSTYPE in
  msys|cygwin) alias echo='echo -E' ;;
esac

# 10ms for key sequences
KEYTIMEOUT=1

[[ -d "$HOME/public_html/wp-content" ]] && hash -d wp-content="$HOME/public_html/wp-content"

# vi mode and exceptions {{{2

# bindkey -v  " `set -o vi` is in .shrc

# Borrowed from emacs mode
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^R' history-incremental-search-backward

bindkey '^F' history-incremental-search-forward

# }}}2

# }}}1

# Compile or recompile ~/.zcompdump and ~/.zshrc {{{1

compile_or_recompile "${HOME}/.zcompdump_${ZSH_VERSION}"
compile_or_recompile "${HOME}/.zshrc"

# }}}1

# End .zshrc benchmark {{{1

if (( AGKOZAK_RC_BENCHMARKS )); then
  case $OSTYPE in
    freebsd*) ;;
    *)
      ((finish=$(date +%s%N)/1000000))
      ((difference=finish-start))
      echo ".zshrc loaded in ${difference}ms total."
      ;;
  esac
fi

unset start finish difference

# }}}1

# Source ~/.zshrc.local, if present {{{1

if [[ -f ${HOME}/.zshrc.local ]]; then
. "${HOME}/.zshrc.local"
fi

# }}}1

# vim: ai:fdm=marker:ts=2:et:sts=2:sw=2
