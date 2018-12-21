# ~/.zprofile
#
# A necessary file, as zsh does not load .profile
#
# https://github.com/agkozak/dotfiles

# Add snap binary and desktop directories to environment
if whence -w snap &> /dev/null && [[ -f /etc/profile.d/apps-bin-path.sh ]]; then
  if [[ ! $PATH == */snap/bin* ]] || [[ ! $XDG_DATA_DIRS == */snapd/* ]]; then
    emulate sh
    source /etc/profile.d/apps-bin-path.sh
    emulate zsh
  fi
fi

if [[ -f "${HOME}/.profile" ]]; then
  if [[ ! -f "${HOME}/.profile.zwc" ]] || [[ "${HOME}/.profile" -nt "${HOME}/profile.zwc" ]]; then
    zcompile "${HOME}/.profile" &> /dev/null
  fi
  (( ! $+ENV )) && source "${HOME}/.profile"
fi

# vim: ts=2:et:ai:sts=2:sw=2
