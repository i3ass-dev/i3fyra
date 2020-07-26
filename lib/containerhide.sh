#!/bin/bash

containerhide(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg=$1
  local tfam sib main

  [[ ${#trg} -gt 1 ]] && {
    multihide "$trg"
    return
  }

  declare -i target sibling splitmain splitfam

  main=${ori[main]}
  splitmain=${i3list[S$main]}
  splitfam=${i3list[S$tfam]}

  [[ ${tfam:=${ori[fam1]}} =~ $trg ]] || tfam=${ori[fam2]}

  target=${_m[$trg]}
  sibling=$((_m[$tfam] & ~target))
  sib=${_n[$sibling]}

  messy "[con_mark=i34${trg}]" move scratchpad

  ((_visible &= ~target))
  ((_hidden  |= target))

  # if trg is last of it's fam, note it.
  # else focus sib
  ((! (sibling & _visible) ))  \
    && _v["i34F${tfam}"]=$trg  \
    || i3list[SIBFOC]=$sib

  # note splits
  ((splitmain && splitmain!=ori[sizemain])) && {
    _v["i34M${main}"]=$splitmain
    i3list[M${main}]=$splitmain
  }

  ((splitfam && splitfam!=ori[sizefam])) && {
    _v["i34M${tfam}"]=$splitfam
    i3list[M${tfam}]=$splitfam
  }
}


