#!/bin/bash

initfyra() {

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}()"

  declare -i wsid i
  declare -a splitsizes
  declare -i halfwidth=$((i3list[WAW]/2)) 
  declare -i halfheight=$((i3list[WAH]/2))

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
  messy "[con_id=$wsid]"          \
    mark "i34X${_splits[0]}",     \
    split "${_splitdir[0]}",      \
    layout "split${_splitdir[0]}"

  # setup default layout size marks if not already set
  ((_isvertical)) \
    && splitsizes=([0]=$halfheight [1]=$halfwidth) \
    || splitsizes=([0]=$halfwidth  [1]=$halfheight)
    
  splitsizes[2]=${splitsizes[1]}

  for i in "${!_splits[@]}"; do
    split=${_splits[$i]}
    [[ -n ${i3list[M$split]} ]] && continue

    i3list[M$split]=${splitsizes[$i]}
    _v+=("i34M$split" "${splitsizes[$i]}")
  done

  # create persistent ghost container
  i3-msg -q "[con_mark=i34GHOST]" kill
  dummywindow "i34GHOST"
  messy "[con_mark=i34GHOST]" move scratchpad

}
