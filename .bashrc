# ~/.bashrc
#
# https://github.com/agkozak/dotfiles
#
# shellcheck shell=bash disable=SC2039

# Begin .bashrc benchmark {{{1

if (( AGKDOT_BENCHMARKS )) && [[ $OSTYPE != freebsd* ]]; then
  (( AGKDOT_BASHRC_START=$(date +%s%N)/1000000 ))
fi

# }}}1

# If not running interactively, don't do anything
[[ $- == *i* ]] || return

# Source ~/.shrc {{{1

# shellcheck source=/dev/null
[[ -f ${HOME}/.shrc ]] && . "${HOME}/.shrc"

# }}}1

# Shell options (shopt) {{{1

shopt -s autocd     # cd to directory names without typing cd

# After each command, redraw lines and columns if window size has changed
shopt -s checkwinsize

# Omit .exe on completion
case $OSTYPE in
  msys|cygwin) shopt -s completion_strip_exe ;;
esac

shopt -s extglob  # Extended globbing

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

shopt -s histappend # Append to the history file (don't overwrite it)

# }}}1

# Shell variables {{{1

# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth
HISTFILESIZE=10000  # Number of lines to save to history file
HISTSIZE=12000      # Number of history items to keep in memory

# }}}1

# make less more friendly for non-text input files, see lesspipe(1)
[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"

# colored GCC warnings and errors
# export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Bash Completion {{{1

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [[ -f /usr/share/bash-completion/bash_completion ]]; then
    #shellcheck source=/dev/null
    . /usr/share/bash-completion/bash_completion
  elif [[ -f /etc/bash_completion ]]; then
    #shellcheck source=/dev/null
    . /etc/bash_completion
  fi
fi

# }}}1

# In FreeBSD, /home is /usr/home
# shellcheck disable=SC2034
[[ $OSTYPE == freebsd* ]] && _Z_NO_RESOLVE_SYMLINKS=1

# shellcheck source=/dev/null
if [[ -f ${HOME}/dotfiles/plugins/bash-z/bash-z.sh ]]; then
  . "${HOME}/dotfiles/plugins/bash-z/bash-z.sh"
else
  if [[ ! -d ${HOME}/dotfiles/plugins/z ]]; then
    if type git &> /dev/null; then
      git clone https://github.com/agkozak/z.git "$HOME/dotfiles/plugins/z"
    else
      >&2 echo 'Please install Git.'
    fi
  fi
  if [[ -f ${HOME}/dotfiles/plugins/z/z.sh ]]; then
    . "${HOME}/dotfiles/plugins/z/z.sh"
  fi
fi

# if type kubectl &> /dev/null; then
#   . "${HOME}/dotfiles/prompts/kube-ps1/kube-ps1.sh"
#   . "${HOME}/dotfiles/prompts/polyglot-kube-ps1/polyglot-kube-ps1.sh"
# fi

# End .bashrc benchmark {{{

if (( AGKDOT_BENCHMARKS )) && [[ $OSTYPE != freebsd* ]]; then
  (( AGKDOT_BASHRC_FINISH=$(date +%s%N)/1000000 ))
  >&2 echo ".bashrc loaded in $((AGKDOT_BASHRC_FINISH-AGKDOT_BASHRC_START))ms total."
fi

unset AGKDOT_BASHRC_START AGKDOT_BASHRC_FINISH

# }}}

# source ~/.bashrc.local {{{1

if [[ -f "$HOME/.bashrc.local" ]]; then
  # shellcheck source=/dev/null
  . "$HOME/.bashrc.local"
fi

# }}}1

# vim: ai:fdm=marker:ts=2:sw=2:et:sts=2
