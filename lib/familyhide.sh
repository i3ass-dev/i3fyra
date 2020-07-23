#!/bin/bash

familyhide(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg famchk tfam=$1

  declare -i target i

  for ((i=0;i<${#tfam};i++)); do

    trg=${tfam:$i:1}
    target=${_m[$trg]}

    if ((target & _visible)); then
      # messy "[con_mark=i34${trg}]" move scratchpad

      ((_visible &= ~target))
      ((_hidden  |= target))

      famchk+=${trg}
    fi
  done

  messy "[con_mark=i34X${tfam}]" move scratchpad

  _v+=("i34F${tfam}" "${famchk}")
  _v+=("i34MAB" "${i3list[SAB]}")
  _v+=("i34M${tfam}" "${i3list[S${tfam}]}")

}
