#!/bin/sh

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
    while [ $# -ne 0 ]; do
      if [ -e "$HOME/$1" ]; then
        printf "Replacing %s\\n" "$1"
      else
        printf "Installing %s\\n" "$1"
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
#   $1 Username/Repository
#   $2 Branch (if other than master)
###########################################################
github_clone_or_update() {
  REPO=$(echo "$1" | awk -F/ '{ printf "%s", $2 }')
  if [ ! -d "$REPO" ]; then
    (git clone https://github.com/"$1".git; cd "$REPO" || return; [ -n "$2" ] && git checkout "$2")
  else
    (cd "$REPO" || return; git pull; [ "$2" != '' ] && git checkout "$2")
  fi
}

# }}}1

[ ! -d themes ] && mkdir themes

cd themes || exit

github_clone_or_update "agkozak/polyglot" develop

github_clone_or_update "agkozak/agkozak-zsh-theme" develop

cd ..

conditional_install vi .exrc

if command -v dircolors > /dev/null 2>&1; then
	echo '.dircolors'
	github_clone_or_update "agkozak/dircolors-zenburn"
fi

conditional_install bash .bash_profile .bashrc .inputrc

echo '.editorconfig'
cp .editorconfig "$HOME"

conditional_install lesspipe .lessfilter
conditional_install lesspipe.sh .lessfilter

conditional_install lynx .lynx.cfg

printf ".profile\\n.shrc\\n"
cp .profile .shrc ..

if [ -e "$HOME/.vimrc" ] \
  && ! cmp ./.vimrc "$HOME/.vimrc" > /dev/null 2>&1; then
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

conditional_install zsh .zprofile .zshrc

conditional_install csh .cshrc

conditional_install screen .screenrc

systeminfo=$( uname -a )

case $systeminfo in
	FreeBSD*|freebsd*)
		printf ".login_conf\\n"
		cp .login_conf "$HOME"
	;;
	*raspberrypi*)
		printf ".config/lxterminal\\n"
		cp .config/lxterminal/lxterminal.conf "$HOME/.config/lxterminal"
	;;
	*Msys|*Cygwin)
		printf ".minttyrc\\n"
		github_clone_or_update "agkozak/zenburn.minttyrc" develop
	;;
esac

case $systeminfo in
  *Cygwin)
    printf ".Xresources\\n"
    cp .Xresources.cygwin ../.Xresources
    ;;
esac

if command -v tmux > /dev/null 2>&1; then
	printf ".tmux.conf\\n"
  cp .tmux.conf ..
	if [ ! -d "$HOME/.tmux" ]; then
		printf "%s\\n" "Installing tpm"
		git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
	fi
fi

if command -v emacs > /dev/null 2>&1; then
  if [ ! -d "$HOME/.emacs.d" ]; then
    mkdir "$HOME/.emacs.d"
    printf "init.el\\n"
    cp ./.emacs.d/init.el "$HOME/.emacs.d"
    if command -v wget > /dev/null 2>&1; then
      (cd "$HOME/.emacs.d" \
        && wget https://raw.githubusercontent.com/purcell/exec-path-from-shell/master/exec-path-from-shell.el)
    fi
  fi
  echo '.spacemacs'
  cp .spacemacs "$HOME"
fi

# vim: ft=sh:fdm=marker:ts=2:sts=2:sw=2:et
