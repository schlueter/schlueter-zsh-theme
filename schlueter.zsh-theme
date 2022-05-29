# vim: set ft=zsh expandtab tabstop=2 shiftwidth=2:
# A two-line, Powerline-inspired theme that displays contextual information.
#
# This theme requires a patched Powerline font, get them from
# https://github.com/Lokaltog/powerline-fonts.
#
# Authors:
#   Isaac Wolkerstorfer <i@agnoster.net>
#   Jeff Sandberg <paradox460@gmail.com>
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#   Brandon Schlueter <bs@bschlueter.com>
#
# Screenshots:
#   http://i.imgur.com/0XIWX.png
#

# Load dependencies.
pmodload 'helper'

# Define variables.
_prompt_paradox_current_bg=default
_prompt_paradox_initial_segment_separator=
_prompt_paradox_segment_separator=
_prompt_paradox_start_time=$SECONDS

function prompt_paradox_start_no_sep_segment {
  local bg="%K{$1}"
  local fg="%F{$2}"
  if [[ $_prompt_paradox_current_bg == default && $bg != '%K{default}' ]]
  then
    print -n "$bg$fg"
  elif [[ $bg != "%K{$_prompt_paradox_current_bg}" ]]
  then
    print -n "$bg$fg "
  else
    print -n "$bg$fg"
  fi
  _prompt_paradox_current_bg="$1"
  [[ -n "$3" ]] && print -n "$3"
}

function prompt_paradox_start_segment {
  local bg="%K{$1}"
  local fg="%F{$2}"
  if [[ $_prompt_paradox_current_bg == default && $bg != '%K{default}' ]]
  then
    print -n "%F{$1}$_prompt_paradox_initial_segment_separator$bg$fg "
  elif [[ $bg != "%K{$_prompt_paradox_current_bg}" ]]
  then
    print -n "$bg%F{$_prompt_paradox_current_bg}$_prompt_paradox_segment_separator$fg "
  else
    print -n "$bg$fg"
  fi
  _prompt_paradox_current_bg="$1"
  [[ -n "$3" ]] && print -n "$3"
}

function prompt_paradox_end_segment {
  if [[ -n "$_prompt_paradox_current_bg" && "$_prompt_paradox_current_bg" != 'default' ]]
  then
    print -n " %k%F{$_prompt_paradox_current_bg}$_prompt_paradox_segment_separator"
  else
    print -n "%k"
  fi
  print -n "%f"
  _prompt_paradox_current_bg=''
}

function prompt_process_info {
  prompt_paradox_start_segment default default '%(!:%F{yellow}⚡  :)%(1j:%F{cyan}⚙  :)'
}

function prompt_paradox_build_prompt {
  local prompt_char
  if [[ -n "$SSH_CLIENT" ]] \
  || [[ -n "$SSH_TTY" ]]
  then
    prompt_paradox_start_no_sep_segment yellow black '%n'
    prompt_paradox_start_segment yellow red '@'
    prompt_paradox_start_segment yellow black '%M'
  fi

  if [[ -z "$git_info" ]]
  then
    prompt_paradox_start_segment default blue '$_abbrev_pwd '
    prompt_process_info
  else
    prompt_paradox_start_segment default blue '$_unabbrev_pwd '
    prompt_process_info
    prompt_paradox_start_segment default magenta '${(e)git_info[ref]}${(e)git_info[status]}'
    print -n " \n"
  fi
  prompt_char="${editor_info[keymap]}"
  if [ ! -z "$prompt_char" ]
  then
    print -n "$prompt_char"
  else
    print -n "%(?;%B%F{blue};%B%F{red})$ %f%b"
  fi

  prompt_paradox_end_segment
}

function prompt_paradox_pwd {
  local pwd="${PWD/#$HOME/~}"

  if [[ "$pwd" == (#m)[/~] ]]
  then
    _abbrev_pwd="~"
    _unabbrev_pwd="~"
  else
    _unabbrev_pwd="$pwd"
    _abbrev_pwd="${${${${(@j:/:M)${(@s:/:)pwd}##.#?}:h}%/}//\%/%%}/${${pwd:t}//\%/%%}"
  fi
}

function prompt_paradox_print_elapsed_time {
  local end_time=$(( SECONDS - _prompt_paradox_start_time ))
  local hours minutes seconds remainder

  if (( end_time >= 3600 ))
  then
    hours=$(( end_time / 3600 ))
    remainder=$(( end_time % 3600 ))
    minutes=$(( remainder / 60 ))
    seconds=$(( remainder % 60 ))
    print -P "%B%F{red}>>> elapsed time ${hours}h${minutes}m${seconds}s%b"
  elif (( end_time >= 60 ))
  then
    minutes=$(( end_time / 60 ))
    seconds=$(( end_time % 60 ))
    print -P "%B%F{yellow}>>> elapsed time ${minutes}m${seconds}s%b"
  elif (( end_time > 10 ))
  then
    print -P "%B%F{green}>>> elapsed time ${end_time}s%b"
  fi
}

function prompt_paradox_precmd {
  setopt LOCAL_OPTIONS
  unsetopt XTRACE KSH_ARRAYS

  # Format PWD.
  prompt_paradox_pwd

  # Get Git repository information.
  if (( $+functions[git-info] ))
  then
    git-info
  fi

  # Calculate and print the elapsed time.
  prompt_paradox_print_elapsed_time
}

function prompt_paradox_preexec {
  _prompt_paradox_start_time="$SECONDS"
}

function prompt_paradox_setup {
  setopt LOCAL_OPTIONS
  unsetopt XTRACE KSH_ARRAYS
  prompt_opts=(cr percent subst)

  # Load required functions.
  autoload -Uz add-zsh-hook

  # Add hook for calling git-info before each command.
  add-zsh-hook preexec prompt_paradox_preexec
  add-zsh-hook precmd prompt_paradox_precmd

  # Set editor-info parameters.
  zstyle ':prezto:module:editor:info:completing' format '%B%F{red}...%f%b'
  zstyle ':prezto:module:editor:info:keymap:primary' format ''
  zstyle ':prezto:module:editor:info:keymap:primary:overwrite' format '%F{red}♺%f'
  zstyle ':prezto:module:editor:info:keymap:alternate' format '%B%F{red}❮%f%b'

  # Set git-info parameters.
  zstyle ':prezto:module:git:info' verbose 'yes'
  zstyle ':prezto:module:git:info:action' format ' ⁝ %s'
  zstyle ':prezto:module:git:info:added' format ' ✚'
  zstyle ':prezto:module:git:info:ahead' format ' ⬆'
  zstyle ':prezto:module:git:info:behind' format ' ⬇'
  zstyle ':prezto:module:git:info:branch' format ' %b'
  zstyle ':prezto:module:git:info:commit' format '➦ %.7c'
  zstyle ':prezto:module:git:info:deleted' format ' ✖'
  zstyle ':prezto:module:git:info:dirty' format ' ⁝'
  zstyle ':prezto:module:git:info:modified' format ' ✱'
  zstyle ':prezto:module:git:info:position' format '%p'
  zstyle ':prezto:module:git:info:renamed' format ' ➙'
  zstyle ':prezto:module:git:info:stashed' format ' S'
  zstyle ':prezto:module:git:info:unmerged' format ' ═'
  zstyle ':prezto:module:git:info:untracked' format ' ?'
  zstyle ':prezto:module:git:info:tag_prefix' format 'Ⓣ '
  zstyle ':prezto:module:git:info:keys' format \
    'ref' '%c $(coalesce "%b" "%p")' \
    'status' '%s%D%A%B%S%a%d%m%r%U%u'

  # Define prompts.
  PROMPT='${(e)$(prompt_paradox_build_prompt)}'
  SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '
}

prompt_paradox_setup "$@"
