#!/bin/bash

familyhide(){

  ERM "familyhide"
  ERM "=========="

  local tfam=$1
  local trg famchk i

  for (( i = 0; i < 2; i++ )); do
    trg=${tfam:$i:1}
    if [[ ${trg} =~ [${i3list[LVI]}] ]]; then
      messy "[con_mark=i34${trg}]" focus, floating enable, \
        move absolute position 0 px 0 px, \
        resize set \
        "$((i3list[WFW]/2))" px \
        "$((i3list[WFH]/2))" px, \
        move scratchpad

      i3list[LHI]+=$trg
      i3list[LVI]=${i3list[LVI]/$trg/}

      famchk+=${trg}
    fi
  done

  i3var set "i34F${tfam}" "${famchk}"
  i3var set "i34MAB" "${i3list[SAB]}"
  i3var set "i34M${tfam}" "${i3list[S${tfam}]}"

}
