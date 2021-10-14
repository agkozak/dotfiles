# ~/.zprofile
#
# https://github.com/agkozak/dotfiles

typeset -gx AGKDOT_SYSTEMINFO
: ${AGKDOT_SYSTEMINFO:=$(uname -a)}

[[ -f ${HOME}/.profile ]] && source ${HOME}/.profile

[[ -f ${HOME}/.zprofile.local ]] && source ${HOME}/.zprofile.local
