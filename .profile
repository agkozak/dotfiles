# ~/.profile: executed by the command interpreter for login shells.
#
# https://github.com/agkozak/dotfiles
#
# shellcheck shell=sh
# shellcheck disable=SC2034

AGKOZAK_SYSTEMINFO=$(uname -a)

export EDITOR VISUAL
if command -v vim > /dev/null 2>&1; then
  EDITOR='vim'
else
  EDITOR='vi'
fi
VISUAL="$EDITOR"

export ENV
ENV="$HOME/.shrc"

export LESS
LESS='-R'

if command -v lesspipe > /dev/null 2>&1; then
  export LESSOPEN
	LESSOPEN='|~/.lessfilter %s'
elif command -v lesspipe.sh > /dev/null 2>&1; then
  export LESSOPEN
	LESSOPEN="$(command -v lesspipe.sh) %s"
fi

export LYNX_CFG
LYNX_CFG="$HOME/.lynx.cfg"

export MANPAGER
MANPAGER='less -X'

export PAGER
PAGER=less

# More modern utilities on Solaris
# case $systeminfo in
#   SunOS*) PATH="$(getconf PATH):$PATH" ;;
# esac

export PATH

# Construct $PATH
for i in '/snap/bin' \
	"$HOME/.local/bin" \
	"$HOME/.cabal/bin" \
	"$HOME/.config/composer/vendor/bin" \
	"$HOME/.composer/vendor/bin" \
	"$HOME/ruby/gems/bin" \
	"$HOME/.rvim/bin" \
	"$HOME/bin"; do
  if [ -d "$i" ]; then
    case :$PATH: in
      *:$i:*) ;;
      *)
        PATH="$i:$PATH"
        ;;
    esac
  fi
done

unset i

case $AGKOZAK_SYSTEMINFO in
  *Msys) [ -d /mingw64/bin ] && PATH="$PATH:/mingw64/bin" ;;
esac

# Load RVM into a shell session *as a function*
# shellcheck source=/dev/null
[ -s "$HOME/.rvm/scripts/rvm" ] && . "$HOME/.rvm/scripts/rvm"

case $AGKOZAK_SYSTEMINFO in
	Darwin*|FreeBSD*)
		export CLICOLOR LSCOLORS SSL_CERT_DIR SSL_CERT_FILE
		CLICOLOR=1
		LSCOLORS='ExfxcxdxBxegedAbagacad'
		SSL_CERT_DIR=/etc/ssl/certs
		SSL_CERT_FILE=/etc/ssl/cert.pem
	  ;;
	*Msys)
		export MSYS SSL_CERT_DIR SSL_CERT_FILE
		# `ln` creates native symlinks in Windows -- only works for administrator
		MSYS="winsymlinks:nativestrict"
    unset PYTHONHOME
		[ ! -f /usr/bin/zsh ] && SHELL=/usr/bin/bash
		SSL_CERT_DIR=/mingw64/ssl/certs
		SSL_CERT_FILE=/mingw64/ssl/cert.pem
	  ;;
	*Cygwin)
		export CYGWIN
    # `ln` creates native symlinks in Windows -- only works for administrator
    CYGWIN="winsymlinks:native"
		unset PYTHONHOME SSL_CERT_DIR SSL_CERT_FILE
	  ;;
  *raspberrypi*)
	  command -v chromium-browser > /dev/null 2>&1 && BROWSER='chromium-browser'
    ;;
esac

if [ -f "$HOME/.profile.local" ]; then
	# shellcheck source=/dev/null
	. "$HOME/.profile.local"
fi

# vim: ts=2:sts=2:sw=2:ai:et
