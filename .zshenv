# ~/.zshenv
#
# https://github.com/agkozak/dotfiles

# if ~/.profile has not been loaded and /etc/zsh/zshenv has
if [[ -z $ENV ]] && [[ -n $PATH ]]; then
  case $- in
    *l*) ;;
    *)
      if [[ -f ${HOME}/.profile ]]; then
        if [[ ! -f ${HOME}/.profile/.zwc ]] || [[ ${HOME}/.profile -nt ${HOME}/profile.zwc ]]; then
          zcompile ${HOME}/.profile &> /dev/null
        fi
        source ${HOME}/.profile
      fi
      ;;
  esac
fi

# Add snap binary and desktop directories to environment
if whence -w snap &> /dev/null && [[ -f /etc/profile.d/apps-bin-path.sh ]]; then
  if [[ ! $PATH == */snap/bin* ]] || [[ ! $XDG_DATA_DIRS == */snapd/* ]]; then
    emulate sh
    source /etc/profile.d/apps-bin-path.sh
    emulate zsh
  fi
fi

# vim: ai:fdm=marker:ts=2:et:sts=2:sw=2
