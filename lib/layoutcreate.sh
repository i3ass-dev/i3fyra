#!/bin/env bash

layoutcreate(){
  local trg fam

  trg=$1

  i3-msg -q workspace "${i3list[WSF]}"

  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    [[ $trg =~ A|B ]] && fam=AB || fam=CD 
    i3-msg -q "[con_mark=i34XAC]" unmark
  else
    [[ $trg =~ A|C ]] && fam=AC || fam=BD
    i3-msg -q "[con_mark=i34XAB]" unmark
  fi

  i3gw gurra  > /dev/null 2>&1
  
  i3-msg -q "[con_mark=gurra]" \
    split v, layout tabbed
  
  i3-msg -q "[con_mark=i34${trg}]" \
    move to workspace "${i3list[WSA]}", \
    floating disable, \
    move to mark gurra

  i3-msg -q "[con_mark=gurra]" focus parent
  i3-msg -q mark i34X${fam}, focus parent

  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    i3-msg -q "[con_mark=gurra]" layout splith, split h
    i3-msg -q "[con_mark=gurra]" kill
    i3-msg -q "[con_mark=i34XAC]" layout splitv, split v
  else
    i3-msg -q "[con_mark=gurra]" layout default, split v
    i3-msg -q "[con_mark=gurra]" kill
    i3-msg -q "[con_mark=i34XAB]" layout splith, split h
  fi

}
