#!/bin/bash

familycreate(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg ourfam theirfam split dir ghost
  declare -i target ourfamily  theirfamily f1 f2

  trg=$1
  target=${_m[$trg]}

  ((_isvertical)) \
    && split=h dir=down  f1=${_m[AB]} f2=${_m[CD]} \
    || split=v dir=right f1=${_m[AC]} f2=${_m[BD]}

  ourfamily=$((target & f1 ? f1 : f2))
  theirfamily=$((_m[ABCD] & ~ourfamily))
  ourfam=${_n[$ourfamily]} theirfam=${_n[$theirfamily]}

  ghost="i34${ourfam}GHOST"

  # messy "[con_mark=i34X${ourfam}]" unmark

  dummywindow "$ghost"
  messy "[con_mark=$ghost]"           \
    move to mark "i34X${_splits[0]}", \
    split "${_splitdir[1]}",          \
    layout tabbed, move "$dir"

  messy "[con_mark=i34${trg}\$]" \
    move to workspace "${i3list[WSF]}", \
    floating disable, \
    move to mark $ghost
  messy "[con_mark=$ghost]" focus, focus parent
  messy mark i34X${ourfam}
  messy "[con_mark=$ghost]" \
    layout "split${_splitdir[1]}", \
    split "${_splitdir[1]}", \
    kill
  messy "[con_mark=i34X${tfam}]" move "$dir"
}
