# ~/.zshenv
#
# https://github.com/agkozak/dotfiles

# if ~/.profile has not been loaded and /etc/zsh/zshev has
if [[ -z $ENV ]] && [[ -n $PATH ]]; then
  case $- in
    *l*) ;;
    *) source "$HOME/.profile" &> /dev/null ;;
  esac
fi
