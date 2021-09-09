# zcomet
#
# https://github.com/agkozak/dotfiles/zcomet
#
# MIT License / Copyright (c) 2021 Alexandros Kozak

typeset -A ZCOMET

# Standardized $0 Handling
# https://github.com/zdharma/Zsh-100-Commits-Club/blob/master/Zsh-Plugin-Standard.adoc#zero-handling
0=${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}
0="${${(M)0:#/*}:-$PWD/$0}"

ZCOMET[SCRIPT]=$0

# Add zcomet completions to FPATH
fpath=( ${0:A:h} $fpath )

# Allow the user to specify custom directories
ZCOMET[HOME_DIR]=${ZCOMET[HOME_DIR]:-${HOME}/.zcomet}
ZCOMET[REPOS_DIR]=${ZCOMET[REPOS_DIR]:-${ZCOMET[HOME_DIR]}/repos}
ZCOMET[SNIPPETS_DIR]=${ZCOMET[SNIPPETS_DIR]:-${ZCOMET[HOME_DIR]}/snippets}

############################################################
# Compile scripts to wordcode or recompile them when they
# have changed.
# Arguments:
#   Files to compile or recompile
############################################################
_zcomet_compile() {
  while (( $# )); do
    if [[ -s $1                                &&
          ( ! -s ${1}.zwc || $1 -nt ${1}.zwc ) &&
          # Don't compile zsh-syntax-highlighting's test data
          $1 != */test-data/* ]]; then
      zcompile $1
    fi
    shift
  done
}

###########################################################
# Allow the user to employ the shorthand `ohmyzsh' for the
# ohmyzsh/ohmyzsh repo and `prezto' for
# sorin-ionescu/prezto
###########################################################
_zcomet_repo_shorthand() {
  typeset -g REPLY
  if [[ $1 == 'ohmyzsh' ]]; then
    REPLY='ohmyzsh/ohmyzsh'
  elif [[ $1 == 'prezto' ]]; then
    REPLY='sorin-ionescu/prezto'
  else
    REPLY=$1
  fi
}

##########################################################
# This function loads plugins that have already been
# cloned. Loading consists of sourcing a main file or
# adding the root directory or a /functions/ subdirectory
# to FPATH or both.
# Globals:
#   REPLY
#   ZCOMET
# Arguments:
#   A repo
#   A subdirectory [Optional]
#   A specific file to be sourced [Optional]
# Returns:
#   0 if a file is successfully sourced or an element is
#     added to FPATH; otherwise 1
# Outputs:
#   Error messages
##########################################################
_zcomet_load() {
  typeset repo subdir file plugin_path
  typeset -a files
  repo=$1
  _zcomet_repo_shorthand $repo
  repo=$REPLY
  shift
  if [[ -n $1 && -f ${ZCOMET[REPOS_DIR]}/${repo}/$1 ]]; then
    files=( $@ )
  else
    (( ${+1} )) && subdir=$1 && shift
    (( $# )) && files=( $@ )
  fi
  plugin_path="${ZCOMET[REPOS_DIR]}/${repo}${subdir:+/${subdir}}"

  if (( ${#files} )); then
    for file in $files; do
      source ${plugin_path}/${file} &&
        _zcomet_add_list load "${repo}${subdir:+ ${subdir}}${file:+ ${file}}" ||
        return $?
    done
  else
    if [[ -n $subdir ]]; then
      files=(
              ${plugin_path}/prompt_${subdir##*/}_setup(N.)
              ${plugin_path}/${subdir##*/}.zsh-theme(N.)
              ${plugin_path}/${subdir##*/}.plugin.zsh(N.)
              ${plugin_path}/${subdir##*/}.zsh(N.)
            )
    else
      files=(
              ${plugin_path}/prompt_${repo##*/}_setup(N.)
              ${plugin_path}/${repo##*/}.zsh-theme(N.)
              ${plugin_path}/${repo##*/}.plugin.zsh(N.)
              ${plugin_path}/${repo##*/}.zsh(N.)
            )
    fi
    (( ${#files} )) ||
      files+=(
               ${plugin_path}.zsh(N.)
               ${plugin_path}/*.plugin.zsh(N.)
               ${plugin_path}/init.zsh(N.)
               ${plugin_path}/*.zsh(N.)
               ${plugin_path}/*.sh(N.)
           )
    file=${files[1]}

    if [[ -n $file ]]; then
      if source $file; then
        _zcomet_add_list load "${repo}${subdir:+ ${subdir}}"
      else
        >&2 print "Cannot source ${file}." && return 1
      fi
    fi
  fi

  if [[ -d ${plugin_path}/functions ]]; then
    (( ! ${fpath[(Ie)${plugin_path}]} )) &&
      fpath=( "${plugin_path}/functions" $fpath )
    _zcomet_add_list load "${repo}${subdir:+ ${subdir}}"
  elif [[ -d ${plugin_path} ]]; then
    (( ! ${fpath[(Ie)${plugin_path}]} )) &&
      fpath=( ${plugin_path} $fpath )
    _zcomet_add_list load "${repo}${subdir:+ ${subdir}}"
  else
    >&2 print "Cannot add ${plugin_path} or ${plugin_path}/functions to FPATH." &&
      return 1
  fi
}

##########################################################
# Manage the arrays used when running `zcomet list'
# Globals:
#   ZCOMET_PLUGINS
#   ZCOMET_SNIPPETS
#   ZCOMET_TRIGGERS
# Arguments:
#   $1 The command being run (load/snippet/trigger)
#   $2 Repository and optional subpackage, e.g.,
#     themes/robbyrussell
##########################################################
_zcomet_add_list() {
  2="${2% }"
  if [[ $1 == 'load' ]]; then
    ZCOMET_PLUGINS+=( "$2" )
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
#   $2 The branch/tag/commit
#
# TODO: At present, this function will compile every
# script in ohmyzsh/ohmyzsh! Rein it in.
##########################################################
_zcomet_clone_repo() {
  local start_dir
  start_dir=$PWD
  _zcomet_repo_shorthand $1
  1=$REPLY

  if [[ ! -d ${ZCOMET[REPOS_DIR]}/${1} ]]; then
    print -P "%B%F{yellow}Cloning ${1}:%f%b"
    command git clone https://github.com/${1} ${ZCOMET[REPOS_DIR]}/${1} ||
      return $?
    [[ -n $branch ]] &&
      command git --git-dir=${ZCOMET[REPOS_DIR]}/${1}/.git \
        --work-tree=${ZCOMET[REPOS_DIR]}/${1} \
        checkout -q $2
    local file
    for file in ${ZCOMET[REPOS_DIR]}/${1}/**/*.zsh(N.) \
                ${ZCOMET[REPOS_DIR]}/${1}/**/prompt_*_setup(N.) \
                ${ZCOMET[REPOS_DIR]}/${1}/**/*.zsh-theme(N.); do
      _zcomet_compile $file
    done
  fi
}

############################################################
# The main command
# Globals:
#   ZCOMET
#   ZCOMET_PLUGINS
#   ZCOMET_SNIPPETS
#   ZCOMET_TRIGGERS
# Arguments:
#   load <repo> [...]
#   trigger <trigger> <repo] [...]
#   snippet <snippet>
#   update
#   unload <repo>
#   list
#   compile
#   help
# Outputs:
#   Status updates
############################################################
zcomet() {

  typeset -gUa ZCOMET_PLUGINS ZCOMET_SNIPPETS ZCOMET_TRIGGERS

  ##########################################################
  # THE MAIN ROUTINE
  ##########################################################

  local cmd orig_dir
  [[ -n $1 ]] && cmd=$1 && shift
  orig_dir=$PWD

  case $cmd in
    load)
      [[ -z $1 ]] && return 1
      local repo branch
      if [[ -n $1 ]]; then
        repo=${1%@*}
        [[ $1 == *@* ]] && branch=${1#*@}
        shift
      fi
      _zcomet_clone_repo $repo $branch || return $?
      _zcomet_load $repo $@
      ;;
    snippet)
      [[ -z $1 ]] && return 1
      local update snippet repo
      [[ $1 == '--update' ]] && update=1 && shift
      snippet=$1
      repo='https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/'
      shift
      if [[ ! -f ${ZCOMET[SNIPPETS_DIR]}/${snippet} ]] || (( update )); then
        [[ ! -d ${ZCOMET[SNIPPETS_DIR]}/${snippet%/*} ]] &&
          mkdir -p ${ZCOMET[SNIPPETS_DIR]}/${snippet%/*}
        print -P "%B%F{yellow}Downloading snippet ${snippet}:%f%b"
        curl ${repo}${snippet#OMZ::} > ${ZCOMET[SNIPPETS_DIR]}/${snippet}
        _zcomet_compile ${ZCOMET[SNIPPETS_DIR]}/${snippet}
      fi
      source ${ZCOMET[SNIPPETS_DIR]}/${snippet} &&
        _zcomet_add_list $cmd $snippet
      ;;
    trigger)
      # TODO: Allow user to create more than one trigger per command
      [[ -z $1 ]] && return 1
      local trigger
      trigger=$1 && shift
      # TODO: Add a pre-clone option
      if ! (( ${+functions[$trigger]} )); then
        functions[$trigger]="ZCOMET_TRIGGERS=( "\${(@)ZCOMET_TRIGGERS:#${trigger}}" );
          unfunction $trigger;
          zcomet load $@;
          eval $trigger \$@" && _zcomet_add_list $cmd $trigger
      else
        >&2 print "There is already a trigger named \`$trigger'."
      fi
      ;;
    unload)
      [[ -z $1 ]] && return 1
      if (( ${+functions[${1#*/}_plugin_unload]} )) &&
        ${1#*/}_plugin_unload; then
        # TODO: Something much better is needed.
        ZCOMET_PLUGINS=( ${(@)ZCOMET_PLUGINS:#*/${1}} )
        ZCOMET_PLUGINS=( ${(@)ZCOMET_PLUGINS:#*/${1} *} )
      fi
      ;;
    update)
      local i
      for i in ${ZCOMET[REPOS_DIR]}/**/.git(N/); do
        print -Pn "%B%F{yellow}${${i:h}#${ZCOMET[REPOS_DIR]}/}:%f%b "
        command git --git-dir=${i} --work-tree=${i:h} pull
        for file in ${i:h}/*.zsh(N.) \
                    ${i:h}/prompt_*_setup(N.) \
                    ${i:h}/*.zsh_theme(N.); do
          _zcomet_compile $file
        done
        (( ${ZCOMET_PLUGINS[(Ie)$i]} )) && zcomet load $i
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
      ;;
    list)
      (( ${#ZCOMET_PLUGINS} )) && print -P '%B%F{yellow}Plugins:%f%b' &&
        print -l -f '  %s\n' ${(@o)ZCOMET_PLUGINS}
      (( ${#ZCOMET_SNIPPETS} )) && print -P '%B%F{yellow}Snippets:%f%b' &&
        print -l -f '  %s\n' ${(@o)ZCOMET_SNIPPETS}
      (( ${#ZCOMET_TRIGGERS} )) && print -P '%B%F{yellow}Triggers:%f%b' &&
        print "  ${(@o)ZCOMET_TRIGGERS}"
      ;;
    compile)
      [[ -z $1 ]] && return 1
      _zcomet_compile $@
      ;;
    -h|--help|help)
      print "usage: $0 command [...]

load            load a plugin
trigger         create a shortcut for loading and running a plugin
snippet         load a snippet of code from Oh-My-ZSH
unload          unload a plugin
update          update all plugins and snippets
list            list all loaded plugins and snippets
compile         (re)compile script(s) (only when necessary)
help            print this help text" | fold -s -w $COLUMNS
      ;;
    *) zcomet help; return 1 ;;
  esac
}
