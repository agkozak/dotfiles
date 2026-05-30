# ~/.zshenv
#
# https://github.com/agkozak/dotfiles

# Ubuntu-specific: Don't run compinit in /etc/zshrc; run it later {{{1

skip_global_compinit=1

# }}}1

# source ~/.zshenv.local {{{1

[[ -f ${HOME}/.zshenv.local ]] && source ${HOME}/.zshenv.local

# }}}1

# vim: ai:fdm=marker:ts=2:et:sts=2:sw=2
