# ~/.cshrc
#
# https://github.com/agkozak/dotfiles

alias h		history 100
alias j		jobs -l
alias la	ls -a
alias lf	ls -FA
alias ll	ls -lA
if ( `uname -s` != 'SunOS' ) then
	alias ls	ls -G
endif

# A righteous umask
umask 22

set path = (/sbin /bin /usr/sbin /usr/bin /usr/games /usr/local/sbin /usr/local/bin $HOME/bin)

setenv	CLICOLOR true

setenv	PAGER   less
setenv	BLOCKSIZE	K

if ($?prompt) then
	# An interactive shell -- set some stuff up
	if ( $?tcsh ) then
		switch ($TERM)
			case "xterm*":
			set prompt = '%{\033]0;%n@%m:%~\007%}[%B%n@%m%b] %B%~%b%# '
				breaksw
			default:
			set prompt = '[%B%n@%m%b] %B%~%b%# '
				breaksw
		endsw
	endif
	set autolist = ambiguous
	set complete = enhance
	set correct = cmd
	set filec
	set autocorrect
	set filec
	set history = 100
	set savehist = 100
	# Use history to aid expansion
    set autoexpand
    set autorehash
	set mail = (/var/mail/$USER)
	if ( $?tcsh ) then
		bindkey "^W" backward-delete-word
		bindkey -k up history-search-backward
		bindkey -k down history-search-forward
    bindkey -v
	endif
endif

# Enable colors and such for git diffs
setenv MORE "-erX"

# Use vim when possible
if ( -x /usr/local/bin/vim || -x /usr/bin/vim ) then
  setenv VISUAL vim
  setenv EDITOR vim
else if ( -x /usr/bin/vi || -x /bin/vi ) then
  setenv VISUAL vi
  setenv EDITOR vim
endif

if ( $?VISUAL && "$VISUAL" == vim ) alias vi vim

setenv LESSOPEN "|/usr/local/bin/lesspipe.sh %s"
setenv ENV "$HOME/.shrc"

# vim: ts=2:sts=2:sw=2:et:ai
