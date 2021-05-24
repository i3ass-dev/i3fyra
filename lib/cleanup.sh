#!/bin/bash

cleanup() {

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}()"

  ((${#mark_vars[@]})) && varset

  [[ -n $_msgstring ]] \
    && i3-msg "$_qflag" "${_msgstring%;}"

  ((${#new_size[@]})) && {
    for k in "${!new_size[@]}"; do 
      _sizestring+="[$k] ${new_size[$k]};"
    done
    i3-msg "${qflag:-}" "${_sizestring%;}"
  }

  # /home/bud/tmp/trees/maketrees.sh
  ((__o[verbose])) && {
    local delta=$(( ($(date +%s%N)-_stamp) /1000 ))
    local time=$(((delta / 1000) % 1000))
    ERM  "---i3fyra done: ${time}ms---"
  }
}
