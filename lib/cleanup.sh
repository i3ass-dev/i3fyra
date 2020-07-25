#!/bin/bash

cleanup() {

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}()"

  local qflag

  ((__o[verbose])) || qflag='-q'

  ((${#_v[@]})) && varset "${_v[@]}"

  [[ -n $_msgstring ]] && i3-msg "${qflag:-}" "$_msgstring"
  [[ -n $_sizstring ]] && i3-msg "${qflag:-}" "$_sizstring"

  ((__o[verbose])) && {
    _=${_n[1]}
    _=$_isvertical
    _=$_existing
    _=$famshow
    local delta=$(( ($(date +%s%N)-_stamp) /1000 ))
    local time=$(((delta / 1000) % 1000))
    ERM  $'\n'"${time}ms"
    ERM "----------------------------"
  }
}
