#!/bin/bash

containercreate(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"

  local trg=$1 
  local ghost="i34${trg}GHOST"

  # mainsplit is not created
  [[ -z ${i3list[X${ori[main]}]} ]] && initfyra

  [[ -z ${i3list[TWC]} ]] \
    && ERX "can't create container without window"

  dummywindow "$ghost"

  messy "[con_mark=$ghost]"            \
    move to mark "i34X${ori[main]}",   \
    split "${ori[charmain]}", layout tabbed
    
  messy "[con_id=${i3list[TWC]}]" \
    floating disable, move to mark "$ghost"
  messy "[con_mark=$ghost]" focus, focus parent
  messy mark "i34${trg}"
    
  # after creation, move cont to scratch
  messy "[con_mark=$ghost]" kill

  # run container show to show container to place
  # container in correct family, set _hidden
  # to trigger that functionality
  ((_hidden |= _m[$trg]))
  containershow "$trg"
}
