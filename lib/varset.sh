#!/bin/bash

varset() {

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local key val json re mark

  json=$(i3-msg -t get_marks)

  while [[ -n $1 ]]; do
    key=$1 val=$2
    shift 2
    re="\"(${key}=[^\"]+)\""
    [[ $json =~ $re ]] && mark="${BASH_REMATCH[1]}"

    if [[ -z $mark ]]; then
      i3gw "${key}=${val}"
      messy "[con_mark=${key}]" move scratchpad
    else
      messy "[con_mark=${key}]" mark "${key}=${val}"
    fi
  done
}
