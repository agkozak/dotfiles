# ~/.zprofile
#
# https://github.com/agkozak/dotfiles

typeset -F SECONDS=0

typeset -gx AGKDOT_SYSTEMINFO
: ${AGKDOT_SYSTEMINFO:=$(uname -a)}

[[ -f ${HOME}/.profile ]] && source ${HOME}/.profile

[[ -f ${HOME}/.zprofile.local ]] && source ${HOME}/.zprofile.local

AGKDOT_ZPROFILE_BENCHMARK=".zprofile loaded in ${$(( SECONDS * 1000 ))%.*}ms total."
