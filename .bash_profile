# ~/.bash_profile
#
# https://github.com/agkozak/dotfiles
#
# shellcheck shell=bash disable=SC1090,SC1091,SC2039

# Source global definitions in CloudLinux if shell is interactive
[[ -z $PS1 && -f /etc/bashrc ]] && source /etc/bashrc

source "$HOME/.profile"

[[ $- == *i* ]] || [[ -f ${HOME}/.bashrc ]] && source "${HOME}/.bashrc"

# vim: ts=2:sw=2:et:sts=2:ai
