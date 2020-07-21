#!/bin/bash

familycreate(){
  local trg tfam ofam
  trg=$1

  if [[ $trg =~ A|C ]];then
    tfam=AC
    ofam=BD
  else
    ofam=AC
    tfam=BD
  fi

  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    if [[ $trg =~ A|B ]];then
      tfam=AB
      ofam=CD
    else
      ofam=AB
      tfam=CD
    fi
  fi

  i3-msg -q "[con_mark=i34X${tfam}]" unmark
  i3gw gurra  > /dev/null 2>&1
  i3-msg -q "[con_mark=gurra]" \
    move to mark "i34X${ofam}", split v, layout tabbed

  i3-msg -q "[con_mark=i34${trg}]" \
    move to workspace "${i3list[WSA]}", \
    floating disable, \
    move to mark gurra
  i3-msg -q "[con_mark=gurra]" focus, focus parent
  i3-msg -q mark i34X${tfam}

  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    i3-msg -q "[con_mark=gurra]" layout splith, split h
    i3-msg -q "[con_mark=gurra]" kill
    i3-msg -q "[con_mark=i34X${tfam}]" move down
  else
    i3-msg -q "[con_mark=gurra]" layout splitv, split v
    i3-msg -q "[con_mark=gurra]" kill
    i3-msg -q "[con_mark=i34X${tfam}]" move right
  fi

}
