#!/bin/bash

containerhide(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg=$1
  local tfam sib mainsplit

  [[ ${#trg} -gt 1 ]] && multihide "$trg" && return

  declare -i family target sibling ref1 ref2 mainsize famsize

  target=${_m[$trg]}

  if ((_isvertical)); then
    mainsplit=AC
    ref1=${i3list[WFH]}
    ref2=${i3list[WFW]}
    family=$((target & _m[AB]?_m[AB]:_m[CD]))
  else
    mainsplit=AB
    ref1=${i3list[WFW]}
    ref2=${i3list[WFH]}
    family=$((target & _m[AC]?_m[AC]:_m[BD]))
  fi

  tfam=${_n[$family]}
  mainsize=${i3list[S$mainsplit]}
  famsize=${i3list[S$tfam]}

  sibling=$((family & ~target))
  sib=${_n[$sibling]}

  messy "[con_mark=i34${trg}]" move scratchpad

  # add to trg to hid
  i3list[LHI]+=$trg
  i3list[LVI]=${i3list[LVI]/$trg/}
  i3list[LVI]=${i3list[LVI]:-X}

  ((_visible &= ~target))
  ((_hidden  |= target))

  # if trg is last of it's fam, note it.
  # else focus sib
  ((! (sibling & _visible) ))       \
    && _v+=("i34F${tfam}" "$trg") \
    || i3list[SIBFOC]=$sib

  # note splits
  ((mainsize && mainsize!=ref1)) && {
    _v+=("i34M${mainsplit}" "$mainsize")
    i3list[M${mainsplit}]=$mainsize
  }

  ((famsize && famsize!=ref2)) && {
    _v+=("i34M${tfam}" "$famsize")
    i3list[M${tfam}]=$famsize
  }
}


