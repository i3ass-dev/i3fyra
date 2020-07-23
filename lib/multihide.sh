#!/bin/bash

multihide(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg arg targets i

  arg="$1"

  # only hide visible containers in arg
  for (( i = 0; i < ${#arg}; i++ )); do
    trg=${arg:$i:1}
    ((_m[$trg] & _visible)) && targets+=$trg
  done

  ((${#targets} == 0)) && return
  
  # hide whole families if present in arg and visible
  if ((_isvertical)); then
    [[ $targets =~ A && $targets =~ B ]] \
      && targets=${targets//[AB]/} && familyhide AB
    [[ $targets =~ C && $targets =~ D ]] \
      && targets=${targets//[CD]/} && familyhide CD
  else
    [[ $targets =~ A && $targets =~ C ]] \
      && targets=${targets//[AC]/} && familyhide AC
    [[ $targets =~ B && $targets =~ D ]] \
      && targets=${targets//[BD]/} && familyhide BD
  fi

  # hide rest if any
  ((${#targets})) && for ((i=0;i<${#targets};i++)); do
    containerhide "${targets:$i:1}"
  done
}
