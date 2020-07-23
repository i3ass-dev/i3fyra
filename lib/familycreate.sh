#!/bin/bash

familycreate(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg ourfam theirfam split dir
  declare -i target ourfamily  theirfamily f1 f2

  trg=$1
  target=${_m[$trg]}

  ((_isvertical)) \
    && split=h dir=down  f1=${_m[AB]} f2=${_m[CD]} \
    || split=v dir=right f1=${_m[AC]} f2=${_m[BD]}

  ourfamily=$((target & f1 ? f1 : f2))
  theirfamily=$((_m[ABCD] & ~ourfamily))
  ourfam=${_n[$ourfamily]} theirfam=${_n[$theirfamily]}

  messy "[con_mark=i34X${ourfam}]" unmark
  dummywindow dummy
  messy "[con_mark=dummy]" \
    move to mark "i34X${theirfam}", split v, layout tabbed

  messy "[con_mark=i34${trg}]" \
    move to workspace "${i3list[WSA]}", \
    floating disable, \
    move to mark dummy
  messy "[con_mark=dummy]" focus, focus parent
  messy mark i34X${ourfam}

  messy "[con_mark=dummy]" \
    layout "split${split}", split "$split"
  messy "[con_mark=dummy]" kill
  messy "[con_mark=i34X${ourfam}]" move "$dir"
}
