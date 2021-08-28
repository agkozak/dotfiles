#                 _
#  _ __   ___ ___(_)
# | '_ \ / _ \_  / |
# | | | | (_) / /| |
# |_| |_|\___/___|_|
#
# https://github.com/agkozak/dotfiles/nozi
#
# MIT License
#
# Copyright (c) 2021 Alexandros Kozak

# This script requires Git
! (( ${+commands[git]} )) &&
  >&2 print 'nozi: Git not installed. Exiting...' &&
  return

# This script should not run if Zinit has been loaded
(( ${+functions[zinit]} )) &&
  >&2 print 'nozi: zinit function already loaded. Exiting...' &&
  return

# nozi provides a subset of Zinit's capabilities
nozi() {

  typeset -gA NOZI
  typeset -ga NOZI_PLUGINS NOZI_SNIPPETS
  local orig_dir=$PWD i j
  local branch=${NOZI[BRANCH]} && NOZI[BRANCH]=''

  # Compile scripts to wordcode when necessary
  _nozi_zcompare() {
    while [[ $# > 0 ]]; do
      if [[ -s ${1} && ( ! -s ${1}.zwc || ${1} -nt ${1}.zwc) ]]; then
        zcompile ${1}
      fi
      shift
    done
  }

  case $1 in

    # The beginnings of a help command
    -h|--help|help)
      >&2 print -- '-h|--help|help'
      >&2 print -- 'ice'
      >&2 print -- 'load|light'
      >&2 print -- 'snippet'
      >&2 print -- 'update'
      >&2 print -- 'list'
      ;;

    # ice only provides ver'...' at present
    ice)
      shift

      ! (( $# )) && return 1

      while [[ -n $@ ]]; do
        [[ $1 == ver* ]] && NOZI[BRANCH]=${1/ver/}
        shift
      done
      ;;

    # For our purposes, load and light do the same thing
    load|light)
      shift

      ! (( $# )) && return 1

      local repo=$1 repo_dir="${1%/*}---${1#*/}"

      # If a script exists, source it and add it to the plugin list
      _nozi_plugin_source() {
        if [[ -f $1 ]]; then
          source $1 && NOZI_PLUGINS+=( $repo )
        else
          return 1
        fi
      }

      if [[ ! -d "${HOME}/.zinit/plugins/${repo_dir}" ]]; then
          git clone "https://github.com/${repo}" \
            "${HOME}/.zinit/plugins/${repo_dir}"
          cd "${HOME}/.zinit/plugins/${repo_dir}" || exit
          if [[ -n $branch ]]; then
            git checkout $branch
          fi
          _nozi_zcompare *.zsh
          cd $orig_dir || exit
        fi
        _nozi_plugin_source "${HOME}/.zinit/plugins/${repo_dir}/${repo#*/}.plugin.zsh" ||
          _nozi_plugin_source "${HOME}/.zinit/plugins/${repo_dir}/init.zsh" ||
          # TODO: Rewrite
          _nozi_plugin_source ${HOME}/.zinit/plugins/${repo_dir}/*.zsh ||
          _nozi_plugin_source ${HOME}/.zinit/plugins/${repo_dir}/*.sh
        ;;

    # Clone and load snippets
    snippet)
      shift

      ! (( $# )) && return 1

      if [[ $1 == OMZ::* ]]; then
        if [[ ! -f ${HOME}/.zinit/snippets/${1/\//--}/${1##*/} ]]; then
          >&2 print "nozi: Installing snippet $1"
          mkdir -p "${HOME}/.zinit/snippets/${1%%/*}--${1#*/}"
          curl "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/${1#OMZ::}" \
            > "${HOME}/.zinit/snippets/${1%%/*}--${1#*/}/${1##*/}"
        fi
        _nozi_zcompare "${HOME}/.zinit/snippets/${1%%/*}--${1#*/}/${1##*/}"
        source "${HOME}/.zinit/snippets/${1%%/*}--${1#*/}/${1##*/}" &&
          NOZI_SNIPPETS+=( $1 )
      else
        return 1
      fi
      ;;

    # Update individual plugins and snippets or all of them
    update)
      shift
      
      [[ -d ${HOME}/.zinit/plugins ]] && cd ${HOME}/.zinit/plugins || exit

      if [[ $1 == --all ]]; then
        >&2 print 'nozi: Updating all plugins and snippets.'
        for i in *; do
          if [[ $i != _local---zinit && -d ${i}/.git ]]; then
            cd $i || exit
            print -n "nozi: Updating plugin ${${PWD:t}%---*}/${${PWD:t}#*---}: "
            git pull
            _nozi_zcompare *.zsh
            cd .. || exit
          fi
        done
        [[ -d ${HOME}/.zinit/snippets ]] && cd ${HOME}/.zinit/snippets || exit
        i=''
        for i in */*/*; do
          [[ $i == *.zwc ]] && continue
          print "nozi: Updating snippet ${${i/--/\/}%/*}"
          nozi snippet ${${i/--/\/}%/*}
          _nozi_zcompare *.zsh
        done
      else
        while (( $# > 0 )); do
          if [[ $1 == OMZ:** ]]; then
            if [[ -f ${HOME}/.zinit/snippets/${1/\//--}/${1##*/} ]]; then
              >&2 print "nozi: Updating snippet $1"
              mkdir -p "${HOME}/.zinit/snippets/${1%%/*}--${1#*/}"
              curl "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/${1#OMZ::}" \
                > "${HOME}/.zinit/snippets/${1%%/*}--${1#*/}/${1##*/}"
            else
              continue
            fi
            _nozi_zcompare "${HOME}/.zinit/snippets/${1%%/*}--${1#*/}/${1##*/}"
            source "${HOME}/.zinit/snippets/${1%%/*}--${1#*/}/${1##*/}" &&
          else
            local repo=$1 repo_dir="${1%/*}---${1#*/}"
            >&2 print -n "nozi: Updating $repo: "
            [[ -d $repo_dir ]] && cd $repo_dir || exit
            git pull
            _nozi_zcompare *.zsh
            cd .. || exit
            nozi load $repo
          fi
          shift
        done
      fi

      cd $orig_dir || exit
      ;;

      # List loaded plugins and snippets
      list)
      >&2 print 'nozi Plugins:'
      >&2 print -lf '  %s\n' $NOZI_PLUGINS
      >&2 print 'nozi Snippets:'
      >&2 print -lf '  %s\n' $NOZI_SNIPPETS
      ;;

    # TODO: Write this eventually.
    self-update) return 1 ;;

    *) return 1 ;;
  esac
}

zinit() { nozi $@; }
zi() { nozi $@; }
