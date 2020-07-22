#!/bin/bash

dummywindow() {

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}()"

  local mark id
  
  mark=${1:?first argument not a mark name}

  if ((__o[dryrun])); then
    id=777
  else
    id="$(i3-msg open)"
    id="${id//[^0-9]/}"
  fi

  messy "[con_id=$id]" floating disable, mark "$mark"
}
