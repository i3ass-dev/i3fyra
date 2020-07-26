#!/bin/bash

varset() {

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}(${_v[*]})"

  local key val json re mark

  json=$(i3-msg -t get_marks)

  for key in "${!_v[@]}"; do
    val=${_v[$key]}
    re="\"(${key}=[^\"]+)\""
    [[ $json =~ $re ]] && mark="${BASH_REMATCH[1]}"

    if [[ -z $mark ]]; then
      dummywindow "${key}=${val}"
      messy "[con_mark=${key}]" move scratchpad
    else
      messy "[con_mark=${key}]" mark "${key}=${val}"
    fi
    unset mark
  done
}
