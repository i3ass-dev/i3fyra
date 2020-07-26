#!/bin/bash

windowmove(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"

  local dir=$1
  local ldir

  declare -i newcont

  # if dir is a container, show/create that container
  # and move the window there
  [[ $dir =~ ^A|B|C|D$ ]] && {

    [[ ${i3list[LEX]} =~ $dir ]] || newcont=1

    containershow "$dir"

    ((newcont)) || messy "[con_id=${i3list[TWC]}]"      \
                          focus, floating disable,      \
                          move to mark "i34${dir}", focus

    return

  }

  # else make sure direction is lowercase u,l,d,r
  dir=${dir,,}
  dir=${dir:0:1}

  # "exit if $dir not valid"
  [[ ! $dir =~ u|r|l|d ]] \
    && ERX "$dir not a valid direction."

  case $dir in
    l ) ldir=left  ;;
    r ) ldir=right ;;
    u ) ldir=up    ;;
    d ) ldir=down  ;;
  esac

  # if window is floating, move with i3Kornhe
  ((i3list[AWF]==1)) && {
    ((__o[verbose])) && ERM k i3Kornhe "m $ldir"
    ((__o[dryrun]))  || i3Kornhe m $ldir
    exit 
  }

  # get visible info from i3viswiz
  # trgcon is the container currently at target pos
  # trgpar is the parent of trgcon (A|B|C|D)
  local wall trgpar wizoutput
  declare -i trgcon family sibling target relatives sibdir

  ((__o[dryrun])) && [[ -z ${wizoutput:=${i3list[VISWIZ]}} ]] \
    && wizoutput='trgcon=3333 wall=up trgpar=C' 

  : "${wizoutput:="$(i3viswiz -p "$dir" | head -1)"}"

  eval "$wizoutput"
  unset trgx trgy sx sy sw sh

  declare -A swapon

  swapon[u]=${_m[AB]} swapon[d]=${_m[CD]}
  swapon[l]=${_m[AC]} swapon[r]=${_m[BD]}

  ((_isvertical)) \
    && sibdir=$((_m[l]|_m[r])) \
    || sibdir=$((_m[u]|_m[d]))

  target=${_m[${i3list[TWP]}]}
  family=${_m[${i3list[TFF]}]}
  sibling=${_m[${i3list[TFS]}]}
  relatives=${_m[${i3list[TFO]}]}

  # moving in to screen edge (wall), toggle something
  if [[ ${wall:-} != none ]]; then

    # sibling toggling
    if ((_m[$dir] & sibdir)); then
      if ((sibling & _visible)); then
        containerhide "${_n[$sibling]}"
      else
        containershow "${_n[$sibling]}"
        ((sibling & swapon[$dir])) \
          && swapmeet "i34${_n[$sibling]}" "i34${_n[$target]}"
      fi
    # family toggling
    else
      if ((relatives & _visible)); then
        familyhide "${_n[$relatives]}"
      else
        familyshow "${_n[$relatives]}"
        ((relatives & swapon[$dir])) \
          && swapmeet "i34X${_n[$relatives]}" "i34X${_n[$family]}"
      fi
    fi

  else
    # trgpar is visible, if layout is tabbed just move it
    if [[ ${i3list[C${trgpar}L]} =~ tabbed|stacked ]]; then
      
      messy "[con_id=${i3list[TWC]}]" \
        focus, floating disable, \
        move to mark "i34${trgpar}", focus
        
    elif [[ ${i3list[C${trgpar}L]} =~ splitv|splith ]]; then
      # target and current container is the same, move normaly
      if [[ $trgpar = "${i3list[TWP]}" ]]; then
        messy "[con_id=${i3list[TWC]}]" move "$ldir"

      # move below/to the right of the last child of the container  
      elif [[ $dir =~ l|u ]]; then
        messy "[con_id=${i3list[TWC]}]" \
          move to mark "i34${trgpar}", focus

      # move above/to the left of target container
      else
        messy "[con_id=${trgcon}]" mark i34tmp
        messy "[con_id=${i3list[TWC]}]" \
          move to mark "i34tmp", swap mark i34tmp
        messy "[con_id=${trgcon}]" unmark
      fi
    fi
  fi
}
