#!/bin/bash

containershow(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  # show target ($1/trg) container (A|B|C|D)
  # if it already is visible, do nothing.
  # if it doesn't exist, create it 
  local trg=$1
  declare -i target=${_m[$trg]}

  ((target & _m[ABCD])) || ERX "$trg not valid container"

  if ((target & _visible)); then
    return 0
  
  elif ((target & _hidden)); then

    declare -i family sibling dest tspl tdim swapon
    local tfam sib tdest tmrk main 

    main=${ori[main]}
    [[ ${tfam:=${ori[fam1]}} =~ $trg ]] || tfam=${ori[fam2]}

    family=${_m[$tfam]}
    sibling=$((family & ~target))
    dest=$((sibling & _visible ? family : _m[$main]))
    sib=${_n[$sibling]}
    tdest=i34X${_n[$dest]}

    swapon=$((_m[ABCD] & ~_m[$main]))

    # remove target from hidden here otherwise
    # familycreation gets borked up
    ((_hidden &= ~target))

    if ((dest == _m[$main])) ; then

      familyshow "$trg"

    else
      # WSA = active workspace
      messy "[con_mark=i34${trg}]" \
        move to workspace "${i3list[WSF]}", \
        floating disable, move to mark "$tdest"

      tspl=${i3list[M${tfam}]}
      tdim=${ori[sizefam]}     
      tmrk=$tfam

      ((_visible |= target))

      ((sibling & swapon)) && {
        messy "[con_mark=i34$trg]" \
          swap container with mark "i34$sib"
      }

      ((tspl && (tdim==tspl || !_famact) )) && {
          i3list[S${tmrk}]=$((tdim/2))
          applysplits "$tmrk=$tspl"
      }

    fi

  else
    containercreate "$trg"
  fi
}
