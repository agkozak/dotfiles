# ~/.bash_profile
#
# https://github.com/agkozak/dotfiles
#
# shellcheck shell=bash disable=SC1090,SC1091

# CloudLinux/RHEL: /etc/profile may not source /etc/bashrc
[[ $- == *i* && -f /etc/bashrc ]] && source /etc/bashrc

source "${HOME}/.profile"

[[ $- == *i* && -f ${HOME}/.bashrc ]] && source "${HOME}/.bashrc"

# vim: ts=2:sw=2:et:sts=2:ai
