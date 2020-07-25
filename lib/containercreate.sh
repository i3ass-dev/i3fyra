#!/bin/bash

containercreate(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"

  local trg=$1

  [[ -z ${i3list[TWC]} ]] \
    && ERX "can't create container without window"

  messy "[con_mark=i34GHOST]"           \
    move to workspace "${i3list[WSF]}", \
    floating disable,                   \
    move to mark "i34X${_splits[0]}",   \
    split h, layout tabbed
    
  messy "[con_id=${i3list[TWC]}]" \
    floating disable, move to mark i34GHOST
  messy "[con_mark=i34GHOST]" focus, focus parent
  messy mark "i34${trg}"
    
  # after creation, move cont to scratch
  messy "[con_mark=i34GHOST]", floating enable,  move scratchpad
  messy "[con_mark=i34${trg}]" move scratchpad

  ((_hidden |= _m[$trg]))
  # run container show to show container
  containershow "$trg"
}
