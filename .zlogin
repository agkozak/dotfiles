setopt EQUALS

if [[ -o interactive &&
      -t 0 &&
      -t 1 &&
      -x =tmux &&
      -z ${TMUX+X}${ZSH_SCRIPT+X}${ZSH_EXECUTION_STRING+X} &&
      -z $VIM &&
      -z $INSIDE_EMACS ]]; then
  exec tmux
fi
