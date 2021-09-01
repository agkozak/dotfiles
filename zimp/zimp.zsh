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
          cd $orig_dir || exit
        fi
        [[ -f ${HOME}/.zimp/repos/${repo}/*.zsh ]] &&
          _zimp_compile ${HOME}/.zimp/repos/${repo}/*.zsh
        [[ -f ${HOME}/.zimp/repos/${repo}/*.sh ]] &&
          _zimp_compile ${HOME}/.zimp/repos/${repo}/*.sh
      fi
      if (( $# )); then
        while (( $# )); do
          source ${HOME}/.zimp/repos/${repo}/$1 &&
            ZIMP_PLUGINS+=( ${repo} )
          shift
        done
      else
        local file
        case $cmd in
          load)
            for file in ${HOME}/.zimp/repos/${repo}/${repo#*/}.plugin.zsh \
                        ${HOME}/.zimp/repos/${repo}/*.plugin.zsh \
                        ${HOME}/.zimp/repos/${repo}/init.zsh; do
              [[ -f $file ]] && break
            done
            ;;
          prompt)
            for file in ${HOME}/.zimp/repos/${repo}/prompt_${repo#*/}_setup \
                        ${HOME}/.zimp/repos/${repo}/${repo#*/}.zsh_theme; do
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
        [[ -f ${HOME}/.zimp/repos/${repo}/*.zsh ]] &&
          _zimp_compile ${HOME}/.zimp/repos/${repo}/*.zsh
        [[ -f ${HOME}/.zimp/repos/${repo}/*.sh ]] &&
          _zimp_compile ${HOME}/.zimp/repos/${repo}/*.sh
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
      print -l -f '  %s\n' $ZIMP_PLUGINS
      print 'Snippets:'
      print -l -f '  %s\n' $ZIMP_SNIPPETS
      print 'Triggers:'
      print "  $ZIMP_TRIGGERS"
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
