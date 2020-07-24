#!/bin/env bash

layoutcreate(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg fam s1 s2
  declare -i target f1 f2

  trg=$1
  target=${_m[$trg]}

  ((_isvertical)) \
    && s1=h s2=v m=AC f1=${_m[AB]} f2=${_m[CD]} \
    || s1=v s2=h m=AB f1=${_m[AC]} f2=${_m[BD]}

  fam=${_n[$((target & f1 ? f1 : f2))]}

  messy workspace "${i3list[WSF]}"
  dummywindow dummy
  
  messy "[con_mark=dummy]" \
    split v, layout tabbed
  
  messy "[con_mark=i34${trg}]" \
    move to workspace "${i3list[WSA]}", \
    floating disable, \
    move to mark dummy

  messy "[con_mark=dummy]" focus, focus parent
  messy mark "i34X${fam}"
  messy "[con_mark=i34X${fam}]" "split${s2}", split "$s2", focus, focus parent
  messy mark "i34X${m}"
  messy "[con_mark=i34X${m}]" layout "split${s1}", split "$s1"
  messy "[con_mark=i34${trg}]" focus child
  messy "[con_mark=dummy]" kill

}
