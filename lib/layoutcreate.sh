#!/bin/env bash

layoutcreate(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg fam

  trg=$1

  messy workspace "${i3list[WSF]}"

  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    [[ $trg =~ A|B ]] && fam=AB || fam=CD 
    messy "[con_mark=i34XAC]" unmark
  else
    [[ $trg =~ A|C ]] && fam=AC || fam=BD
    messy "[con_mark=i34XAB]" unmark
  fi

  # i3gw gurra  > /dev/null 2>&1
  ((_dummy)) || dummywindow
  
  messy "[con_id=$_dummy]" \
    split v, layout tabbed
  
  messy "[con_mark=i34${trg}]" \
    move to workspace "${i3list[WSA]}", \
    floating disable, \
    move to mark "$_dummy"

  messy "[con_id=$_dummy]" focus parent
  messy mark i34X${fam}, focus parent

  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    messy "[con_id=$_dummy]" layout splith, split h
    # messy "[con_id=$_dummy]" kill
    messy "[con_mark=i34XAC]" layout splitv, split v
  else
    messy "[con_id=$_dummy]" layout default, split v
    # messy "[con_id=$_dummy]" kill
    messy "[con_mark=i34XAB]" layout splith, split h
  fi

}