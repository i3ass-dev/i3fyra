#!/bin/bash

containercreate(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"

  local trg=$1

  [[ -z ${i3list[TWC]} ]] \
    && ERX "can't create container without window"

  dummywindow dummy

  messy "[con_mark=dummy]" split h, layout tabbed
  messy "[con_id=${i3list[TWC]}]" \
    floating disable, move to mark dummy
  messy "[con_mark=dummy]" focus parent
  # messy "[con_mark=dummy]" focus, focus parent
  messy mark "i34${trg}"
  messy "[con_mark=dummy]" kill
    
  # after creation, move cont to scratch
  messy "[con_mark=i34${trg}]" move scratchpad

  ((_hidden |= _m[$trg]))
  # run container show to show container
  containershow "$trg"
}
