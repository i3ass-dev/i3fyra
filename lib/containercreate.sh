#!/bin/bash

containercreate(){

  local trg=$1

  # error can't create container without window
  [[ -z ${i3list[TWC]} ]] && exit 1

  i3gw gurra  > /dev/null 2>&1
  i3-msg -q "[con_mark=gurra]" \
    split h, layout tabbed
  i3-msg -q "[con_id=${i3list[TWC]}]" \
    floating disable, move to mark gurra
  i3-msg -q "[con_mark=gurra]" \
    focus, focus parent
  i3-msg -q mark "i34${trg}"
  i3-msg -q "[con_mark=gurra]" kill
    
  # after creation, move cont to scratch
  i3-msg -q "[con_mark=i34${trg}]" focus, floating enable, \
    move absolute position 0 px 0 px, \
    resize set $((i3list[WFW]/2)) px $((i3list[WFH]/2)) px, \
    move scratchpad
  # add to trg to hid
  i3list[LHI]+=$trg
  # run container show to show container
  containershow "$trg"
}
