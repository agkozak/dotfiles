() {
local -r home_dir=${1}

# download the repository
command curl -Ss -L https://raw.githubusercontent.com/agkozak/dotfiles/zimp/zimp/zimp.zsh \
  > ${home_dir}/zimp.zsh

# add modules to .zshrc
print 'source ${HOME}/zimp.zsh
zimp load zimfw/environment
zimp load zimfw/git
zimp load zimfw/input
zimp load zimfw/termtitle
zimp load zimfw/utility
zimp load zimfw/duration-info
zimp fpath zimfw/duration-info
zimp fpath zimfw/git-info functions
zimp prompt zimfw/asciiship
zimp load zsh-users/zsh-completions
zimp load zsh-users/zsh-autosuggestions
zimp load zsh-users/zsh-syntax-highlighting
zimp load zsh-users/zsh-history-substring-search
# zimp adds functions to fpath but does not autoload them!
() {
  setopt LOCAL_OPTIONS EXTENDED_GLOB
  local zfunction
  for zfunction in ${HOME}/.zimp/repos/zimfw/*/functions/^(*~|*.zwc(|.old)|_*|prompt_*_setup)(N-.:t); do
    autoload -Uz ${zfunction}
  done
}
bindkey "^[[A" history-substring-search-up
bindkey "^[[B" history-substring-search-down
' >>! ${home_dir}/.zshrc

} "${@}"
