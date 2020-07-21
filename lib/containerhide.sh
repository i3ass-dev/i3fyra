#!/bin/env bash

containerhide(){

  ERM "containerhide"
  ERM "============="

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

  messy "[con_mark=i34${trg}]" focus, floating enable, \
    move absolute position 0 px 0 px, \
    resize set $((i3list[WFW]/2)) px $((i3list[WFH]/2)) px, \
    move scratchpad

  # add to trg to hid
  i3list[LHI]+=$trg
  i3list[LVI]=${i3list[LVI]/$trg/}
  i3list[LVI]=${i3list[LVI]:-X}

  ((_visible &= ~target))

  # if trg is last of it's fam, note it.
  # else focus sib
  (( ! sibling & _visible )) \
    && i3var set "i34F${tfam}" "$trg" \
    || i3list[SIBFOC]=$sib

  # note splits
  ((mainsize && mainsize!=ref1)) && {
    i3var set "i34M${mainsplit}" "$mainsize"
    i3list[MAC]=$mainsize
  }

  (( famsize && famsize!=ref2)) && {
    i3var set "i34M${tfam}" "$famsize"
    i3list[M${tfam}]=$famsize
  }
}
