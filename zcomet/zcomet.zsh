# zcomet
#
# https://github.com/agkozak/dotfiles/zcomet
#
# MIT License / Copyright (c) 2021 Alexandros Kozak

typeset -A ZCOMET
0=${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}
ZCOMET[SCRIPT]=${${(M)0:#/*}:-$PWD/$0}
# Add zcomet completions to FPATH
fpath=( ${ZCOMET[SCRIPT]:A:h} $fpath )

# Allow the user to specify custom directories
ZCOMET[HOME_DIR]=${ZCOMET[HOME_DIR]:-${HOME}/.zcomet}
ZCOMET[REPOS_DIR]=${ZCOMET[REPOS_DIR]:-${ZCOMET[HOME_DIR]}/repos}
ZCOMET[SNIPPETS_DIR]=${ZCOMET[SNIPPETS_DIR]:-${ZCOMET[HOME_DIR]}/snippets}

# Conditionally compile or recompile ZSH scripts

############################################################
# Compile scripts to wordcode or recompile them when they
# have changed.
# Arguments:
#   Files to compile or recompile
############################################################
_zcomet_compile() {
  while (( $# )); do
    if [[ -s $1 && ( ! -s ${1}.zwc || $1 -nt ${1}.zwc ) ]]; then
      zcompile $1
    fi
    shift
  done
}

# Conditionally compile zcomet.zsh
_zcomet_compile ${ZCOMET[SCRIPT]}

############################################################
# The main command
# Globals:
#   ZCOMET
#   ZCOMET_PLUGINS
#   ZCOMET_PROMPTS
#   ZCOMET_SNIPPETS
#   ZCOMET_TRIGGERS
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
zcomet() {

  typeset -gUa ZCOMET_PROMPTS ZCOMET_PLUGINS ZCOMET_SNIPPETS ZCOMET_TRIGGERS


  ##########################################################
  # Find plugin file to source and/or add directories to
  # FPATH and adds the repo and optional argument to a list
  # that can be displayed with `zcomet list'
  # Globals:
  #   ZCOMET
  # Arguments:
  #   $1 The command being executed (`load' or `prompt')
  #   $2 A Git repository
  #   $3 A continuation of the repo path, e.g.,
  #     `plugins/common-aliases'
  # Returns:
  #   0 if a file was successfully sourced or a directory
  #   was added to FPATH; otherwise 1
  ##########################################################
  _zcomet_smart_source() {
    local cmd file repo source_path
    cmd=$1 repo=$2 source_path="${ZCOMET[REPOS_DIR]}/${repo}${3:+/${3}}"
    local -a files

    case $cmd in
      load)
        files=(
                ${source_path}/${repo#*/}.plugin.zsh(N.)
                ${source_path}/${3%*/}.plugin.zsh(N.)
                ${source_path}/*.plugin.zsh(N.)
                ${source_path}/init.zsh(N.)
                ${source_path}/*.sh(N.)
              )
        file=${files[1]}
        ;;
      prompt)
        files=(
                ${source_path}/prompt_${repo#*/}_setup(N.)
                ${source_path}/${repo#*/}.zsh-theme(N.)
                ${source_path}/*.zsh-theme(N.)
                ${source_path}/*.plugin.zsh(N.)
              )
        file=${files[1]}
        ;;
    esac
    local success

    # Try to source a script
    if source $file &> /dev/null; then
      success=1 
    fi

    # Add directories to FPATH

    # E.g., zcomet load zimfw/git add /path/to/zimfw/git/functions to FPATH
    if [[ -d ${source_path}/functions ]] &&
       (( ! ${fpath[(Ie)${source_path}]} )); then
      fpath=( "${source_path}/functions" $fpath )
      success=1
    # E.g., zcomet load ohmyzsh/ohmyzsh plugins/extract adds
    # /path/to/extract to FPATH
    elif [[ -n $3                                   &&
          -f ${source_path}/_${3#*/}              ||
          -f ${source_path}/${3#*/}.plugin.zsh ]] ||
       # E.g., zcomet load agkozak/zsh-z adds /path/to/zsh-z to FPATH
       [[ -f ${source_path}/_${repo#*/}           ||
          -f ${source_path}/${repo#*/}.plugin.zsh ]] &&
       (( ! ${fpath[(Ie)${source_path}]} )); then
      fpath=( ${source_path} $fpath )
      success=1
    fi

    # If a script has been sourced or a directory added to FPATH or both, make
    # the repo and any subpackage visible in `zcomet list'
    if (( success )); then
      _zcomet_add_list $cmd "${repo} ${3}"

    # Report failure if a script has not been sourced nor a directory added to
    # FPATH
    else
      >&2 print "Could not load ${repo}."
      return 1
    fi
  }

  ##########################################################
  # Manage the arrays used when running `zcomet list'
  # Globals:
  #   ZCOMET_PLUGINS
  #   ZCOMET_PROMPTS
  #   ZCOMET_SNIPPETS
  #   ZCOMET_TRIGGERS
  # Arguments:
  #   $1 The command being run (load/prompt/snippet/trigger)
  #   $2 Repository and optional subpackage, e.g.,
  #     themes/robbyrussell
  ##########################################################
  _zcomet_add_list() {
    2="${2% }"
    if [[ $1 == 'load' ]]; then
      ZCOMET_PLUGINS+=( "$2" )
    elif [[ $1 == 'prompt' ]]; then
      ZCOMET_PROMPTS+=( "$2" )
    elif [[ $1 == 'snippet' ]]; then
      ZCOMET_SNIPPETS+=( "$2" )
    elif [[ $1 == 'trigger' ]]; then
      ZCOMET_TRIGGERS+=( "$2" )
    fi
  }

  ##########################################################
  # Clone a repository, switch to a branch/tag/commit if
  # requested, and compile the scripts
  # Globals:
  #   ZCOMET
  # Arguments:
  #   $1 The repository
  #
  # TODO: At present, this function will compile every
  # script in ohmyzsh/ohmyzsh! Rein it in.
  ##########################################################
  _zcomet_clone_repo() {
    local start_dir
    start_dir=$PWD

    if [[ ! -d ${ZCOMET[REPOS_DIR]}/${1} ]]; then
      print -P "%B%F{yellow}Cloning ${1}:%f%b"
      command git clone https://github.com/${1} ${ZCOMET[REPOS_DIR]}/${1}
      cd ${ZCOMET[REPOS_DIR]}/${1} || exit
      [[ -n $branch ]] && command git checkout $branch
      local file
      for file in **/*.zsh(N.) \
                  **/prompt_*_setup(N.) \
                  **/*.zsh-theme(N.) \
                  _*(N.); do
        _zcomet_compile $file
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
      _zcomet_clone_repo $repo || return 1
      if (( $# )); then
        while (( $# )); do
          # Example: zcomet load sindresorhus/pure async.zsh pure.zsh
          if [[ -f ${ZCOMET[REPOS_DIR]}/${repo}/$1 ]]; then
            source ${ZCOMET[REPOS_DIR]}/${repo}/$1 &&
              fpath=( ${ZCOMET[REPOS_DIR]}/${repo} $fpath ) &&
              _zcomet_add_list $cmd "${repo} ${1}"
          # Example: zcomet load ohmyzsh/ohmyzsh plugins/common-aliases
          elif [[ -d ${ZCOMET[REPOS_DIR]}/${repo}/${1} ]]; then
            _zcomet_smart_source $cmd ${repo} $1
              _zcomet_add_list $cmd "${repo} ${1}"
          # Example: zcomet load ohmyzsh/ohmyzsh lib/git
          elif [[ $cmd == 'load' &&
                  -f ${ZCOMET[REPOS_DIR]}/${repo}/${1}.zsh ]]; then
            source ${ZCOMET[REPOS_DIR]}/${repo}/${1}.zsh &&
              fpath=( ${ZCOMET[REPOS_DIR]}/${repo} $fpath ) &&
              _zcomet_add_list $cmd "${repo} ${1}"
          # Example: zcomet load ohmyzsh/ohmyzsh themes/robbyrussell
          elif [[ -f ${ZCOMET[REPOS_DIR]}/${repo}/${1}.zsh-theme ]]; then
            source ${ZCOMET[REPOS_DIR]}/${repo}/${1}.zsh-theme &&
              fpath=( ${ZCOMET[REPOS_DIR]}/${repo} $fpath ) &&
              _zcomet_add_list $cmd "${repo} ${1}"
          else
            >&2 print "Cannot source ${repo} $1."
            return 1
          fi
          shift
        done
      else
        _zcomet_smart_source $cmd ${repo}
      fi
      ;;
    fpath)
      [[ -z $1 ]] && return
      _zcomet_clone_repo $1 || return 1
      fpath=( ${ZCOMET[REPOS_DIR]}/${1}/${2} $fpath )
      ;;
    snippet)
      [[ -z $1 ]] && return 1
      local update snippet repo
      [[ $1 == '--update' ]] && update=1 && shift
      snippet=$1 repo='https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/'
      shift
      if [[ ! -f ${ZCOMET[SNIPPETS_DIR]}/${snippet} ]] || (( update )); then
        [[ ! -d ${ZCOMET[SNIPPETS_DIR]}/${snippet%/*} ]] &&
          mkdir -p ${ZCOMET[SNIPPETS_DIR]}/${snippet%/*}
        print -P "%B%F{yellow}Downloading snippet ${snippet}:%f%b"
        curl ${repo}${snippet#OMZ::} > ${ZCOMET[SNIPPETS_DIR]}/${snippet}
        _zcomet_compile ${ZCOMET[SNIPPETS_DIR]}/${snippet}
      fi
      source ${ZCOMET[SNIPPETS_DIR]}/${snippet} && _zcomet_add_list $cmd $snippet
      ;;
    trigger)
      [[ -z $1 ]] && return 1
      local trigger
      trigger=$1 && shift
      ! (( ${+functions[$trigger]} )) &&
        functions[$trigger]="ZCOMET_TRIGGERS=( "\${(@)ZCOMET_TRIGGERS:#${trigger}}" );
          unfunction $trigger;
          zcomet load $@;
          eval $trigger \$@" &&
        _zcomet_add_list $cmd $trigger
      ;;
    unload)
      [[ -z $1 ]] && return 1
      if (( ${+functions[${1#*/}_plugin_unload]} )) &&
        ${1#*/}_plugin_unload; then
        ZCOMET_PROMPTS=( ${(@)ZCOMET_PROMPTS:#${1}} )
        ZCOMET_PROMPTS=( ${(@)ZCOMET_PROMPTS:#${1} *} )
        ZCOMET_PLUGINS=( ${(@)ZCOMET_PLUGINS:#${1}} )
        ZCOMET_PLUGINS=( ${(@)ZCOMET_PLUGINS:#${1} *} )
      fi
      ;;
    update)
      [[ -d ${ZCOMET[REPOS_DIR]} ]] && cd ${ZCOMET[REPOS_DIR]} || exit
      local i
      for i in */*(N); do
        cd $i
        print -Pn "%B%F{yellow}${i}:%f%b "
        command git pull
        local file
        for file in **/*.zsh(N.) \
                    **/prompt_*_setup(N.) \
                    **/*.zsh_theme(N.) \
                    **/_*(N.); do
          _zcomet_compile $file
        done
        if (( ${ZCOMET_PLUGINS[(Ie)$i]} )); then
          zcomet load $i
        elif (( ${ZCOMET_PROMPT[(Ie)$i]} )); then
          zcomet prompt $i
        fi
        cd ../..
      done
      local -a snippets
      snippets=( ${ZCOMET[SNIPPETS_DIR]}/**/*(N) )
      for i in $snippets; do
        if [[ $i == *.zsh || $i == *.sh ]]; then
          print -P "%B%F{yellow}${i#${ZCOMET[SNIPPETS_DIR]}/}:%f%b"
          zcomet snippet --update ${i#${ZCOMET[SNIPPETS_DIR]}/}
        _zcomet_compile $i
        (( ${ZCOMET_SNIPPETS[(Ie)$i]} )) &&
          zcomet snippet ${i#${ZCOMET[SNIPPETS_DIR]}/}
        fi
      done
      cd $orig_dir
      ;;
    list)
      (( ${#ZCOMET_PROMPTS} )) && print -P '%B%F{yellow}Prompts:%f%b' &&
        print -l -f '  %s\n' ${(@o)ZCOMET_PROMPTS}
      (( ${#ZCOMET_PLUGINS} )) && print -P '%B%F{yellow}Plugins:%f%b' &&
        print -l -f '  %s\n' ${(@o)ZCOMET_PLUGINS}
      (( ${#ZCOMET_SNIPPETS} )) && print -P '%B%F{yellow}Snippets:%f%b' &&
        print -l -f '  %s\n' ${(@o)ZCOMET_SNIPPETS}
      (( ${#ZCOMET_TRIGGERS} )) && print -P '%B%F{yellow}Triggers:%f%b' &&
        print "  ${(@o)ZCOMET_TRIGGERS}"
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
    *) zcomet help; return 1 ;;
  esac
}
