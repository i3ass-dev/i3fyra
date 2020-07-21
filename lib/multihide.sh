#!/bin/bash

multihide(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg real i

  trg="$1"

  for (( i = 0; i < ${#trg}; i++ )); do
    [[ ${trg:$i:1} =~ [${i3list[LVI]}] ]] && real+=${trg:$i:1}
  done

  [[ -z $real ]] && return
  [[ ${#real} -eq 1 ]] && containerhide "$real" && return
  
  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    [[ "A" =~ [$real] ]] && [[ "B" =~ [$real] ]] \
      && real=${real/A/} real=${real/B/} && familyhide AB
    [[ "C" =~ [$real] ]] && [[ "D" =~ [$real] ]] \
      && real=${real/C/} real=${real/D/} && familyhide CD
  else
    [[ "A" =~ [$real] ]] && [[ "C" =~ [$real] ]] \
      && real=${real/A/} real=${real/C/} && familyhide AC
    [[ "B" =~ [$real] ]] && [[ "D" =~ [$real] ]] \
      && real=${real/B/} real=${real/D/} && familyhide BD
  fi

  for (( i = 0; i < ${#real}; i++ )); do
    containerhide "${real:$i:1}"
  done
}
