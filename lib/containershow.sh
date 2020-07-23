#!/bin/bash

containershow(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  # show target ($1/trg) container (A|B|C|D)
  # if it already is visible, do nothing.
  # if it doesn't exist, create it 
  local trg=$1

  declare -i target
  target=${_m[$trg]}

  ((target & _m[ABCD])) || ERX "$trg not valid container"

  if ((target & _visible)); then
    return 0

  # if if no containers are visible create layout
  elif ((!_visible)); then
    layoutcreate "$trg"
  
  elif ((target & _hidden)); then

    declare -i family sibling dest tspl tdim
    declare -i famshow size1 size2

    local tfam sib tdest tmrk mainsplit 
    local mainfam sibgroup

    declare -a swap=()

    if ((_isvertical)); then
      mainsplit=AC
      mainfam=AB
      sibgroup=BD
      size1=${i3list[WFH]}
      size2=${i3list[WFW]}

    else
      mainsplit=AB
      mainfam=AC
      sibgroup=CD
      size1=${i3list[WFW]}
      size2=${i3list[WFH]}

    fi

    family=$((target & _m[$mainfam] ? _m[$mainfam] 
           :( _m[ABCD] & ~_m[$mainfam] ) ))

    sibling=$((family & ~target))
    dest=$((sibling & _visible ? family : _m[$mainsplit]))
    tfam=${_n[$family]}
    sib=${_n[$sibling]}
    tdest=i34X${_n[$dest]}

    # if tdest is main container, trg is first in family
    if ((dest == _m[$mainsplit])) ; then

      familycreate "$trg"
      famshow=1

      tspl=${i3list[M$mainsplit]}  # stored split
      tdim=$size1                  # workspace width
      tmrk=$mainsplit

      ((sibling & _m[$mainfam])) \
        && swap=("X$tfam" "X${i3list[LAL]/$tfam/}")

    else
      # WSA = active workspace
      messy "[con_mark=i34${trg}]" \
        move to workspace "${i3list[WSA]}", \
        floating disable, move to mark "$tdest"

      tspl=${i3list[M${tfam}]}
      tdim=$size2     
      tmrk=$tfam

      ((sibling & _m[$sibgroup])) && swap=("$trg" "$sib")

    fi

    ((${#swap[@]})) && {
      messy "[con_mark=i34${swap[0]}]" \
        swap container with mark "i34${swap[1]}"
    }

    ((tspl)) \
      && ((tdim==size2 || !_famact)) && {
        i3list[S${tmrk}]=$((tdim/2))
        applysplits "$tmrk=$tspl"
    }

    ((_visible |= target)) && ((_hiddent &= ~target))

    # bring the whole family
    ((famshow && sibling & _hidden)) && containershow "$sib"

  else
    containercreate "$trg"
  fi
}
