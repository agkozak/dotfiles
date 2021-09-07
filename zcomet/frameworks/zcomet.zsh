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
zcomet prompt zimfw/asciiship
zcomet load zsh-users/zsh-completions
zcomet load zsh-users/zsh-autosuggestions
zcomet load zsh-users/zsh-syntax-highlighting
zcomet load zsh-users/zsh-history-substring-search
[[ $TERM != dumb ]] && () {
  zcomet compile ${HOME}/.zcompdump_${ZSH_VERSION}
  autoload -Uz compinit; compinit -C -d ${HOME}/.zcompdump_${ZSH_VERSION}
}
# zcomet adds functions to fpath but does not autoload them!
() {
  setopt LOCAL_OPTIONS EXTENDED_GLOB
  local zfunction
  for zfunction in ${HOME}/.zcomet/repos/zimfw/*/functions/^(*~|*.zwc(|.old)|_*|prompt_*_setup)(N-.:t); do
    autoload -Uz ${zfunction}
  done
}
bindkey "^[[A" history-substring-search-up
bindkey "^[[B" history-substring-search-down
' >>! ${home_dir}/.zshrc

} "${@}"
