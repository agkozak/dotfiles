# MIT License / Copyright (c) 2021 Alexandros Kozak
typeset -A ZIMP
0=${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}
ZIMP[SCRIPT]=${${(M)0:#/*}:-$PWD/$0}
ZIMP[DIR]=${${NOZI[SCRIPT]}:A:h}

_zimp_compile() {
  while (( $# )); do
    [[ -s $1 && ( ! -s ${1}.zwc || $1 -nt ${1}.zwc ) ]] &&
      # TODO: Debug mode
      zcompile $1 &> /dev/null
    shift
  done
}

_zimp_compile ${ZIMP[SCRIPT]}

zimp() {

  setopt NULL_GLOB

  typeset -gUa ZIMP_PROMPTS ZIMP_PLUGINS ZIMP_SNIPPETS ZIMP_TRIGGERS

  _zimp_smart_source() {
    local cmd file repo source_path
    cmd=$1 repo=$2 source_path="${HOME}/.zsh-imp/repos/${repo}${3:+\/${3}}"
    local -a files

    case $cmd in
      load)
        # TODO: Check these conditions.
        if [[ -s ${source_path}/${repo#*/}.plugin.zsh ]]; then
          file=${source_path}/${repo#*/}.plugin.zsh
        elif [[ -s ${source_path}/${3%*/}.plugin.zsh ]]; then
          file=${source_path}/${3%*/}.plugin.zsh 
        else
          files=( ${source_path}/*.plugin.zsh )
          if (( ${#files} == 1 )); then
            file=${files[1]}
          elif [[ -s ${source_path}/init.zsh ]]; then
            file=${source_path}/init.zsh
          else
            files=( ${source_path}/*.sh )
            if (( ${#files} == 1 )); then
              file=${files[1]}
            fi
          fi
        fi
        ;;
      prompt)
        # TODO: Check these conditions.
        if [[ -s ${source_path}/prompt_${repo#*/}_setup ]]; then
          file=${source_path}/prompt_${repo#*/}_setup
        elif [[ -s ${source_path}/${repo#*/}.zsh-theme ]]; then
          file=${source_path}/${repo#*/}.zsh-theme
        else
          files=( ${source_path}/*.zsh-theme )
          if (( ${#files} == 1 )); then
            file=${files[1]}
          else
            files=( ${source_path}/*.plugin.zsh )
            if (( ${#files} == 1 )); then
              file=${files[1]}
            fi
          fi
        fi
        ;;
    esac
    local success
    if source $file; then
      success=1 
    fi
    if [[ -f ${source_path}/_${repo#*/} ||
          -f ${source_path}/${repo#*/}.plugin.zsh ]] &&
       (( ! ${fpath[(Ie)${source_path}]} )); then
      fpath=( ${source_path} $fpath )
      success=1
    fi
    if [[ -d ${source_path}/functions ]] &&
       (( ! ${fpath[(Ie)${source_path}]} )); then
      fpath=( "${source_path}/functions" $fpath )
      success=1
    fi
    if (( success )); then
      _zimp_add_list $cmd "${repo} ${3}"
    else
      >&2 print "Could not load ${repo}."
      return 1
    fi
  }

  _zimp_add_list() {
    2="${2% }"
    if [[ $1 == 'load' ]]; then
      ZIMP_PLUGINS+=( "$2" )
    elif [[ $1 == 'prompt' ]]; then
      ZIMP_PROMPTS+=( "$2" )
    elif [[ $1 == 'snippet' ]]; then
      ZIMP_SNIPPETS+=( "$2" )
    elif [[ $1 == 'trigger' ]]; then
      ZIMP_TRIGGERS+=( "$2" )
    fi
  }

  _zimp_clone_repo() {
    local start_dir
    start_dir=$PWD

    if [[ ! -d ${HOME}/.zsh-imp/repos/${1} ]]; then
      print -P "%B%F{yellow}Cloning ${1}:%f%b"
      command git clone https://github.com/${1} ${HOME}/.zsh-imp/repos/${1}
      cd ${HOME}/.zsh-imp/repos/${1} || exit
      [[ -n $branch ]] && command git checkout $branch
      for file in **/*; do
        [[ -s $file &&
          $file == *.zsh ||
          $file == prompt_*_setup ||
          $file == *.zsh-theme ||
          $file == *.sh ||
          $file == _* ]] && _zimp_compile $file
      done
      cd $start_dir || exit
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
      _zimp_clone_repo $repo || return 1
      if (( $# )); then
        while (( $# )); do
          # Example: zimp prompt sindresorhus/pure async.zsh pure.zsh
          if [[ -f ${HOME}/.zsh-imp/repos/${repo}/$1 ]]; then
            source ${HOME}/.zsh-imp/repos/${repo}/$1 &&
              _zimp_add_list $cmd "${repo} ${1}"
          # Example: zimp load ohmyzsh/ohmyzsh plugins/common-aliases
          elif [[ -d ${HOME}/.zsh-imp/repos/${repo}/$1 ]]; then
            _zimp_smart_source $cmd ${repo} $1
          # Example: zimp load ohmyzsh/ohmyzsh lib/git
          elif [[ $cmd == 'load' &&
                  -f ${HOME}/.zsh-imp/repos/${repo}/${1}.zsh ]]; then
            source ${HOME}/.zsh-imp/repos/${repo}/${1}.zsh &&
              _zimp_add_list $cmd "${repo} ${1}"
          # Example: zimp load ohmyzsh/ohmyzsh themes/robbyrussell
          elif [[ -f ${HOME}/.zsh-imp/repos/${repo}/${1}.zsh-theme ]]; then
            source ${HOME}/.zsh-imp/repos/${repo}/${1}.zsh-theme &&
              _zimp_add_list $cmd "${repo} ${1}"
          else
            >&2 print "Cannot source ${repo} $1."
            return 1
          fi
          shift
        done
      else
        _zimp_smart_source $cmd ${repo}
      fi
      ;;
    fpath)
      [[ -z $1 ]] && return
      _zimp_clone_repo $1 || return 1
      fpath=( ${HOME}/.zsh-imp/repos/${1}/${2} $fpath )
      ;;
    snippet)
      [[ -z $1 ]] && return 1
      local update snippet repo
      [[ $1 == '--update' ]] && update=1 && shift
      snippet=$1 repo='https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/'
      shift
      if [[ ! -f ${HOME}/.zsh-imp/snippets/${snippet} ]] || (( update )); then
        [[ ! -d ${HOME}/.zsh-imp/snippets/${snippet%/*} ]] &&
          mkdir -p ${HOME}/.zsh-imp/snippets/${snippet%/*}
        print -P "%B%F{yellow}Downloading snippet ${snippet}:%f%b"
        curl ${repo}${snippet#OMZ::} > ${HOME}/.zsh-imp/snippets/${snippet}
        _zimp_compile ${HOME}/.zsh-imp/snippets/${snippet}
      fi
      source ${HOME}/.zsh-imp/snippets/${snippet} && _zimp_add_list $cmd $snippet
      ;;
    trigger)
      [[ -z $1 ]] && return 1
      local trigger
      trigger=$1 && shift
      ! (( ${+functions[$trigger]} )) &&
        functions[$trigger]="ZIMP_TRIGGERS=( "\${(@)ZIMP_TRIGGERS:#${trigger}}" );
          unfunction $trigger;
          zimp load $@;
          eval $trigger \$@" &&
        _zimp_add_list $cmd $trigger
      ;;
    unload)
      [[ -z $1 ]] && return 1
      if (( ${+functions[${1#*/}_plugin_unload]} )) &&
        ${1#*/}_plugin_unload; then
        ZIMP_PROMPTS=( ${(@)ZIMP_PROMPTS:#${1}} )
        ZIMP_PROMPTS=( ${(@)ZIMP_PROMPTS:#${1} *} )
        ZIMP_PLUGINS=( ${(@)ZIMP_PLUGINS:#${1}} )
        ZIMP_PLUGINS=( ${(@)ZIMP_PLUGINS:#${1} *} )
      fi
      ;;
    update)
      [[ -d ${HOME}/.zsh-imp/repos ]] && cd ${HOME}/.zsh-imp/repos || exit
      local i
      for i in */*; do
        cd $i
        print -Pn "%B%F{yellow}${i}:%f%b "
        command git pull
        for file in **/*; do
          [[ -s $file &&
            $file == *.zsh ||
            $file == prompt_*_setup ||
            $file == *.zsh-theme ||
            $file == *.sh ]] && _zimp_compile $file
        done
        if (( ${ZIMP_PLUGINS[(Ie)$i]} )); then
          zimp load $i
        elif (( ${ZIMP_PROMPT[(Ie)$i]} )); then
          zimp prompt $i
        fi
        cd ../..
      done
      local -a snippets
      snippets=( ${HOME}/.zsh-imp/snippets/**/* )
      for i in $snippets; do
        if [[ $i == *.zsh || $i == *.sh ]]; then
          print -P "%B%F{yellow}${i#${HOME}/.zsh-imp/snippets/}:%f%b"
          zimp snippet --update ${i#${HOME}/.zsh-imp/snippets/}
        _zimp_compile $i
        (( ${ZIMP_SNIPPETS[(Ie)$i]} )) &&
          zimp snippet ${i#${HOME}/.zsh-imp/snippets/}
        fi
      done
      cd $orig_dir
      ;;
    list)
      (( ${#ZIMP_PROMPTS} )) && print -P '%B%F{yellow}Prompts:%f%b' &&
        print -l -f '  %s\n' ${(@o)ZIMP_PROMPTS}
      (( ${#ZIMP_PLUGINS} )) && print -P '%B%F{yellow}Plugins:%f%b' &&
        print -l -f '  %s\n' ${(@o)ZIMP_PLUGINS}
      (( ${#ZIMP_SNIPPETS} )) && print -P '%B%F{yellow}Snippets:%f%b' &&
        print -l -f '  %s\n' ${(@o)ZIMP_SNIPPETS}
      (( ${#ZIMP_TRIGGERS} )) && print -P '%B%F{yellow}Triggers:%f%b' &&
        print "  ${(@o)ZIMP_TRIGGERS}"
      ;;
    -h|--help|help)
      print "usage: $0 command [...]

load            load a plugin
trigger         create a shortcut for loading and running a plugin
prompt          load a prompt
fpath           clone a repo and add it to FPATH
snippet         load a snippet of code from Oh-My-ZSH
unload          unload a prompt or plugin
update          update all plugins and snippets
list            list all loaded plugins and snippets
-h|--help|help  print this help text" | fold -s -w $COLUMNS
      ;;
    *) zimp help; return 1 ;;
  esac
}
