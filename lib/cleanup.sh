#!/bin/bash

cleanup() {

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}()"

  local qflag k s

  ((__o[verbose])) || qflag='-q'

  ((${#_v[@]})) && varset

  [[ -n $_msgstring ]] && i3-msg "${qflag:-}" "$_msgstring"
  
  ((${#_r[@]})) && {
    for k in "${!_r[@]}"; do s+="[$k] ${_r[$k]};" ; done
    i3-msg "${qflag:-}" "$s"
  }

  ((__o[verbose])) && {
    local delta=$(( ($(date +%s%N)-_stamp) /1000 ))
    local time=$(((delta / 1000) % 1000))
    ERM  "---i3fyra done: ${time}ms---"
  }
}
