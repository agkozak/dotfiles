# ~/.profile: executed by the command interpreter for login shells.
#
# https://github.com/agkozak/dotfiles
#
# shellcheck shell=sh
# shellcheck disable=SC1090,SC1091,SC2034

# For SUSE {{{1

if [ -d /etc/YaST2 ] && [ -z "$PROFILEREAD" ] && [ -f /etc/profile ]; then
  . /etc/profile
fi

# }}}1

# AGKDOT_SYSTEMINFO {{{1

export AGKDOT_SYSTEMINFO
: "${AGKDOT_SYSTEMINFO:=$(uname -a)}"

# }}}1

# Environment variables {{{1

export BAT_THEME
BAT_THEME=zenburn

export EDITOR VISUAL
if command -v vim > /dev/null 2>&1; then
  EDITOR='vim'
else
  EDITOR='vi'
fi
VISUAL="$EDITOR"

export ENV
ENV="${HOME}/.shrc"

export GEM_HOME
GEM_HOME="${HOME}/gems"

export LESS
case $AGKDOT_SYSTEMINFO in
  UWIN*) LESS=-i ;;
  *) LESS=-FiRX ;;
esac

# Always use Unicode line-drawing characters, not VT100-style ones
export NCURSES_NO_UTF8_ACS
NCURSES_NO_UTF8_ACS=1

export PAGER
PAGER='less'

# More modern utilities on Solaris
# case $AGKDOT_SYSTEMINFO in
#   SunOS*) PATH="$(getconf PATH):$PATH" ;;
# esac

export PATH

_agkdot_construct_path() {
  while [ $# -gt 0 ]; do
    if [ -d "$1" ]; then
      case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1${PATH:+:$PATH}" ;;
      esac
    fi
    shift
  done
}

_agkdot_construct_path  '/mingw64/bin' \
                        "${HOME}/.local/bin" \
                        "${HOME}/.cabal/bin" \
                        "${HOME}/.config/composer/vendor/bin" \
                        "${HOME}/.composer/vendor/bin" \
                        "${HOME}/gems/bin" \
                        "${HOME}/.rbenv/bin" \
                        "${HOME}/.cargo/bin" \
                        "${HOME}/bin"

unset -f _agkdot_construct_path

# The user's Windows home directory rarely changes. Cache it to avoid forking
# cygpath/cmd.exe on every login.
_agkdot_cache_winhome() {
  _f="${XDG_CACHE_HOME:-${HOME}/.cache}/agkdot/winhome"
  if [ -s "$_f" ]; then
    IFS= read -r WINHOME < "$_f"
  else
    WINHOME=$("$@")
    [ -n "$WINHOME" ] && mkdir -p "${_f%/*}" 2>/dev/null &&
      printf '%s\n' "$WINHOME" > "$_f" 2>/dev/null
  fi
  unset _f
}

_agkdot_winhome_wsl() {
  wslpath "$(cmd.exe /C "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')"
}

case $AGKDOT_SYSTEMINFO in
  *Cygwin)
    export CYGWIN
    # Have `ln' create native symlinks in Windows - only works for administrator
    CYGWIN=winsymlinks:native
    unset PYTHONHOME SSL_CERT_DIR SSL_CERT_FILE

    export WINHOME
    _agkdot_cache_winhome cygpath "$USERPROFILE"
    ;;
  Darwin*|FreeBSD*)
    export SSL_CERT_DIR SSL_CERT_FILE
    SSL_CERT_DIR=/etc/ssl/certs
    SSL_CERT_FILE=/etc/ssl/cert.pem
    ;;
  # WSL
  *[Mm]icrosoft*)
    [ ! -d "${HOME}/.screen" ] && mkdir -p "${HOME}/.screen" &&
      chmod 700 "${HOME}/.screen"
    export SCREENDIR
    SCREENDIR="${HOME}/.screen"

    # WINHOME should contain the user's Windows home directory
    if command -v wslpath > /dev/null 2>&1 &&
        command -v cmd.exe > /dev/null 2>&1; then
      export WINHOME
      _agkdot_cache_winhome _agkdot_winhome_wsl
    fi
    ;;
  *Msys)
    export MSYS SSL_CERT_DIR SSL_CERT_FILE
    # Have `ln' create native symlinks in Windows - only works for administrator
    MSYS=winsymlinks:nativestrict
    unset PYTHONHOME
    [ ! -f /usr/bin/zsh ] && SHELL=/usr/bin/bash
    SSL_CERT_DIR=/usr/ssl/certs
    SSL_CERT_FILE=/usr/ssl/cert.pem

    export WINHOME
    _agkdot_cache_winhome cygpath "$USERPROFILE"
    ;;
  *raspberrypi*)
    if command -v firefox > /dev/null 2>&1; then
      export BROWSER
      BROWSER=firefox
    fi
    ;;
esac

unset -f _agkdot_cache_winhome _agkdot_winhome_wsl

# }}}1

# umask {{{1

# TODO: Consider setting in wsl.conf
case $AGKDOT_SYSTEMINFO in
  *[Mm]icrosoft*)
    case $(umask) in
      000|0000) umask 022 ;;
    esac
    ;;
  *) ;;
esac

# }}}1

# Source ~/.profile.local {{{1

if [ -f "$HOME/.profile.local" ]; then
  . "$HOME/.profile.local"
fi

# }}}1

# vim: fdm=marker:ts=2:sts=2:sw=2:ai:et
