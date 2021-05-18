#!/bin/bash

initfyra() {

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}()"

  declare -i wsid
  local split

  # if we aren't on i3fyra workspace, go there
  # and do a new i3list to get the workspace id
  ((!__o[dryrun] && i3list[WSA] != i3list[WSF])) && {
    i3-msg -q workspace "${i3list[WSF]}"
    eval "$(i3list)"
    i3list[WFH]=${i3list[WAH]}
    i3list[WFW]=${i3list[WAW]}
  }

  wsid=${i3list[WAI]}
  messy "[con_id=$wsid]"           \
    mark "i34X${ori[main]}",       \
    split "${ori[charmain]}",      \
    layout "split${ori[charmain]}"

  for split in ${ori[fam1]} ${ori[fam2]} ${ori[main]}; do
    [[ -n ${i3list[M${split}]} ]] && continue
    [[ $split = "${ori[main]}" ]] \
      && size=${ori[sizemainhalf]} \
      || size=${ori[sizefamhalf]}
    i3list[M${split}]=$size
    _v["i34M$split"]=$size
  done

  _v["i34F${ori[fam1]}"]=X
  _v["i34F${ori[fam2]}"]=X
}
