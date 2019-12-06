<p align="center">
    <img src="img/logo.svg">
</p>

# ALEXANDROS KOZAK'S DOTFILES

[![MIT License](img/mit_license.svg)](https://opensource.org/licenses/MIT)
![GitHub Stars](https://img.shields.io/github/stars/agkozak/dotfiles.svg)

I have tested these dotfiles primarily on

* Windows
    - MSYS2 with mintty
    - Cygwin with mintty
    - The Windows Subsystem for Linux (a.ka. Bash on Ubuntu on Windows)
* Linux
    - Ubuntu/Linux Mint/Raspbian (based on Debian)
    - CloudLinux (based on CentOS)
* BSD
    - FreeBSD/TrueOS/GhostBSD
    - NetBSD
    - OpenBSD
* Unix
    - Solaris 11
    - OpenIndiana

## Installation

Clone this repository to a `~/dotfiles` directory (the directory name is hard-coded at the moment) and run the installation script:

```sh
git clone https://github.com/agkozak/dotfiles.git "$HOME/dotfiles"
cd "$HOME/dotfiles"
./install.sh
```

That will copy relevant configuration files to your home directory. The files copied depend on what shells or other programs you have installed on your system, so if you install others in the future, run the installation script again or type

    update_dotfiles

in any POSIX-compliant shell. `update_dotfiles` is a function that pulls in the latest commits to my dotfiles repository and does what is necessary to update the system.
