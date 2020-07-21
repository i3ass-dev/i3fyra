#!/bin/env bash

familyshow(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"

  local fam=$1
  local tfammem="${i3list[F${fam}]}"
  # F${fam} - family memory

  _famact=1
  for (( i = 0; i < ${#tfammem}; i++ )); do
    [[ ${tfammem:$i:1} =~ [${i3list[LHI]}] ]] \
      && containershow "${tfammem:$i:1}"
  done

  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    i3list[SAC]=$((i3list[WFH]/2))
    applysplits "AC=${i3list[MAC]}"
  else
    i3list[SAB]=$((i3list[WFW]/2))
    applysplits "AB=${i3list[MAB]}"
  fi
}
