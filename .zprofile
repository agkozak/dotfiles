# ~/.zprofile
#
# https://github.com/agkozak/dotfiles

export AGKDOT_SYSTEMINFO
: ${AGKDOT_SYSTEMINFO:=$(uname -a)}

# Zinit binary module
if [[ -f "${HOME}/.zinit/mod-bin/zmodules/Src/zdharma/zplugin.so" ]]; then
  if [[ -z ${module_path[(re)"${HOME}/.zinit/-mod-bin/zmodules/Src"]} ]]; then
    module_path=( "${HOME}/.zinit/mod-bin/zmodules/Src" ${module_path[@]} )
  fi
  zmodload zdharma/zplugin
fi

[[ -f ${HOME}/.profile ]] && source ${HOME}/.profile

[[ -f ${HOME}/.zprofile.local ]] && source ${HOME}/.zprofile.local
