# nozi

[![MIT License](img/mit_license.svg)](img/mit_license.svg)
![ZSH version 4.3.11 and higher](img/zsh_4.3.11_plus.svg)

[Zinit](https://github.com/zdharma/zinit) is one of the best ZSH frameworks at present, and I use it in my [dotfiles](https://github.com/agkozak/dotfiles). It only functions reliably, however, with ZSH v5.0.8 and later. I develop [ZSH plugins](https://agkozak.github.io/) that I guarantee to work in ZSH v4.3.11. Clearly, I need to have a way to load my own and other people's plugins and snippets with older versions of the shell.

`nozi` is a partial drop-in replacement for times when you have **no Zi**nit. It understands a subset of Zinit's commands:

* `load`/`light`
* `snippet` (works only with [Oh-My-ZSH](https://github.com/ohmyzsh/ohmyzsh) code right now)
* `update`
* `list`
* `ice` (right now only the modifier `ver'...'` is understood; no [alternative syntaxes](https://zdharma.github.io/zinit/wiki/Alternate-Ice-Syntax/) yet)
* `-h`|`--help`|`help`

The following example of how `nozi` can be used is derived from [my own `.zshrc`](https://github.com/agkozak/dotfiles/blob/master/.zshrc`). You'll see that it accounts for three possibilities: when Zinit Turbo mode is possible, when Zinit without Turbo mode is desired, and when Zinit is not an option and `nozi` kicks in:

```sh
autoload -Uz is-at-least compinit

# Zinit's perfect for ZSH v5.0.8 and later
if is-at-least 5.0.8; then

    if [[ ! -d ${HOME}/.zinit/bin ]]; then
      mkdir -p "${HOME}/.zinit"
      git clone https://github.com/zdharma/zinit.git "${HOME}/.zinit/bin"
    fi

    # I like to have a ZSH version-specific .zcompdump file
    typeset -A ZINIT
    ZINIT[ZCOMPDUMP_PATH]="${HOME}/.zcompdump_${ZSH_VERSION}"

    source "${HOME}/.zinit/bin/zinit.zsh"

    # Various reasons not to use Zinit Turbo mode: ZSH < v5.3, dumb terminal, Solaris, root user
    is-at-least 5.3 &&
      [[ $TERM   != dumb     &&
         $OSTYPE != solaris* &&
         $EUID   != 0 ]] && USE_TURBO=1

# Otherwise use nozi
else
    source ${HOME}/dotfiles/nozi/nozi.zsh
fi

# My own prompt; I use the `develop' branch
zinit ice ver'develop'
zinit light agkozak/agkozak-zsh-prompt

# A plugin I wrote; also using the `develop' branch
zinit ice ver'develop'
zinit light agkozak/zsh-z

# Here's another of my plugins that I like to lazy-load when possible
if (( USE_TURBO )); then
    zinit ice ver'develop' wait lucid
else
    zinit ice ver'develop'
fi
zinit light agkozak/zhooks

# Someone else's plugin; lazy-load when possible
(( USE_TURBO )) && zinit ice atload'_zsh_title__precmd' lucid nocd wait
zinit light jreese/zsh-titles

# And a snippet from Oh-My-ZSH
zinit snippet OMZ::plugins/extract/extract.plugin.zsh

# Run compinit
compinit -u -d "${ZINIT[ZCOMPDUMP_PATH]}"
```

In this example, a `USE_TURBO` variable is set when Zinit Turbo mode is appropriate and a backup `ice` modifier is used when necessary. If Zinit does not load, `nozi` knows how to interpret the basic meaning of `load`/`light`/`snippet` commmands and will keep repositories and snippets in the same directories that Zinit uses (`nozi` even understands [`ZINIT[HOME_DIR]`, `ZINIT[PLUGINS_DIR]`, and `ZINIT[SNIPPETS_DIR]`](https://github.com/zdharma/zinit#customizing-paths)). The `ice` modifier `ver'...'` will use the correct Git branch for a plugin, and once you are at a prompt you can `update` plugins and snippets and `list` what you have loaded into the environment.

Copyright (c) 2021 Alexandros Kozak
