#!/bin/bash

familycreate(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
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

  messy "[con_mark=i34X${tfam}]" unmark

  dummywindow dummy
  
  messy "[con_mark=dummy]" \
    move to mark "i34X${ofam}", split v, layout tabbed

  messy "[con_mark=i34${trg}]" \
    move to workspace "${i3list[WSA]}", \
    floating disable, \
    move to mark dummy
  messy "[con_mark=dummy]" focus, focus parent
  messy mark i34X${tfam}

  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    messy "[con_mark=dummy]" layout splith, split h
    messy "[con_mark=dummy]" kill
    messy "[con_mark=i34X${tfam}]" move down
  else
    messy "[con_mark=dummy]" layout splitv, split v
    messy "[con_mark=dummy]" kill
    messy "[con_mark=i34X${tfam}]" move right
  fi

}
