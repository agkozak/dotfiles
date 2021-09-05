# ZSH-Imp
#
# https://github.com/agkozak/dotfiles/zsh-imp
#
# MIT License / Copyright (c) 2021 Alexandros Kozak

typeset -A ZIMP
0=${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}
ZIMP[SCRIPT]=${${(M)0:#/*}:-$PWD/$0}
# Add zimp completions to fpath
fpath=( ${ZIMP[SCRIPT]:A:h} $fpath )

# Allow the user to specify custom directories
ZIMP[HOME_DIR]=${ZIMP[HOME_DIR]:-${HOME}/.zsh-imp}
ZIMP[REPOS_DIR]=${ZIMP[REPOS_DIR]:-${ZIMP[HOME_DIR]}/repos}
ZIMP[SNIPPETS_DIR]=${ZIMP[SNIPPETS_DIR]:-${ZIMP[HOME_DIR]}/snippets}

# Conditionally compile or recompile ZSH scripts

############################################################
# Compile scripts to wordcode or recompile them when they
# have changed.
# Arguments:
#   Files to compile or recompile
############################################################
_zimp_compile() {
  while (( $# )); do
    if [[ -s $1 && ( ! -s ${1}.zwc || $1 -nt ${1}.zwc ) ]]; then
      # TODO: Debug mode
      zcompile $1 &> /dev/null
    fi
    shift
  done
}

# Keep a current compile version of zsh-imp.zsh
_zimp_compile ${ZIMP[SCRIPT]}

############################################################
# The main command
# Globals:
#   ZIMP
#   ZIMP_PLUGINS
#   ZIMP_PROMPTS
#   ZIMP_SNIPPETS
#   ZIMP_TRIGGERS
# Arguments:
#   load <repo> [...]
#   trigger <trigger> <repo] [...]
#   snippet <snippet>
#   update
#   prompt <repo> [...]
#   fpath <repo> [...]
#   unload <repo>
#   list
#   help
# Outputs:
#   Status updates
############################################################
zimp() {

  setopt NULL_GLOB

  typeset -gUa ZIMP_PROMPTS ZIMP_PLUGINS ZIMP_SNIPPETS ZIMP_TRIGGERS


  ##########################################################
  # Find plugin file to source and/or add directories to
  # FPATH and adds the repo and optional argument to a list
  # that can be displayed with `zimp list'
  # Globals:
  #   ZIMP
  # Arguments:
  #   $1 The command being executed (`load' or `prompt')
  #   $2 A Git repository
  #   $3 A continuation of the repo path, e.g.,
  #     `plugins/common-aliases'
  # Returns:
  #   0 if a file was successfully sourced or a directory
  #   was added to FPATH; otherwise 1
  ##########################################################
  _zimp_smart_source() {
    local cmd file repo source_path
    cmd=$1 repo=$2 source_path="${ZIMP[REPOS_DIR]}/${repo}${3:+/${3}}"
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

    # Try to source a script
    if source $file &> /dev/null; then
      success=1 
    fi

    # Add directories to fpath

    # E.g., zimp load zimfw/git add /path/to/zimfw/git/functions to fpath
    if [[ -d ${source_path}/functions ]] &&
       (( ! ${fpath[(Ie)${source_path}]} )); then
      fpath=( "${source_path}/functions" $fpath )
      success=1
    # E.g., zimp load ohmyzsh/ohmyzsh plugins/extract adds
    # /path/to/extract to fpath
    elif [[ -n $3                                   &&
          -f ${source_path}/_${3#*/}              ||
          -f ${source_path}/${3#*/}.plugin.zsh ]] ||
       # E.g., zimp load agkozak/zsh-z adds /path/to/zsh-z to fpath
       [[ -f ${source_path}/_${repo#*/}           ||
          -f ${source_path}/${repo#*/}.plugin.zsh ]] &&
       (( ! ${fpath[(Ie)${source_path}]} )); then
      fpath=( ${source_path} $fpath )
      success=1
    fi

    # If a script has been sourced or a directory added to fpath or both, make
    # the repo and any subpackage visible in `zimp list'
    if (( success )); then
      _zimp_add_list $cmd "${repo} ${3}"

    # Report failure if a script has not been sourced nor a directory added to
    # fpath
    else
      >&2 print "Could not load ${repo}."
      return 1
    fi
  }

  ##########################################################
  # Manage the arrays used when running `zimp list'
  # Globals:
  #   ZIMP_PLUGINS
  #   ZIMP_PROMPTS
  #   ZIMP_SNIPPETS
  #   ZIMP_TRIGGERS
  # Arguments:
  #   $1 The command being run (load/prompt/snippet/trigger)
  #   $2 Repository and optional subpackage, e.g.,
  #     themes/robbyrussell
  ##########################################################
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

  ##########################################################
  # Clone a repository, switch to a branch/tag/commit if
  # requested, and compile the scripts
  # Globals:
  #   ZIMP 
  # Arguments:
  #   $1 The repository
  #
  # TODO: At present, this function will compile every
  # script in ohmyzsh/ohmyzsh! Rein it in.
  ##########################################################
  _zimp_clone_repo() {
    local start_dir
    start_dir=$PWD

    if [[ ! -d ${ZIMP[REPOS_DIR]}/${1} ]]; then
      print -P "%B%F{yellow}Cloning ${1}:%f%b"
      command git clone https://github.com/${1} ${ZIMP[REPOS_DIR]}/${1}
      cd ${ZIMP[REPOS_DIR]}/${1} || exit
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

  ##########################################################
  # THE MAIN ROUTINE
  ##########################################################

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
          # Example: zimp load sindresorhus/pure async.zsh pure.zsh
          if [[ -f ${ZIMP[REPOS_DIR]}/${repo}/$1 ]]; then
            source ${ZIMP[REPOS_DIR]}/${repo}/$1 &&
              fpath=( ${ZIMP[REPOS_DIR]}/${repo} $fpath ) &&
              _zimp_add_list $cmd "${repo} ${1}"
          # Example: zimp load ohmyzsh/ohmyzsh plugins/common-aliases
          elif [[ -d ${ZIMP[REPOS_DIR]}/${repo}/${1} ]]; then
            _zimp_smart_source $cmd ${repo} $1
              _zimp_add_list $cmd "${repo} ${1}"
          # Example: zimp load ohmyzsh/ohmyzsh lib/git
          elif [[ $cmd == 'load' &&
                  -f ${ZIMP[REPOS_DIR]}/${repo}/${1}.zsh ]]; then
            source ${ZIMP[REPOS_DIR]}/${repo}/${1}.zsh &&
              fpath=( ${ZIMP[REPOS_DIR]}/${repo} $fpath ) &&
              _zimp_add_list $cmd "${repo} ${1}"
          # Example: zimp load ohmyzsh/ohmyzsh themes/robbyrussell
          elif [[ -f ${ZIMP[REPOS_DIR]}/${repo}/${1}.zsh-theme ]]; then
            source ${ZIMP[REPOS_DIR]}/${repo}/${1}.zsh-theme &&
              fpath=( ${ZIMP[REPOS_DIR]}/${repo} $fpath ) &&
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
      fpath=( ${ZIMP[REPOS_DIR]}/${1}/${2} $fpath )
      ;;
    snippet)
      [[ -z $1 ]] && return 1
      local update snippet repo
      [[ $1 == '--update' ]] && update=1 && shift
      snippet=$1 repo='https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/'
      shift
      if [[ ! -f ${ZIMP[SNIPPETS_DIR]}/${snippet} ]] || (( update )); then
        [[ ! -d ${ZIMP[SNIPPETS_DIR]}/${snippet%/*} ]] &&
          mkdir -p ${ZIMP[SNIPPETS_DIR]}/${snippet%/*}
        print -P "%B%F{yellow}Downloading snippet ${snippet}:%f%b"
        curl ${repo}${snippet#OMZ::} > ${ZIMP[SNIPPETS_DIR]}/${snippet}
        _zimp_compile ${ZIMP[SNIPPETS_DIR]}/${snippet}
      fi
      source ${ZIMP[SNIPPETS_DIR]}/${snippet} && _zimp_add_list $cmd $snippet
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
      [[ -d ${ZIMP[REPOS_DIR]} ]] && cd ${ZIMP[REPOS_DIR]} || exit
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
      snippets=( ${ZIMP[SNIPPETS_DIR]}/**/* )
      for i in $snippets; do
        if [[ $i == *.zsh || $i == *.sh ]]; then
          print -P "%B%F{yellow}${i#${ZIMP[SNIPPETS_DIR]}/}:%f%b"
          zimp snippet --update ${i#${ZIMP[SNIPPETS_DIR]}/}
        _zimp_compile $i
        (( ${ZIMP_SNIPPETS[(Ie)$i]} )) &&
          zimp snippet ${i#${ZIMP[SNIPPETS_DIR]}/}
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
