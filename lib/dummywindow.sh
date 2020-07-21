#!/bin/bash

dummywindow() {

  local tmp

  tmp="$(i3-msg open)"
  _dummy="${tmp//[^0-9]/}"

  i3-msg -q "[con_id=$_dummy]" floating disable
}
