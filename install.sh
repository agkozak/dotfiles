#!/bin/sh
# shellcheck disable=SC1117

# Save current directory {{{1

# From https://github.com/dylanaraps/pure-sh-bible
_agkdot_dirname() {
  # Usage: dirname "path"

  # If '$1' is empty set 'dir' to '.', else '$1'.
  dir=${1:-.}

  # Strip all trailing forward-slashes '/' from
  # the end of the string.
  #
  # "${dir##*[!/]}": Remove all non-forward-slashes
  # from the start of the string, leaving us with only
  # the trailing slashes.
  # "${dir%%"${}"}": Remove the result of the above
  # substitution (a string of forward slashes) from the
  # end of the original string.
  dir=${dir%%"${dir##*[!/]}"}

  # If the variable *does not* contain any forward slashes
  # set its value to '.'.
  [ "${dir##*/*}" ] && dir=.

  # Remove everything *after* the last forward-slash '/'.
  dir=${dir%/*}

  # Again, strip all trailing forward-slashes '/' from
  # the end of the string (see above).
  dir=${dir%%"${dir##*[!/]}"}

  # Print the resulting string and if it is empty,
  # print '/'.
  printf '%s\n' "${dir:-/}"
}

AGKDOT_ORIG_DIR="$PWD"
cd "$(_agkdot_dirname "$0")" || exit
unset -f _agkdot_dirname

# }}}1

# Functions {{{1

###########################################################
# Test to see if a command is available
#
# Argument:
#   $1              Program
###########################################################
has_command() {
  command -v "$1" > /dev/null 2>&1
}

###########################################################
# Install configuration files only if the program they
# configure is installed.
#
# Arguments:
#   $1               Program
#   $2, $3, $4, etc. Configuration files
###########################################################
conditional_install() {
  if has_command "$1"; then
    shift
    until [ $# = 0 ]; do
      if [ ! -e "${HOME}/$1" ]; then
        printf 'Installing %s\n' "$1"
      elif [ -n "$(find -L "./$1" -prune -newer "${HOME}/$1" 2>/dev/null)" ]; then
        printf 'Upgrading %s\n' "$1"
      else
        printf 'Replacing %s\n' "$1"
      fi
      cp -p "$1" "$HOME"
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
  if ! has_command git; then
    printf 'Install git.\n' >&2 && return 1
  fi
  case $1 in
    */*) ;;
    *) has_command "$1" && shift || return ;;
  esac
  AGKDOT_REPO=${1#*/}
  printf '\n'
  printf 'GitHub repository %s:\n' "$1"
  if [ ! -d "$AGKDOT_REPO" ]; then
    git clone https://github.com/"$1".git || return 1
    (cd "$AGKDOT_REPO" && { [ -z "$2" ] || git checkout "$2"; }) ||
      { rm -rf "$AGKDOT_REPO"; return 1; }
  else
    (cd "$AGKDOT_REPO" && git pull && { [ -z "$2" ] || git checkout "$2"; }) ||
      return 1
  fi
  printf '\n'
  unset AGKDOT_REPO
}

# }}}1

# Main routine {{{1

[ ! -d prompts ] && mkdir -p prompts

cd prompts || exit

github_clone_or_update agkozak/polyglot develop
github_clone_or_update kubectl jonmosco/kube-ps1
github_clone_or_update kubectl agkozak/polyglot-kube-ps1

cd .. || exit

if [ -d "${HOME}/dotfiles/plugins/bash-z" ]; then
  (cd "${HOME}/dotfiles/plugins/bash-z" && git pull)
fi

github_clone_or_update dircolors agkozak/dircolors-zenburn &&
  cp dircolors-zenburn/dircolors "$HOME/.dircolors"

conditional_install bash .bash_profile .bashrc .inputrc

conditional_install csh .cshrc

printf '.editorconfig\n'
cp .editorconfig "$HOME"

conditional_install mysql .editrc

if [ -d '/c/Program Files (x86)/JetBrains' ] ||
   [ -d '/cygdrive/c/Program Files (x86)/JetBrains' ]; then
  printf 'Installing .ideavimrc\n'
  cp .ideavimrc "$HOME"
fi

if has_command osh; then
  printf 'Installing ~/.config/oil/oshrc\n'
  mkdir -p "${HOME}/.config/oil"
  cp .config/oil/oshrc "$HOME/.config/oil"
fi

conditional_install screen .screenrc

conditional_install sh .profile .shrc

conditional_install tmux .tmux.conf

if has_command vim; then
  if [ -e "$HOME/.vimrc" ] && ! cmp ./.vimrc "$HOME/.vimrc" > /dev/null 2>&1; then
    conditional_install vim .vimrc .exrc
    vim +PlugInstall +qall
  else
    conditional_install vim .vimrc .exrc
  fi
else
  case $(readlink -f "$(command -v vi)" 2>/dev/null) in
    *busybox*) ;;
    *) conditional_install vi .exrc ;;
  esac
fi

if has_command nvim; then
  printf 'Linking ~/.config/nvim/init.vim to ~/.vimrc\n'
  if ! has_command vim; then
    cp .vimrc "$HOME"
  fi
  if [ ! -d "$HOME/.config/nvim" ]; then
    [ -d "${HOME}/.vim" ] && ln -s "$HOME/.vim" "$HOME/.config/nvim"
  fi
  if [ ! -f "$HOME/.config/nvim/init.vim" ]; then
    mkdir -p "$HOME/.config/nvim"
    ln -s "$HOME/.vimrc" "$HOME/.config/nvim/init.vim"
  fi
fi

if has_command yash; then
  [ ! -f "$HOME/.yash_profile" ] &&
    printf 'Linking ~/.yash_profile to ~/.profile\n' &&
    ln -s "$HOME/.profile" "$HOME/.yash_profile"
  [ ! -f "$HOME/.yashrc" ] &&
    printf 'Linking ~/.yashrc to ~/.shrc\n' &&
    ln -s "$HOME/.shrc" "$HOME/.yashrc"
fi

conditional_install zsh .zshenv .zshrc .zlogin .p10k.zsh

case ${AGKDOT_SYSTEMINFO:=$(uname -a)} in
	*BSD*|DragonFly*)
    conditional_install sh .login_conf
	;;
	*raspberrypi*)
		printf '.config/lxterminal\n'
		cp .config/lxterminal/lxterminal.conf "$HOME/.config/lxterminal"
	;;
	*Msys|*Cygwin)
    conditional_install mintty .minttyrc
	;;
esac

case ${AGKDOT_SYSTEMINFO:=$(uname -a)} in
  *Cygwin)
    printf '.Xresources\n'
    cp .Xresources.cygwin "$HOME/.Xresources"
    ;;
esac

# Clean up after some frameworks {{{1
rm -f "$HOME/.zlogin" "$HOME/.zlogin.zwc" "$HOME/.zlogout" "$HOME/zlogout.zwc"

# }}}1

# Clean up outdated files {{{1

[ -f "${HOME}/.zprofile" ] && rm "${HOME}/.zprofile"

# Return to original directory {{{1

cd "$AGKDOT_ORIG_DIR" || exit
unset AGKDOT_ORIG_DIR

# }}}1

# vim: ft=sh:fdm=marker:ts=2:sts=2:sw=2:et
