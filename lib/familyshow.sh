#!/bin/env bash

familyshow(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"

  local fam=$1 trg
  local tfammem="${i3list[F${fam}]}"
  # i3list[Fxx] - family memory

  declare -i i target

  _famact=1
  for ((i=0;i<${#tfammem};i++)); do
    trg=${tfammem:$i:1}
    target=${_m[$trg]}
    ((target & _hidden)) && containershow "$trg"
  done

  if ((_isvertical)); then
    i3list[SAC]=$((i3list[WFH]/2))
    applysplits "AC=${i3list[MAC]}"
  else
    i3list[SAB]=$((i3list[WFW]/2))
    applysplits "AB=${i3list[MAB]}"
  fi
}
