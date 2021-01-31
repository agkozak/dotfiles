# ~/.zprofile
#
# https://github.com/agkozak/dotfiles

export AGKDOT_SYSTEMINFO
: ${AGKDOT_SYSTEMINFO:=$(uname -a)}

[[ -f ${HOME}/.profile ]] && source ${HOME}/.profile

[[ -f ${HOME}/.zprofile.local ]] && source ${HOME}/.zprofile.local
