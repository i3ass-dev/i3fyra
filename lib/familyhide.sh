#!/bin/bash

familyhide(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg famchk tfam=$1

  declare -i target i

  for ((i=0;i<${#tfam};i++)); do

    trg=${tfam:$i:1}
    target=${_m[$trg]}

    if ((target & _visible)); then
      # messy "[con_mark=i34${trg}]" move scratchpad

      ((_visible &= ~target))
      ((_hidden  |= target))

      famchk+=${trg}
    fi
  done

  declare -i famw famh famx famy fams

  fams=$(( (_isvertical ? i3list[WFH] : i3list[WFW]) - i3list[S${ori[main]}] ))
  ((fams < 0)) && ((fams *= -1))

  famw=$((_isvertical ? i3list[WFW] : fams ))
  famh=$((_isvertical ? fams : i3list[WFH]))
  famx=$((_isvertical ? 0 : i3list[S${ori[main]}]))
  famy=$((_isvertical ? i3list[S${ori[main]}] : 0))

  messy "[con_mark=i34X${tfam}]" floating enable, \
    resize set "$famw" "$famh",                   \
    move absolute position "$famx" px "$famy" px, \
    move scratchpad

  _v["i34F${tfam}"]=${famchk}
  _v["i34M${ori[main]}"]=${i3list[S${ori[main]}]:=0}
  _v["i34M${tfam}"]=${i3list[S${tfam}]:=0}

}
