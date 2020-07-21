#!/bin/bash

dummywindow() {

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}()"

  declare -gi _dummy
  local tmp

  tmp="$(i3-msg open)"
  _dummy="${tmp//[^0-9]/}"

  messy "[con_id=$_dummy]" \
    floating disable, mark "$_dummy"
}
