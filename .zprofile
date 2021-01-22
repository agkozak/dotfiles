# ~/.zprofile
#
# https://github.com/agkozak/dotfiles

export AGKDOT_SYSTEMINFO
: ${AGKDOT_SYSTEMINFO:=$(uname -a)}

[[ -f ${HOME}/.profile ]] && source ${HOME}/.profile
