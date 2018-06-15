# ~/.zshenv
#
# https://github.com/agkozak/dotfiles

# if ~/.profile has not been loaded and /etc/zsh/zshev has
if [[ -z $ENV ]] && [[ -n $PATH ]]; then
  case $- in
    *l*) ;;
    *) [[ -f "$HOME/.profile" ]] && source "$HOME/.profile" ;;
  esac
fi
