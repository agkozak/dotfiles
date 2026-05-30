# ~/.zprofile
#
# https://github.com/agkozak/dotfiles

[[ -z $ENV && -f ${HOME}/.profile ]] && source "${HOME}/.profile"

if [[ -o interactive &&
      -t 0 &&
      -t 1 &&
      -z ${TMUX+X}${ZSH_SCRIPT+X}${ZSH_EXECUTION_STRING+X} &&
      -z $VIM &&
      -z $INSIDE_EMACS ]]; then
      (( ${+commands[tmux]} )) && exec tmux
fi

# vim: ai:fdm=marker:ts=2:et:sts=2:sw=2