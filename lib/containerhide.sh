#!/bin/bash

containerhide(){
  local trg tfam

  trg=$1


  [[ ${#trg} -gt 1 ]] && multihide "$trg" && return

  [[ $trg =~ A|C ]] && tfam=AC || tfam=BD
  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    [[ $trg =~ A|B ]] && tfam=AB || tfam=CD
  fi

  i3-msg -q "[con_mark=i34${trg}]" focus, floating enable, \
    move absolute position 0 px 0 px, \
    resize set $((i3list[WFW]/2)) px $((i3list[WFH]/2)) px, \
    move scratchpad
  # add to trg to hid
  i3list[LHI]+=$trg
  i3list[LVI]=${i3list[LVI]/$trg/}
  i3list[LVI]=${i3list[LVI]:-X}

  # if trg is last of it's fam, note it.
  # else focus sib
  [[ ! ${tfam/$trg/} =~ [${i3list[LVI]}] ]] \
    && i3var set "i34F${tfam}" "$trg" \
    || i3list[SIBFOC]=${tfam/$trg/}

  # note splits
  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    [[ -n ${i3list[SAC]} ]] && ((i3list[SAC]!=i3list[WFH])) && {
      i3var set "i34MAC" "${i3list[SAC]}"
      i3list[MAC]=${i3list[SAC]}
    }

    [[ -n ${i3list[S${tfam}]} ]] && ((${i3list[S${tfam}]}!=i3list[WFW])) && {
      i3var set "i34M${tfam}" "${i3list[S${tfam}]}" 
      i3list[M${tfam}]=${i3list[S${tfam}]}
    }
  else
    [[ -n ${i3list[SAB]} ]] && ((i3list[SAB]!=i3list[WFW])) && {
      i3var set "i34MAB" "${i3list[SAB]}"
      i3list[MAB]=${i3list[SAB]}
    }

    [[ -n ${i3list[S${tfam}]} ]] && ((${i3list[S${tfam}]}!=i3list[WFH])) && {
      i3var set "i34M${tfam}" "${i3list[S${tfam}]}" 
      i3list[M${tfam}]=${i3list[S${tfam}]}
    }
  fi
}


