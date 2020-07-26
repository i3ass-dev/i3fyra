#!/bin/bash

swapmeet(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local m1=$1 m2=$2 tmrk old
  declare -i tspl tdim i
  declare -A acn

  messy "[con_mark=${m1}]"  swap mark "${m2}", mark i34tmp
  messy "[con_mark=${m2}]"  mark "${m1}"
  messy "[con_mark=i34tmp]" mark "${m2}"
  
  # acn[oldname]=newname
  declare -A acn

  # swap families
  if [[ $m1 =~ X ]]; then

    ((_isvertical)) \
      && acn=([A]=C [B]=D [C]=A [D]=B) \
      || acn=([A]=B [B]=A [C]=D [D]=C)

    tdim=${ori[sizemain]}
    tmrk=${ori[main]}
    tspl=${i3list[S$tmrk]}

    _v[i34M${ori[fam1]}]=${i3list[M${ori[fam2]}]}
    _v[i34M${ori[fam2]}]=${i3list[M${ori[fam1]}]}

  else # swap within family

    ((_isvertical)) \
      && acn=([A]=B [B]=A [C]=D [D]=C) \
      || acn=([A]=C [B]=D [C]=A [D]=B)

    # dont use AFF ?
    tmrk="${i3list[AFF]}"
    tspl="${i3list[S${tmrk}]}"
    tdim=${ori[sizefam]}

  fi

  for ((i=0;i< ${#i3list[LEX]};i++)); do
    old=${i3list[LEX]:$i:1}
    messy "[con_mark=i34${old}]" mark "i34tmp${old}"
  done

  for ((i=0;i< ${#i3list[LEX]};i++)); do
    old=${i3list[LEX]:$i:1}
    messy "[con_mark=i34tmp${old}]" mark "i34${acn[$old]}"
  done

  # invert split
  [[ $m1 =~ X ]] && ((tspl+tdim)) && applysplits "$tmrk=$((tdim-tspl))"
  messy "[con_id=${i3list[TWC]}]" focus
}
