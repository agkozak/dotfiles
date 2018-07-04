# ~/.zprofile
#
# A necessary file, as zsh does not load .profile
#
# https://github.com/agkozak/dotfiles

# Add snap binary and desktop directories to environment
emulate sh -c 'source /etc/profile.d/apps-bin-path.sh'

if [[ -f $HOME/.profile ]]; then
  if [[ ! -f $HOME/.profile.zwc ]] || [[ $HOME/.profile -nt $HOME/profile.zwc ]]; then
    zcompile "$HOME/.profile" &> /dev/null
  fi
  if [[ -z $ENV ]]; then
    source "$HOME/.profile"
  fi
fi

# vim: ts=2:et:ai:sts=2:sw=2
