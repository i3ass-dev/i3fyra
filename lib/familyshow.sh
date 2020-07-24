#!/bin/bash

familyshow(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"

  local arg=$1 ourfam trg theirfam

  [[ ${ourfam:=${_splits[1]}} =~ ${arg:0:1} ]] \
    || ourfam=${_splits[2]}

  declare -i i target newfamily
  declare -i ourfamily theirfamily firstfam

  ourfamily=${_m[$ourfam]}

  # if our family is not in hiding it doesn't exist
  # arg should always be a single from containershow().
  ((ourfamily & _hidden)) || {
    familycreate "${arg:0:1}"
    newfamily=1
  }

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

  ((newfamily)) || messy "[con_mark=i34X${ourfam}]"    \
                   move to workspace "${i3list[WSF]}", \
                   floating disable,                   \
                   move to mark "i34X${_splits[0]}"

  # if $ourfam is the first and the otherfamily
  # is visible swap'em
  firstfam=${_m[${_splits[1]}]}
  ((ourfamily == firstfam && theirfamily & _visible)) \
    && messy "[con_mark=i34X${ourfam}]" \
       swap container with mark "i34X${theirfam}"

  applysplits "$splits"

}
