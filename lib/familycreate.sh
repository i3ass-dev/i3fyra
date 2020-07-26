#!/bin/bash

familycreate(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg=$1 tfam ghost
  declare -i target=${_m[$trg]}

  [[ ${tfam:=${ori[fam1]}} =~ $trg ]] || tfam=${ori[fam2]}

  ghost="i34${tfam}GHOST"

  # messy "[con_mark=i34X${tfam}]" unmark

  dummywindow "$ghost"
  messy "[con_mark=$ghost]"             \
    move to mark "i34X${ori[main]}",    \
    split "${ori[charfam]}",            \
    layout tabbed,                      \
    move "${ori[movemain]}"

  messy "[con_mark=i34${trg}\$]"        \
    move to workspace "${i3list[WSF]}", \
    floating disable,                   \
    move to mark "$ghost",              \
    layout "split${ori[charfam]}",      \
    split "${ori[charfam]}",            \
    focus, focus parent

  messy mark "i34X${tfam}"
  # combine with above?
  messy "[con_mark=i34X${tfam}]" \
    move "${ori[movemain]}"

  messy "[con_mark=$ghost]" kill
  
  i3list[X${tfam}]=${i3list[WSF]}
}
