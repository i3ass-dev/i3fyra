#!/bin/bash

swapmeet(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local m1=$1 m2=$2 tmrk old
  declare -i tspl tdim i
  declare -A acn

  messy "[con_mark=${m1}]"  swap mark "${m2}", mark i34tmp
  messy "[con_mark=${m2}]"  mark "${m1}"
  messy "[con_mark=i34tmp]" mark "${m2}"


  # family swap, rename all existing containers with their twins
  if [[ $m1 =~ X ]]; then
    # acn[oldname]=newname
    if ((_isvertical)); then
      tspl="${i3list[SAC]}" tdim="${i3list[WFH]}"
      tmrk=AC
      acn=([A]=C [B]=D [C]=A [D]=B)
      _v+=(i3MAB "${i3list[MCD]}")
      _v+=(i3MCD "${i3list[MAB]}")
    else
      tspl="${i3list[SAB]}" tdim="${i3list[WFW]}"
      tmrk=AB
      acn=([A]=B [B]=A [C]=D [D]=C)
      _v+=(i3MAC "${i3list[MBD]}")
      _v+=(i3MBD "${i3list[MAC]}")
    fi

  else # swap within family, rename siblings
    tmrk="${i3list[AFF]}"
    tspl="${i3list[S${tmrk}]}"

    if ((_isvertical)); then
      acn=([A]=B [B]=A [C]=D [D]=C)
      tdim="${i3list[WFW]}"
    else
      acn=([A]=C [B]=D [C]=A [D]=B)
      tdim="${i3list[WFH]}"
    fi
  fi

  for ((i =0;i< ${#i3list[LEX]};i++)); do
    old=${i3list[LEX]:$i:1}
    messy "[con_mark=i34${old}]" mark "i34tmp${old}"
  done

  for ((i =0;i< ${#i3list[LEX]};i++)); do
    old=${i3list[LEX]:$i:1}
    messy "[con_mark=i34tmp${old}]" mark "i34${acn[$old]}"
  done

  # invert split
  ((tspl+tdim)) && applysplits "$tmrk=$((tdim-tspl))"
  messy "[con_id=${i3list[TWC]}]" focus
}
