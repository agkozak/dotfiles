(( ${+command[git]} )) &&
  >&2 print 'no-zinit: Git not installed. Exiting...' &&
  exit

(( ${+functions[zinit]} )) &&
  >&2 print 'no-zinit: zinit function already loaded. Exiting...' &&
  exit

zinit() {

  typeset -gA NO_ZINIT
  typeset -ga NO_ZINIT_PLUGINS NO_ZINIT_SNIPPETS
  local orig_dir=$PWD i j
  local branch=${NO_ZINIT[BRANCH]} && NO_ZINIT[BRANCH]=''

  _no_zinit_zcompare() {
    while [[ $# > 0 ]]; do
      if [[ -s ${1} && ( ! -s ${1}.zwc || ${1} -nt ${1}.zwc) ]]; then
        zcompile ${1}
      fi
      shift
    done
  }

  case $1 in
    -h|--help|help)
      >&2 print -- '-h|--help|help'
      >&2 print -- 'ice'
      >&2 print -- 'load|light'
      >&2 print -- 'snippet'
      >&2 print -- 'update'
      >&2 print -- 'list'
      ;;

    ice)
      shift

      ! (( $# )) && return 1

      while [[ -n $@ ]]; do
        [[ $1 == ver* ]] && NO_ZINIT[BRANCH]=${1/ver/}
        shift
      done
      ;;
    load|light)
      shift

      ! (( $# )) && return 1

      local repo=$1 repo_dir="${1%/*}---${1#*/}"

      _plugin_source() {
        if [[ -f $1 ]]; then
          source $1 && NO_ZINIT_PLUGINS+=( $repo )
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
          _no_zinit_zcompare *.zsh
          cd $orig_dir || exit
        fi
        _plugin_source "${HOME}/.zinit/plugins/${repo_dir}/${repo#*/}.plugin.zsh" ||
          _plugin_source "${HOME}/.zinit/plugins/${repo_dir}/init.zsh" ||
          # TODO: Rewrite
          _plugin_source ${HOME}/.zinit/plugins/${repo_dir}/*.zsh ||
            _plugin_source ${HOME}/.zinit/plugins/${repo_dir}/*.sh
        ;;
    snippet)
      shift

      ! (( $# )) && return 1

      if [[ $1 == OMZ::* ]]; then
        if [[ ! -f ${HOME}/.zinit/snippets/${1/\//--}/${1##*/} ]]; then
          >&2 print "no-zinit: Installing snippet $1"
          mkdir -p "${HOME}/.zinit/snippets/${1%%/*}--${1#*/}"
          curl "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/${1#OMZ::}" \
            > "${HOME}/.zinit/snippets/${1%%/*}--${1#*/}/${1##*/}"
        fi
        _no_zinit_zcompare "${HOME}/.zinit/snippets/${1%%/*}--${1#*/}/${1##*/}" 
        source "${HOME}/.zinit/snippets/${1%%/*}--${1#*/}/${1##*/}" &&
          NO_ZINIT_SNIPPETS+=( $1 )
      else
        return 1
      fi
      ;;
    update)
      shift
      # TODO: Allow user to update individual plugins and snippets 
      >&2 print 'no-zinit: Updating all plugins and snippets.'
      [[ -d ${HOME}/.zinit/plugins ]] && cd ${HOME}/.zinit/plugins || exit
      for i in *; do
        if [[ $i != _local---zinit && -d ${i}/.git ]]; then
          cd $i || exit
          print -n "no-zinit: Updating plugin ${${PWD:t}%---*}/${${PWD:t}#*---}: "
          git pull
          _no_zinit_zcompare *.zsh
          cd .. || exit
        fi
      done
      [[ -d ${HOME}/.zinit/snippets ]] && cd ${HOME}/.zinit/snippets || exit
      i=''
      for i in */*/*; do
        [[ $i == *.zwc ]] && continue
        print "no-zinit: Updating snippet ${${i/--/\/}%/*}"
        zinit snippet ${${i/--/\/}%/*}
      done
      cd $orig_dir || exit
      ;;
    list)
      >&2 print 'no-zinit Plugins:'
      print -lf '  %s\n' $NO_ZINIT_PLUGINS
      >&2 print 'no-zinit Snippets:'
      print -lf '  %s\n' $NO_ZINIT_SNIPPETS
      ;;
    *) return 1 ;;
  esac
}
