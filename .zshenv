# ~/.zshenv
#
# https://github.com/agkozak/dotfiles

# Benchmarks {{{1

typeset -F SECONDS=0

# }}}1

# if ~/.profile has not been loaded and /etc/zsh/zshenv has {{{1

if [[ -z $ENV && -n $PATH ]]; then
  case $- in
    *l*) ;;
    *) [[ -f ${HOME}/.profile ]] && source ${HOME}/.profile ;;
  esac
fi

# }}}1

# Add snap binary and desktop directories to environment {{{1

if (( ${+commands[snap]} )) &&
   [[ $PATH != */snap/bin* || $XDG_DATA_DIRS != */snapd/* ]]; then
  [[ -f /etc/profile.d/apps-bin-path.sh ]] &&
    source /etc/profile.d/apps-bin-path.sh
fi

# }}}1

# Ubuntu-specific: Don't run compinit in /etc/zshrc; run it later {{{1

skip_global_compinit=1

# }}}1

# source ~/.zshenv.local {{{1

[[ -f ${HOME}/.zshenv.local ]] && source ${HOME}/.zshenv.local

# }}}1

# Benchmarks {{{1

typeset -g AGKDOT_ZSHENV_BENCHMARK=${$(( SECONDS * 1000))%.*}

# }}}1

# vim: ai:fdm=marker:ts=2:et:sts=2:sw=2
