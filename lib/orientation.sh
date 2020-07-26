#!/bin/bash

orientationinit() {

  declare -gi _isvertical

  declare -i sw=${i3list[WFW]:-${i3list[WAW]}}
  declare -i sh=${i3list[WFH]:-${i3list[WAH]}}
  declare -i swh=$((sw/2))
  declare -i shh=$((sh/2))

  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    _isvertical=1
    ori=(

      [main]=AC [fam1]=AB [fam2]=CD

      [charmain]=v        [charfam]=h
      [movemain]=down     [movefam]=right
      [resizemain]=height [resizefam]=width
      [sizemain]=$sh      [sizefam]=$sw 
      [sizemainhalf]=$shh [sizefamhalf]=$swh

    )
  else
    _isvertical=0
    ori=(

      [main]=AB [fam1]=AC [fam2]=BD

      [charmain]=h        [charfam]=v
      [movemain]=right    [movefam]=down
      [resizemain]=width  [resizefam]=height
      [sizemain]=$sw      [sizefam]=$sh
      [sizemainhalf]=$swh [sizefamhalf]=$shh

    )
  fi
}
