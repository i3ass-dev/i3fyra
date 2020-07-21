#!/bin/bash

windowmove(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  local dir=$1
  local trgcon wall trgpar ldir newcont

  # if dir is a container, show/create that container
  # and move the window there

  [[ $dir =~ A|B|C|D ]] && {

    [[ ! ${i3list[LEX]:-} =~ $dir ]] \
      && newcont=1 || newcont=0

    containershow "$dir"

    if ((newcont!=1)); then
      messy "[con_id=${i3list[TWC]}]" \
        focus, floating disable, \
        move to mark "i34${dir}", focus
    fi
    exit

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
  ((i3list[AWF]==1)) && { i3Kornhe m $ldir; exit ;}

  # get visible info from i3viswiz
  # trgcon is the container currently at target pos
  # trgpar is the parent of trgcon (A|B|C|D)

  eval "$(i3viswiz -p "$dir" | head -1)"

  if [[ ${wall:-} != none ]]; then

    # sibling toggling
    if [[ $dir =~ u|d ]]; then
      if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
        # if relatives is visible, hide 'em
        if [[ ${i3list[LVI]} =~ [${i3list[AFO]}] ]]; then
          familyhide "${i3list[AFO]}"
        else
            # else show container, add to swap
            familyshow "${i3list[AFO]}"
            {
              { [[ $dir = u ]] && [[ ${i3list[AFO]} = AB ]] ; } || \
              { [[ $dir = d ]] && [[ ${i3list[AFO]} = CD ]] ; }
            } && toswap=("i34X${i3list[AFO]}" "i34X${i3list[AFF]}")
        fi
      else
        # if sibling is visible, hide it
        if [[ ${i3list[AFS]} =~ [${i3list[LVI]}] ]]; then
          containerhide "${i3list[AFS]}"
        else
            # else show container, add to swap
            containershow "${i3list[AFS]}"
            {
              { [[ $dir = u ]] && [[ ${i3list[AFS]} =~ [AB] ]] ; } || \
              { [[ $dir = d ]] && [[ ${i3list[AFS]} =~ [CD] ]] ; }
            } && toswap=("i34${i3list[AFS]}" "i34${i3list[AWP]}")
        fi
      fi

    # family toggling
    elif [[ $dir =~ l|r ]]; then
      if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
        # if sibling is visible, hide it
        if [[ ${i3list[AFS]} =~ [${i3list[LVI]}] ]]; then
          containerhide "${i3list[AFS]}"
        else
            # else show container, add to swap
            containershow "${i3list[AFS]}"
            {
              { [[ $dir = l ]] && [[ ${i3list[AFS]} =~ [AC] ]] ; } || \
              { [[ $dir = r ]] && [[ ${i3list[AFS]} =~ [BD] ]] ; }
            } && toswap=("i34${i3list[AFS]}" "i34${i3list[AWP]}")
        fi
      else
        # if relatives is visible, hide 'em
        if [[ ${i3list[LVI]} =~ [${i3list[AFO]}] ]]; then
          familyhide "${i3list[AFO]}"
        else
            # else show container, add to swap
            familyshow "${i3list[AFO]}"
            {
              { [[ $dir = l ]] && [[ ${i3list[AFO]} = AC ]] ; } || \
              { [[ $dir = r ]] && [[ ${i3list[AFO]} = BD ]] ; }
            } && toswap=("i34X${i3list[AFO]}" "i34X${i3list[AFF]}")
        fi
      fi
    fi
    
    [[ -n ${toswap[1]:-} ]] \
      && swapmeet "${toswap[0]}" "${toswap[1]}" \
      && messy "[con_id=${i3list[TWC]}]" focus

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
