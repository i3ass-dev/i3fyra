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
  local wall trgpar wizoutput groupsize
  declare -i trgcon family sibling target relatives sibdir

  ((__o[dryrun])) && [[ -z ${wizoutput:=${i3list[VISWIZ]}} ]] \
    && wizoutput='trgcon=3333 wall=up trgpar=C groupsize=1' 

  read -r wall trgpar groupsize trgcon < <(
    i3viswiz --parent "$dir" \
             --debug "wall,trgpar,groupsize,trgcon" \
             --debug-format "%v "
  )
  # : "${wizoutput:=$(i3viswiz -p "$dir" | head -1)}"

  # eval "$wizoutput"

  wizoutput="trgcon=$trgcon wall=$wall trgpar=$trgpar groupsize=$groupsize"
  # wizoutput="tx=${trgx:=} ty=${trgy:=} con=${trgcon:=} "
  # wizoutput+="wall=${wall:=} par=${trgpar:=} size=${groupsize:=}"

  ((__o[verbose])) && ERM "w $wizoutput"

  # unset trgx trgy sx sy sw sh

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

  if [[ ${wall:-} != none ]]; then # hit wall, toggle something

    if ((_m[$dir] & sibdir)); then # sibling toggling
      
      local sib=${_n[$sibling]}

      if ((sibling & _visible)); then
        containerhide "$sib"
      elif ((sibling & _hidden)); then
        containershow "$sib"
        ((sibling & swapon[$dir])) \
          && swapmeet "i34$sib" "i34${_n[$target]}"
      elif ((groupsize > 1)); then # sibling doesn't exist
        # groupsize comes from viswiz and is the number
        # of real siblings in the current container
        # if its not more then one, do nothing
        windowmove "$sib"
        ((sibling & swapon[$dir])) \
          || swapmeet "i34$sib" "i34${_n[$target]}"
      fi
    
    else # family toggling

      local rel=${_n[$relatives]}

      if ((relatives & _visible)); then
        familyhide "$rel"
      elif ((relatives & _hidden)); then
        familyshow "$rel"
        ((relatives & swapon[$dir])) \
          && swapmeet "i34X$rel" "i34X${_n[$family]}"
      elif ((groupsize > 1)); then # relatives doesn't exist
        # groupsize comes from viswiz and is the number
        # of real siblings in the current container
        # if its not more then one, do nothing
        windowmove "${rel:0:1}"
        ((relatives & swapon[$dir])) \
          || swapmeet "i34X$rel" "i34X${_n[$family]}"
      fi
    fi

  else # trgpar is visible
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
