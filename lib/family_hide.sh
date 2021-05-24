#!/bin/bash

family_hide(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local family=$1
  local child childs

  declare -i famw famh famx famy split_size

  split_size=$(( ( _isvertical ? i3list[WFH] : i3list[WFW] ) - i3list["S${ori[main]}"] ))
  ((split_size < 0)) && ((split_size *= -1))

  famw=$((_isvertical ? i3list[WFW] : split_size ))
  famh=$((_isvertical ? split_size : i3list[WFH]))
  famx=$((_isvertical ? 0 : i3list["S${ori[main]}"]))
  famy=$((_isvertical ? i3list["S${ori[main]}"] : 0))

  messy "[con_mark=i34X${family}]"                \
    floating enable,                              \
    resize set "$famw" "$famh",                   \
    move absolute position "$famx" px "$famy" px, \
    move scratchpad

  for child in "${family:0:1}" "${family:1:1}"; do
    [[ ${i3list[LVI]} =~ $child ]] || continue
    i3list[LVI]=${i3list[LVI]/$child/}
    i3list[LHI]+=$child
    childs+=$child
  done

  mark_vars["i34F${family}"]=$childs
  mark_vars["i34M${ori[main]}"]=${i3list[S${ori[main]}]:=0}
  mark_vars["i34M${family}"]=${i3list[S${family}]:=0}

}
