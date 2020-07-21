#!/bin/env bash

familyshow(){

  ERM "familyshow"
  ERM "=========="

  local fam=$1
  # [F${fam}] - existing members of family
  local familymemories="${i3list[F${fam}]}"

  _famact=1
  for (( i = 0; i < ${#familymemories}; i++ )); do
    member=${familymemories:$i:1}
    [[ $member =~ [${i3list[LHI]}] ]] \
      && containershow "$member"
  done

  if ((_isvertical)); then
    i3list[SAC]=$((i3list[WFH]/2))
    applysplits "AC=${i3list[MAC]}"
  else
    i3list[SAB]=$((i3list[WFW]/2))
    applysplits "AB=${i3list[MAB]}"
  fi
}
