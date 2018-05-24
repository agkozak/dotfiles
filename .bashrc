# ~/.bashrc
#
# https://github.com/agkozak/dotfiles
#
# shellcheck shell=bash

# Begin .bashrc benchmark {{{1

if (( AGKOZAK_RC_BENCHMARKS == 1 )); then
  case $OSTYPE in
    FreeBSD*|freebsd*) ;;
    *) ((start=$(date +%s%N)/1000000)) ;;
  esac
fi

# }}}1

# If not running interactively, don't do anything
case $- in
  *i*) ;;
  *) return ;;
esac

# Source ~/.shrc {{{1

# shellcheck source=/dev/null
[[ -f ${HOME}/.shrc ]] && . "${HOME}/.shrc"

# }}}1

# Shell options (shopt) {{{1

shopt -s autocd     # cd to directory names without typing cd

# After each command, redraw lines and columns if window size has changed
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

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

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

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

# shellcheck source=/dev/null
if [[ -f ${HOME}/.zplugin/plugins/agkozak---z/z.sh ]]; then
  . ${HOME}/.zplugin/plugins/agkozak---z/z.sh
else
  if [[ ! -d ${HOME}/dotfiles/plugins/z ]]; then
    git clone https://github.com/agkozak/z.git "${HOME}/dotfiles/plugins/z"
  fi
  . "${HOME}/dotfiles/plugins/z/z.sh"
fi

# End .bashrc benchmark {{{

if (( AGKOZAK_RC_BENCHMARKS == 1 )); then
  case $OSTYPE in
    FreeBSD*|freebsd*) ;;
    *)
      ((finish=$(date +%s%N)/1000000))
      ((difference=finish-start))
      echo ".bashrc loaded in ${difference}ms total."
      ;;
  esac
fi

# }}}

# source ~/.bashrc.local {{{1

if [[ -f "$HOME/.bashrc.local" ]]; then
  # shellcheck source=/dev/null
  . $HOME/.bashrc.local
fi

# }}}1

# vim: ai:fdm=marker:ts=2:sw=2:et:sts=2
