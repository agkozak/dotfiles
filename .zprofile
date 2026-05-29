# ~/.zprofile
#
# https://github.com/agkozak/dotfiles

if [[ -o interactive &&
      -t 0 &&
      -t 1 &&
      -z ${TMUX+X}${ZSH_SCRIPT+X}${ZSH_EXECUTION_STRING+X} &&
      -z $VIM &&
      -z $INSIDE_EMACS ]]; then
      (( ${+commands[tmux]} )) && exec tmux
fi
