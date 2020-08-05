#!/bin/bash

familyshow(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"

  local arg=$1 ourfam trg theirfam

  [[ ${ourfam:=${ori[fam1]}} =~ ${arg:0:1} ]] \
    || ourfam=${ori[fam2]}

  declare -i i target newfamily
  declare -i ourfamily theirfamily firstfam

  ourfamily=${_m[$ourfam]}

  # our family doesn't exist
  # familycreate expects single char arg
  # where arg is an already created container
  [[ -z ${i3list[X$ourfam]} ]] && {
    familycreate "${arg:0:1}"
    newfamily=1
  }

  theirfamily=$((_m[ABCD] & ~ourfamily))
  theirfam=${_n[$theirfamily]}

  _famact=1
  for ((i=0;i<${#ourfam};i++)); do
    trg=${ourfam:$i:1}
    target=${_m[$trg]}
    if ((target & _hidden)); then
      ((_hidden &= ~target))
      ((_visible |= target))
    fi
  done

  i3list[S${ori[main]}]=${ori[sizemainhalf]}

  ((newfamily)) || messy "[con_mark=i34X${ourfam}]"    \
                   move to workspace "${i3list[WSF]}", \
                   floating disable,                   \
                   move to mark "i34X${ori[main]}"

  # if $ourfam is the first and the otherfamily
  # is visible swap'em
  firstfam=${_m[${ori[fam1]}]}
  ((ourfamily == firstfam && theirfamily & _visible)) \
    && messy "[con_mark=i34X${ourfam}]" \
       swap container with mark "i34X${theirfam}"

  applysplits "${ori[main]}=${i3list[M${ori[main]}]}"

}
