#!/bin/bash

initialize_globals() {

  __o[verbose]=1
  # __o[dryrun]=1

  ((__o[verbose])) && {
    declare -gi _stamp
    _stamp=$(date +%s%N)
    ERM $'\n'"---i3fyra start---"
  }

  trap 'cleanup' EXIT

  declare -Ag i3list
  declare -Ag mark_vars
  declare -Ag new_size
  declare -Ag ori

  _marks_json=$(i3-msg -t get_marks)

  [[ $_action != layout && ! $_marks_json =~ i3fyra_ws ]] && {
    # the i3fyra_ws mark/var is read by i3list
    # if it isn't present no info regarding i3fyra
    # will be in the output of i3list
    # we set the mark/var here

    ((__o[verbose])) && ERM INIT FYRA_WS
    i3var set i3fyra_ws "${I3FYRA_WS:-$(i3get -r w)}"
    i3var set i34ORI "$I3FYRA_ORIENTATION"
  }

  # _qflag is option added to i3-msg (cleanup())
  ((__o[verbose])) || _qflag='-q'

  eval "${_array:=${__o[array]:-$(i3list)}}"

  declare -gi _isvertical

  declare -i sw=${i3list[WFW]:-${i3list[WAW]}}
  declare -i sh=${i3list[WFH]:-${i3list[WAH]}}
  declare -i swh=$((sw/2))
  declare -i shh=$((sh/2))

  if [[ ${i3list[ori]} = vertical ]]; then
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
