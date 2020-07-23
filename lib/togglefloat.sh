#!/bin/env bash

togglefloat(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}()"
  
  

  # AWF - 1 = floating; 0 = tiled
  if ((i3list[AWF]==1)); then

    # WSA != i3fyra && normal tiling
    if ((i3list[WSA]!=i3list[WSF])); then
      messy "[con_id=${i3list[AWC]}]" floating disable
      return
    fi

    local trg

    declare -i main
    main=${_m[$I3FYRA_MAIN_CONTAINER]}

    if ((main & _visible)); then
      trg=$I3FYRA_MAIN_CONTAINER
    elif ((_visible)); then
      trg=${i3list[LVI]:0:1}
    elif ((_hidden)); then
      trg=${i3list[LHI]:0:1}
    else
      trg=$I3FYRA_MAIN_CONTAINER
    fi

    if (( _m[$trg] & (_visible | _hidden) )); then
      containershow "$trg"
      messy "[con_id=${i3list[AWC]}]" floating disable, \
        move to mark "i34${trg}"
    else
      # if $trg container doesn't exist, create it
      containershow "$trg"
    fi
  else
    # AWF == 0 && make AWC floating
    messy "[con_id=${i3list[AWC]}]" floating enable
  fi
}
