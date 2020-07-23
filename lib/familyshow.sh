#!/bin/bash

# trg=$1
# target=${_m[$trg]}

# ((_isvertical)) \
#   && split=h dir=down  f1=${_m[AB]} f2=${_m[CD]} \
#   || split=v dir=right f1=${_m[AC]} f2=${_m[BD]}

# ourfamily=$((target & f1 ? f1 : f2))
# theirfamily=$((_m[ABCD] & ~ourfamily))
# ourfam=${_n[$ourfamily]} theirfam=${_n[$theirfamily]}

# messy "[con_mark=i34X${ourfam}]" unmark
# dummywindow dummy
# messy "[con_mark=dummy]" \
#   move to mark "i34X${theirfam}", split v, layout tabbed

# messy "[con_mark=i34${trg}]" \
#   move to workspace "${i3list[WSA]}", \
#   floating disable, \
#   move to mark dummy
# messy "[con_mark=dummy]" focus, focus parent
# messy mark i34X${ourfam}

# messy "[con_mark=dummy]" \
#   layout "split${split}", split "$split"
# messy "[con_mark=dummy]" kill
# messy "[con_mark=i34X${ourfam}]" move "$dir"

familyshow(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"

  local ourfam=$1 trg theirfam

  declare -i i target ourfamily theirfamily

  ourfamily=${_m[$ourfam]}
  theirfamily=$((_m[ABCD] & ~ourfamily))
  theirfam=${_n[$theirfamily]}

  _famact=1
  for ((i=0;i<${#ourfam};i++)); do
    trg=${ourfam:$i:1}
    target=${_m[$trg]}
    ((target & _hidden)) \
      && ((_hidden &= ~target)) && ((_visible |= target))
    # containershow "$trg"
  done

  if ((_isvertical)); then
    split=h dir=down
    i3list[SAC]=$((i3list[WFH]/2))
    splits="AC=${i3list[MAC]}"
  else
    split=v dir=right
    i3list[SAB]=$((i3list[WFW]/2))
    splits="AB=${i3list[MAB]}"
  fi

  messy "[con_mark=i34X${theirfam}]" \
    split "$split", focus, focus parent
  messy mark i34templar
  messy "[con_mark=i34X${ourfam}]" \
    move to workspace "${i3list[WSA]}", \
    floating disable, \
    move to mark "i34templar", \
    move "$dir"
  messy "[con_mark=i34templar]" unmark

  applysplits "$splits"

}
