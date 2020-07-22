#!/bin/bash

cleanup() {

  local qflag

  ((__o[verbose])) || qflag='-q'

  ((_dummy)) \
    && messy "[con_id=$_dummy]" kill

  ((${#_v[@]})) && varset "${_v[@]}"

  ((${#_msg[@]})) && ((!__o[dryrun])) \
    && i3-msg "${qflag:-}" "${_msg[@]}"

  ((__o[verbose])) && {
    _=${_n[1]}
    _=$_isvertical
    local delta=$(( ($(date +%s%N)-_stamp) /1000 ))
    local time=$(((delta / 1000) % 1000))
    ERM  $'\n'"${time}ms"
    ERM "----------------------------"
  }
}
