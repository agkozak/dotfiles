setopt EQUALS

if [[ -o interactive &&
      -t 0 &&
      -t 1 &&
      -x =tmux &&
      -z $TMUX &&
      -z $VIM &&
      -z $INSIDE_EMACS ]]; then
  exec tmux
fi
