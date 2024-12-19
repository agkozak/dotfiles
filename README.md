<p align="center">
    <img src="img/logo.png">
</p>

# Alexandros Kozak's Dotfiles

[![MIT License](img/mit_license.svg)](https://opensource.org/licenses/MIT)
![GitHub Stars](https://img.shields.io/github/stars/agkozak/dotfiles.svg)

I have tested these dotfiles primarily on

* Windows
    - MSYS2 with `mintty`
    - Cygwin with `mintty`
    - The Windows Subsystem for Linux (versions 1 and 2) with Windows Terminal
* Linux
    - Ubuntu/Raspbian (based on Debian)
    - CloudLinux (based on CentOS)
    - Alpine Linux
* BSD
    - FreeBSD
    - NetBSD
    - OpenBSD
    - DragonFly BSD
* Unix
    - Solaris 11
    - OpenIndiana

## Notes

* `.profile` and `.shrc` are POSIX-compliant. They provide settings common to most shells and are sourced by the relevant `zsh` and `bash` dotfiles.
* Everything is in `vi`-mode, although in `zsh` there are additional key bindings borrowed from `emacs`-mode.
* The `tmux` and `screen` prefix key is `Ctrl-Q` (flow control has been disabled to allow this key binding). If you don't need flow control, `Ctrl-Q` is ideal: it does not interfere with any known application's key combinations.
* [Zenburn](https://github.com/jnurmine/Zenburn) colors are used whenever possible (in Vim, obviously, as well as in `tmux`, `ls`, `grep`, and `mintty` -- also see my [Zenburn Color Schemes for Windows Terminal](https://github.com/agkozak/windows-terminal-zenburn)).

## Installation

Clone this repository to a `~/dotfiles` directory (the directory name is hard-coded at the moment) and run the installation script:

```sh
git clone https://github.com/agkozak/dotfiles.git "${HOME}/dotfiles"
cd "${HOME}/dotfiles"
./install.sh
```

That will copy relevant configuration files to your home directory. The files copied depend on what shells or other programs you have installed on your system, so if you install others in the future, run the installation script again or type

    update_dotfiles

in any POSIX-compliant shell. `update_dotfiles` is a function that pulls in the latest commits to my dotfiles repository and does what is necessary to update the system.

My `.zshrc` also provides a `zsh_update` function that runs `update_dotfiles`  and then uses my own plugin manager ([`zcomet`](https://github.com/agkozak/zcomet)) to update the various plugins.
