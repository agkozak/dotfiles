# ~/.profile: executed by the command interpreter for login shells.
#
# https://github.com/agkozak/dotfiles
#
# shellcheck shell=sh
# shellcheck disable=SC2034

# For SUSE {{{1

if [ -d '/etc/YaST2' ]; then
  # shellcheck disable=SC1091,SC2015
  [ -z "$PROFILEREAD" ] && . '/etc/profile' || true
fi

# }}}1

# AGKDOT_SYSTEMINFO {{{1

if [ -z "$AGKDOT_SYSTEMINFO" ]; then
  export AGKDOT_SYSTEMINFO
  AGKDOT_SYSTEMINFO=$(uname -a)
fi

# }}}1

# Environment variables {{{1

export EDITOR VISUAL
if command -v vim > /dev/null 2>&1; then
  EDITOR='vim'
else
  EDITOR='vi'
fi
VISUAL="$EDITOR"

export ENV
ENV="${HOME}/.shrc"

export LESS
case $(ls -l "$(command -v less)") in
  *busybox*) LESS='-FIMR' ;;
  *)
    case $AGKDOT_SYSTEMINFO in
      UWIN*) LESS='-i' ;;
      *) LESS='-FiRX' ;;
    esac
    ;;
esac

if command -v lesspipe > /dev/null 2>&1; then
  export LESSOPEN
	LESSOPEN='| lesspipe %s'
elif command -v lesspipe.sh > /dev/null 2>&1; then
  export LESSOPEN
	LESSOPEN='| lesspipe.sh %s'
fi

if [ -f "$HOME/.lynx.cfg" ]; then
  export LYNX_CFG
  LYNX_CFG="${HOME}/.lynx.cfg"
fi

export MANPAGER
MANPAGER='less'

# Always use Unicode line-drawing characters, not VT100-style ones
export NCURSES_NO_UTF8_ACS
NCURSES_NO_UTF8_ACS=1

export PAGER
PAGER='less'

# More modern utilities on Solaris
# case $systeminfo in
#   SunOS*) PATH="$(getconf PATH):$PATH" ;;
# esac

export PATH

_agkdot_construct_path() {
  while [ $# -gt 0 ]; do
    if [ -d "$1" ]; then
      case $PATH in
        $1:*|*:$1:*|*:$1) ;;
        *) PATH="$1:${PATH}" ;;
      esac
    fi
    shift
  done
}

_agkdot_construct_path  '/mingw64/bin' \
                        "${HOME}/.gem/ruby/2.4.0/bin" \
                        "${HOME}/.local/bin" \
                        "${HOME}/go/bin" \
                        "${HOME}/.cabal/bin" \
                        "${HOME}/.config/composer/vendor/bin" \
                        "${HOME}/.composer/vendor/bin" \
                        "${HOME}/.luarocks/bin" \
                        "${HOME}/ruby/gems/bin" \
                        "${HOME}/.rvim/bin" \
                        "${HOME}/bin"

# Load RVM into a shell session *as a function*
# shellcheck source=/dev/null
[ -s "${HOME}/.rvm/scripts/rvm" ] && . "${HOME}/.rvm/scripts/rvm"

case $AGKDOT_SYSTEMINFO in
	*Cygwin)
		export CYGWIN
    # Have `ln' create native symlinks in Windows - only works for administrator
    CYGWIN='winsymlinks:native'
		unset PYTHONHOME SSL_CERT_DIR SSL_CERT_FILE
	  ;;
	Darwin*|FreeBSD*)
		export CLICOLOR LSCOLORS SSL_CERT_DIR SSL_CERT_FILE
		CLICOLOR=1
		LSCOLORS='ExfxcxdxBxegedAbagacad'
		SSL_CERT_DIR=/etc/ssl/certs
		SSL_CERT_FILE=/etc/ssl/cert.pem
	  ;;
  *Microsoft*)                                                            # WSL
    [ ! -d "${HOME}/.screen" ] && mkdir "${HOME}/.screen" &&
      chmod 700 "${HOME}/.screen"
    export SCREENDIR
    SCREENDIR="${HOME}/.screen"
    ;;
	*Msys)
		export MSYS SSL_CERT_DIR SSL_CERT_FILE
		# Have `ln' create native symlinks in Windows - only works for administrator
		MSYS='winsymlinks:nativestrict'
    unset PYTHONHOME
		[ ! -f '/usr/bin/zsh' ] && SHELL='/usr/bin/bash'
		SSL_CERT_DIR='/mingw64/ssl/certs'
		SSL_CERT_FILE='/mingw64/ssl/cert.pem'
	  ;;
  *raspberrypi*)
	  command -v chromium-browser > /dev/null 2>&1 && BROWSER='chromium-browser'
    ;;
esac

# }}}1

# umask {{{1

# TODO: Consider setting in wsl.conf
case $(umask) in
  000|0000) umask 022 ;;                                              # For WSL
esac

# }}}1

# Source ~/.profile.local {{{1

if [ -f "$HOME/.profile.local" ]; then
	# shellcheck source=/dev/null
	. "$HOME/.profile.local"
fi

# }}}1

# vim: fdm=marker:ts=2:sts=2:sw=2:ai:et
