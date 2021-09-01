# MIT License / Copyright (c) 2021 Alexandros Kozak
typeset -A ZIMP
0=${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}
ZIMP[SCRIPT]=${${(M)0:#/*}:-$PWD/$0}
ZIMP[DIR]=${${NOZI[SCRIPT]}:A:h}

zimp() {

  typeset -ga ZIMP_PLUGINS ZIMP_SNIPPETS ZIMP_TRIGGERS

  _zimp_compile() {
    while (( $# )); do
      [[ -s $1 && ( ! -s ${1}.zwc || $1 -nt ${1}.zwc ) ]] && zcompile $1
      shift
    done
  }

  _zimp_smart_source() {
    local cmd file repo_path
    cmd=$1 repo_path=$2

    case $cmd in
      load)
        for file in ${repo_path}/${repo#*/}.plugin.zsh \
                    ${repo_path}/*.plugin.zsh \
                    ${repo_path}/init.zsh; do
          [[ -f $file ]] && break
        done
        ;;
      prompt)
        for file in ${repo_path}/prompt_${repo#*/}_setup \
                    ${repo_path}/${repo#*/}.zsh-theme; do
          [[ -f $file ]] && break
        done
        ;;
    esac
    if source $file; then
      ZIMP_PLUGINS+=( ${repo} )
    else
      >&2 print "Could not source ${repo}."
      return 1
    fi
  }

  local cmd orig_dir
  [[ -n $1 ]] && cmd=$1 && shift
  orig_dir=$PWD
  case $cmd in
    load|prompt)
      [[ -z $1 ]] && return 1
      local repo branch
      if [[ -n $1 ]]; then
        repo=${1%@*}
        [[ $1 == *@* ]] && branch=${1#*@}
        shift
      fi
      if [[ ! -d ${HOME}/.zimp/repos/${repo} ]]; then
        git clone https://github.com/${repo} ${HOME}/.zimp/repos/${repo}
        if [[ -n $branch ]]; then
          cd ${HOME}/.zimp/repos/${repo} || exit
          git checkout $branch
        fi
        # TODO: Compile **/*.zsh **/prompt_*_setup **/*.zsh-theme **/*.sh
        cd $orig_dir || exit
      fi
      if (( $# )); then
        while (( $# )); do
          # Example: zimp prompt sindresorhus/pure async.zsh pure.zsh
          if [[ -f ${HOME}/.zimp/repos/${repo}/$1 ]]; then
            source ${HOME}/.zimp/repos/${repo}/$1 && ZIMP_PLUGINS+=( ${repo} )
          # Example: zimp load ohmyzsh/ohmyzsh plugins/common-aliases
          elif [[ -d ${HOME}/.zimp/repos/${repo}/$1 ]]; then
            _zimp_smart_source $cmd ${HOME}/.zimp/repos/${repo}/$1
          # Example: zimp load ohmyzsh/ohmyzsh lib/git
          elif [[ $cmd == 'load' &&
                  -f ${HOME}/.zimp/repos/${repo}/${1}.zsh ]]; then
            source ${HOME}/.zimp/repos/${repo}/${1}.zsh && ZIMP_PLUGINS+=( $repo )
          # Example: zimp load ohmyzsh/ohmyzsh themes/robbyrussell
          elif [[ $cmd == 'prompt' &&
                  -f ${HOME}/.zimp/repos/${repo}/${1}.zsh-theme ]]; then
            source ${HOME}/.zimp/repos/${repo}/${1}.zsh-theme &&
              ZIMP_PLUGINS+=( $repo )
          else
            >&2 print "Cannot source ${repo} $1."
            return 1
          fi
          shift
        done
      else
        _zimp_smart_source $cmd ${HOME}/.zimp/repos/${repo}
      fi
      ;;
    snippet)
      [[ -z $1 ]] && return 1
      local update snippet repo
      [[ $1 == '--update' ]] && update=1 && shift
      snippet=$1 repo='https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/'
      shift
      if [[ ! -f ${HOME}/.zimp/snippets/${snippet} ]] || (( update )); then
        [[ ! -d ${HOME}/.zimp/snippets/${snippet%/*} ]] &&
          mkdir -p ${HOME}/.zimp/snippets/${snippet%/*}
        print ${repo}${snippet#OMZ::}
        curl ${repo}${snippet#OMZ::} > ${HOME}/.zimp/snippets/${snippet}
        _zimp_compile ${HOME}/.zimp/snippets/${snippet}
      fi
      source ${HOME}/.zimp/snippets/${snippet} && ZIMP_SNIPPETS+=( $snippet )
      ;;
    trigger-load)
      [[ -z $1 ]] && return 1
      functions[$2]="unfunction $2; zimp load $1; eval $2 \$@"
      ZIMP_TRIGGERS+=( $2 )
      ;;
    update)
      [[ -d ${HOME}/.zimp/repos ]] && cd ${HOME}/.zimp/repos || exit
      local i
      for i in */*; do
        cd $i
        print -n "${i}: "
        git pull
        # TODO: Compile **/*.zsh **/prompt_*_setup **/*.zsh-theme **/*.sh
        (( ${ZIMP_PLUGINS[(Ie)$i]} )) && zimp load $i
        cd ../..
      done
      local -a snippets
      snippets=( ${HOME}/.zimp/snippets/**/* )
      for i in $snippets; do
        if [[ $i == *.zsh || $i == *.sh ]]; then
          zimp snippet --update ${i#${HOME}/.zimp/snippets/}
        _zimp_compile $i
        (( ${ZIMP_SNIPPETS[(Ie)$i]} )) &&
          zimp snippet ${i#${HOME}/.zimp/snippets/}
        fi
      done
      cd $orig_dir
      ;;
    list)
      print 'Plugins:'
      print -l -f '  %s\n' ${(@o)ZIMP_PLUGINS}
      print 'Snippets:'
      print -l -f '  %s\n' ${(@o)ZIMP_SNIPPETS}
      print 'Triggers:'
      print "  ${(@o)ZIMP_TRIGGERS}"
      ;;
    -h|--help|help)
      print "usage: $0 command [...]

load            load a plugin
trigger-load    create a shortcut for loading and running a plugin
prompt          load a prompt
snippet         load a snippet of code from Oh-My-ZSH
update          update all plugins and snippets
list            list all loaded plugins and snippets
-h|--help|help  print this help text" | fold -s -w $COLUMNS
      ;;
    *) zimp help; return 1 ;;
  esac
}
