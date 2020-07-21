#!/bin/bash

cleanup() {

  ((_dummy)) \
    && messy "[con_id=$_dummy]" kill

  ((${#_v[@]})) && varset "${_v[@]}"

  ((${#_msg[@]})) && {
    if ((__o[verbose])); then
      ERM "MSG ${_msg[*]}"
      i3-msg "${_msg[@]}"
    else
      i3-msg -q "${_msg[@]}"
    fi
  }

  ((__o[verbose])) && {
    _=${_n[1]}
    _=$_isvertical
    local delta=$(( ($(date +%s%N)-_stamp) /1000 ))
    local time=$(((delta / 1000) % 1000))
    ERM  $'\n'"${time}ms"
    ERM "dummy id: $_dummy"
    ERM "----------------------------"
  }
}
