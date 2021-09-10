() {
local -r home_dir=${1}

if [[ -f ~zcomet/zcomet.zsh ]]; then
  cp ~zcomet/zcomet.zsh ${home_dir}
else
# download the repository
  command curl -Ss -L https://raw.githubusercontent.com/agkozak/dotfiles/zcomet/zcomet/zcomet.zsh \
    > ${home_dir}/zcomet.zsh
fi

# add modules to .zshrc
print 'source ${HOME}/zcomet.zsh
zcomet load zimfw/environment
zcomet load zimfw/git
zcomet load zimfw/input
zcomet load zimfw/termtitle
zcomet load zimfw/utility
zcomet load zimfw/duration-info
zcomet load zimfw/git-info
zcomet load zimfw/asciiship
zcomet load zsh-users/zsh-completions
zcomet load zsh-users/zsh-autosuggestions
zcomet load zsh-users/zsh-syntax-highlighting
zcomet load zsh-users/zsh-history-substring-search
# zcomet adds functions to fpath but does not autoload them!
autoload -Uz git-alias-lookup \\
         git-branch-current \\
         git-branch-delete-interactive \\
         git-dir \\
         git-ignore-add \\
         git-root \\
         git-stash-clear-interactive \\
         git-stash-recover \\
         git-submodule-move \\
         git-submodule-remove \\
         mkcd \\
         mkpw \\
         duration-info-precmd \\
         duration-info-prexec \\
         coalesce \\
         git-action \\
         git-info
[[ $TERM != dumb ]] && () {
  [[ -f ${HOME}/.zcompdump_${ZSH_VERSION} ]] &&
    zcomet compile ${HOME}/.zcompdump_${ZSH_VERSION}
  autoload -Uz compinit; compinit -C -d ${HOME}/.zcompdump_${ZSH_VERSION}
}

bindkey "^[[A" history-substring-search-up
bindkey "^[[B" history-substring-search-down
' >>! ${home_dir}/.zshrc

} "${@}"
