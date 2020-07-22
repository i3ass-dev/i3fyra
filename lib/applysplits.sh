#!/bin/env bash

applysplits(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local i tsn dir mrk
  declare -i tsv par parw parh

  # i3list[WF-W/H] - i3fyra workspace W/H
  # i3list[WA-W/H] - active workspace W/H
  parw=${i3list[WFW]:-"${i3list[WAW]}"}
  parh=${i3list[WFH]:-"${i3list[WAH]}"}

  for i in ${1}; do
    tsn=${i%=*} # target name of split
    tsv=${i#*=} # target value of split

    if ((_isvertical)); then
      [[ $tsn = AC ]] \
        && par=$parh dir=height mrk=i34XAB \
        || par=$parw dir=width  mrk=i34${tsn:0:1}
    else
      [[ $tsn = AB ]] \
        && par=$parw dir=width  mrk=i34XAC \
        || par=$parh dir=height mrk=i34${tsn:0:1}
    fi

    ((tsv<0)) && tsv=$((par-(tsv*-1)))

    messy "[con_mark=${mrk}]" resize set "$dir" "$tsv" px

    # i3list[Sxx] = current/actual split xx
    # i3list[Mxx] = last/stored    split xx
    i3list[S${tsn}]=${tsv}
    _v+=("i34M${tsn}" "${tsv}")

  done
}
