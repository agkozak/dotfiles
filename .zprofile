# ~/.zprofile
#
# https://github.com/agkozak/dotfiles

typeset -gx AGKDOT_SYSTEMINFO
: ${AGKDOT_SYSTEMINFO:=$(uname -a)}

# Compile dotfiles that won't be handled by zcomet {{{1

for i in .profile \
	 .profile.local \
	 .zshenv.local \
	 .zprofile.local \
	 .shrc \
         .shrc.local \
         .zshrc.local; do
  if [[ -e ${HOME}/${i}       &&
        ! -e ${HOME}/${i}.zwc ||
        ${HOME}/${i} -nt ${HOME}/${i}.zwc ]]; then
    (( AGKDOT_BENCHMARKS )) && >&2 print -P "%F{red}Compiling ${i}%f"
    zcompile -R "${HOME}/${i}"
  fi
done
unset i

# }}}1

[[ -f ${HOME}/.profile ]] && source ${HOME}/.profile

[[ -f ${HOME}/.zprofile.local ]] && source ${HOME}/.zprofile.local
