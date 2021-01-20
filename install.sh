#!/bin/sh
# shellcheck disable=SC1117

# Functions {{{1

###########################################################
# Install configuration files only if the program they
# configure is installed.
#
# Arguments:
#   $1               Program
#   $2, $3, $4, etc. Configuration files
###########################################################
conditional_install() {
  if command -v "$1" > /dev/null 2>&1; then
    shift
    until [ $# = 0 ]; do
      if [ ! -e "${HOME}/$1" ]; then
        printf 'Installing %s\n' "$1"
      elif [ -n "$(find -L "./$1" -prune -newer "${HOME}/$1" > /dev/null 2>&1)" ]; then
        printf 'Upgrading %s\n' "$1"
      else
        printf 'Replacing %s\n' "$1"
      fi
      cp "$1" "$HOME"
      shift
    done
  fi
}

###########################################################
# Clone a repo or update it with a pull.
#
# Arguments
#   [Optional] Command that must exist for installation to
#     take place
#   Username/Repository
#   [Optional] Branch (if other than master)
###########################################################
github_clone_or_update() {
  case $1 in
    */*) ;;
    *) command -v "$1" > /dev/null 2>&1 || return ;;
  esac
  command -v git > /dev/null 2>&1 || echo 'Install git.' >&2 && return 1
  AGKDOT_REPO=$(echo "$1" | awk -F/ '{ printf "%s", $2 }')
  echo
  printf 'GitHub repository %s:\n' "$1"
  if [ ! -d "$AGKDOT_REPO" ]; then
    AGKDOT_CUR_DIR="$PWD"
    git clone https://github.com/"$1".git || return 1
    cd "$AGKDOT_REPO" || return 1
    [ -n "$2" ] && git checkout "$2"
    cd "$AGKDOT_CUR_DIR" || return 1
  else
    AGKDOT_CUR_DIR="$PWD"
    cd "$AGKDOT_REPO" || return 1
    git pull || return 1
    [ -n "$2" ] && git checkout "$2"
    cd "$AGKDOT_CUR_DIR" || return 1
  fi
  echo
  unset AGKDOT_REPO
}

# }}}1

[ ! -d prompts ] && mkdir prompts

cd prompts || exit

github_clone_or_update agkozak/polyglot develop
github_clone_or_update kubectl jonmosco/kube-ps1
github_clone_or_update kubectl agkozak/polyglot-kube-ps1

cd .. || exit

if [ -d "${HOME}/dotfiles/plugins/bash-z" ]; then
  AGKDOT_CUR_DIR="$PWD"
  cd "${HOME}/dotfiles/plugins/bash-z" || exit
  git pull
  cd "$AGKDOT_CUR_DIR" || exit
  unset AGKDOT_CUR_DIR
fi

github_clone_or_update dircolors agkozak/dircolors-zenburn &&
  cp dircolors-zenburn/dircolors "$HOME/.dircolors"

conditional_install bash .bash_profile .bashrc .inputrc

conditional_install csh .cshrc

echo '.editorconfig'
cp .editorconfig "$HOME"

if command -v emacs > /dev/null 2>&1; then
  if [ ! -d "$HOME/.emacs.d" ]; then
    mkdir "$HOME/.emacs.d"
  fi
  echo Installing ~/.emacs.d/init.el
  cp ./.emacs.d/init.el "$HOME/.emacs.d"
fi

conditional_install less .lessfilter

conditional_install lynx .lynx.cfg

conditional_install mysql .editrc

if command -v phpstorm > /dev/null 2>&1        ||
  [ -d '/c/Program Files/JetBrains' ]          ||
  [ -d '/cygdrive/c/Program Files/JetBrains' ] ||
  [ -d '/mnt/c/Program Files/JetBrains' ]; then
  echo Installing .ideavimrc
  cp .ideavimrc "$HOME"
fi

conditional_install screen .screenrc

conditional_install sh .profile .shrc

conditional_install tmux .tmux.conf

if [ -e "$HOME/.vimrc" ] && ! cmp ./.vimrc "$HOME/.vimrc" > /dev/null 2>&1; then
  conditional_install vim .vimrc .exrc
  vim +PlugInstall +qall
else
  conditional_install vim .vimrc .exrc
fi

if command -v nvim > /dev/null 2>&1; then
  echo 'Linking ~/.vimrc to ~/config/nvim/init.vim'
  if ! command -v vim > /dev/null 2>&1; then
    cp .vimrc "$HOME"
  fi
  if [ ! -d "$HOME/.config/nvim" ]; then
    ln -s "$HOME/.vim" "$HOME/.config/nvim"
  fi
  if [ ! -f "$HOME/.config/nvim/init.vim" ]; then
    ln -s "$HOME/.vimrc" "$HOME/.config/nvim/init.vim"
  fi
fi

conditional_install vi .exrc

conditional_install zsh .zprofile .zshenv .zshrc

case ${AGKDOT_SYSTEMINFO:=$(uname -a)} in
	*BSD*|DragonFly*)
    conditional_install sh .login_conf
	;;
	*raspberrypi*)
		echo .config/lxterminal
		cp .config/lxterminal/lxterminal.conf "$HOME/.config/lxterminal"
	;;
	*Msys|*Cygwin)
    conditional_install mintty .minttyrc
	;;
esac

case ${AGKDOT_SYSTEMINFO:=$(uname -a)} in
  *Cygwin)
    echo .Xresources
    cp .Xresources.cygwin ../.Xresources
    ;;
esac

# Clean up after some frameworks
rm -f "$HOME/.zlogin" "$HOME/.zlogin.zwc" "$HOME/.zlogout" "$HOME/zlogout.zwc"

# vim: ft=sh:fdm=marker:ts=2:sts=2:sw=2:et
