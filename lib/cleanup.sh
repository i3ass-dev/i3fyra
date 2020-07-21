#!/bin/bash

cleanup() {
  ((_dummy)) \
    && i3-msg -q "[con_id=$_dummy]" kill

  ((__o[verbose])) && {
    _=${_n[1]}
    local delta=$(( ($(date +%s%N)-_stamp) /1000 ))
    local time=$(((delta / 1000) % 1000))
    ERM  $'\n'"${time}ms"
    ERM "----------------------------"
  }
}
