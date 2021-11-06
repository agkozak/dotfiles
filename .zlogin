# ~/.zlogin
#
# https://github.com/agkozak/dotfiles

if (( ${+functions[zcomet]} )); then
	( zcomet compile .zshenv .zshenv.local .zshrc .zshrc.local .profile \
		               .profile.local .shrc .shrc.local ) &!
fi

# vim: ts=2:sts=2:sw=2:et
