#!/bin/env bash

containershow(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  # show target ($1/trg) container (A|B|C|D)
  # if it already is visible, do nothing.
  # if it doesn't exist, create it 
  local trg sts tfam sib tdest famshow tmrk tspl tdim

  # trg = target container
  # sts = status (none|visible|hidden)

  trg=$1

  declare -i target

  target=${_m[$trg]}

  ((target & _m[ABCD])) \
    || ERX "$trg is not a valid container name (ABCD)"
  
  ERM "$trg : $(tobin $_visible)"

  if ((target & _visible)); then
    return 0
  elif ((target & _hidden)); then
    # sib = sibling, tfam = family
    if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
      [[ $trg =~ [AB] ]] \
        && tfam=AB \
        || tfam=CD
    else
      [[ $trg =~ [AC] ]] \
        && tfam=AC \
        || tfam=BD
    fi

    sib=${tfam/$trg/}


    # if sibling is visible, tdest (destination)
    # otherwise XAB, main container
    if [[ ${sib} =~ [${i3list[LVI]}] ]]; then
      tdest="i34X${tfam}"
    elif [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
      tdest=i34XAC
    else
      tdest=i34XAB
    fi
    
    # if if no containers are visible create layout
    if [[ -z ${i3list[LVI]} ]]; then
      layoutcreate "$trg"
    else
      # if tdest is XAB, trg is first in family
      if { [[ ${I3FYRA_ORIENTATION,,} = vertical ]] && [[ $tdest = i34XAC ]] ;}; then
        familycreate "$trg"
        famshow=1
      elif { [[ ${I3FYRA_ORIENTATION,,} != vertical ]] && [[ $tdest = i34XAB ]] ;}; then
        familycreate "$trg"
        famshow=1
      else
        # WSA = active workspace
        messy "[con_mark=i34${trg}]" \
          move to workspace "${i3list[WSA]}", \
          floating disable, move to mark "$tdest"
      fi

      # swap - what to swap
      swap=()

      if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
        [[ $tdest = i34XAC ]] && [[ $sib =~ A|B ]] \
          && swap=("X$tfam" "X${i3list[LAL]/$tfam/}")

        [[ $tdest = i34X${tfam} ]] && [[ $sib =~ B|D ]] \
          && swap=("$trg" "${tfam/$trg/}")

        if [[ $tdest = i34XAC ]]; then
          tspl=${i3list[MAC]}  # stored split
          tdim=${i3list[WFH]}  # workspace width
          tmrk=AC
        else
          tspl=${i3list[M${tfam}]}
          tdim=${i3list[WFW]}      
          tmrk=$tfam 
        fi

        [[ ${#swap[@]} -gt 0 ]] && {
          messy "[con_mark=i34${swap[0]}]" \
            swap container with mark "i34${swap[1]}"
        }

        [[ -n $tspl ]] \
          && { ((tdim==i3list[WFW])) || ((_famact!=1)) ;} && {
            i3list[S${tmrk}]=$((tdim/2))
            eval "applysplits $tmrk=$tspl"
        }
      else
        [[ $tdest = i34XAB ]] && [[ $sib =~ A|C ]] \
          && swap=("X$tfam" "X${i3list[LAL]/$tfam/}")

        [[ $tdest = i34X${tfam} ]] && [[ $sib =~ C|D ]] \
          && swap=("$trg" "${tfam/$trg/}")

        if [[ $tdest = i34XAB ]]; then
          tspl=${i3list[MAB]}  # stored split
          tdim=${i3list[WFW]}  # workspace width
          tmrk=AB
        else
          tspl=${i3list[M${tfam}]}
          tdim=${i3list[WFH]}      
          tmrk=$tfam 
        fi

        [[ ${#swap[@]} -gt 0 ]] && {
          messy "[con_mark=i34${swap[0]}]" \
            swap container with mark "i34${swap[1]}"
        }

        [[ -n $tspl ]] \
          && { ((tdim==i3list[WFH])) || ((_famact!=1)) ;} && {
            i3list[S${tmrk}]=$((tdim/2))
            eval "applysplits $tmrk=$tspl"
        }
      fi
     
    fi

    i3list[LVI]+=$trg
    i3list[LHI]=${i3list[LHI]/$trg/}

    # bring the whole family
    [[ ${famshow:-} = 1 ]] && [[ $sib =~ [${i3list[LHI]}] ]] \
      && containershow "$sib"
  else
    containercreate "$trg"
  fi
}
