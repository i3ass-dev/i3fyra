#!/bin/bash

dummywindow() {

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}()"

  local mark id
  
  mark=${1:?first argument not a mark name}

  ((__o[dryrun])) && id=777 || id="$(i3-msg open)"
  messy "[con_id=${id//[^0-9]/}]" floating disable, mark "$mark"
}
