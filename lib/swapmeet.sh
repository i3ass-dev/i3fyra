#!/bin/bash

swapmeet(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  # ivp - "inverted" vertical positions
  declare -A ivp
  for k in A B C D; do
    ivp[${i3list[VP$k]:=$k}]=$k
  done

  local m1=$1 m2=$2 tmrk k c1 c2 vpk1 vpk2
  
  declare -i tspl tdim i
  declare -A acn

  messy "[con_mark=${m1}]"  swap mark "${m2}", mark i34tmp
  messy "[con_mark=${m2}]"  mark "${m1}"
  messy "[con_mark=i34tmp]" mark "${m2}"
  
  # acn[oldname]=newname
  declare -A acn

  # swap families, rename all containers
  if [[ $m1 =~ X ]]; then

    ((_isvertical)) \
      && acn=([A]=C [B]=D [C]=A [D]=B) \
      || acn=([A]=B [B]=A [C]=D [D]=C)

    tdim=${ori[sizemain]}
    tmrk=${ori[main]}
    tspl=${i3list[S$tmrk]}

    _v[i34M${ori[fam1]}]=${i3list[M${ori[fam2]}]}
    _v[i34M${ori[fam2]}]=${i3list[M${ori[fam1]}]}


    for k in A B C D; do

      vpk1=${i3list[VP$k]:-$k}
      vpk2=${i3list[VP${acn[$vpk1]}]:-${acn[$vpk1]}}

      _v[i34VP$vpk2]=${ivp[$k]}

      ((_m[$k] & (_visible | _hidden) )) || continue
      messy "[con_mark=i34$k]" mark "i34tmp$k"
    done

    for k in A B C D; do
      ((_m[$k] & (_visible | _hidden) )) || continue
      messy "[con_mark=i34tmp$k]" mark "i34${acn[$k]}"
    done

    
  else # swap within family

    c1=${m1#i34} c2=${m2#i34}

    ((_isvertical)) \
      && acn=([A]=B [B]=A [C]=D [D]=C) \
      || acn=([A]=C [B]=D [C]=A [D]=B)

    for k in "$c1" "$c2"; do
      vpk1=${i3list[VP$k]:-$k}
      vpk2=${i3list[VP${acn[$vpk1]}]:-${acn[$vpk1]}}

      _v[i34VP${ivp[$k]}]=$vpk2
    done

    # dont use AFF ?
    tmrk="${i3list[AFF]}"
    tspl="${i3list[S${tmrk}]}"
    tdim=${ori[sizefam]}

  fi

  # invert split
  ((tspl+tdim)) && applysplits "$tmrk=$((tdim-tspl))"

  messy "[con_id=${i3list[TWC]}]" focus
}
