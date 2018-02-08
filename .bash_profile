# ~/.bash_profile
#
# https://github.com/agkozak/dotfiles
#
# shellcheck shell=bash disable=SC1090,SC1091

# Source global definitions in CloudLinux if shell is interactive
if [[ -z $PS1 ]]; then
  if [[ -f /etc/bashrc ]]; then
    source /etc/bashrc
  fi
fi

source "$HOME/.profile"

case $- in
  *i*)      # Interactive shell
    [[ -f $HOME/.bashrc ]] && source "$HOME/.bashrc"
    ;;
esac

# vim: ts=2:sw=2:et:sts=2:ai
