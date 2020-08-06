#!/bin/bash

swapmeet(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"

  local m1=$1 m2=$2 tmrk k 
  local c1 c2 i1 i2 v1 v2

  declare -i tspl tdim i
  declare -A acn

  declare -a ivp
  declare -A iip

  iip=([A]=0 [B]=1 [C]=2 [D]=3)

  for k in "${!iip[@]}"; do
    ivp[${i3list[VP$k]}]=$k
  done

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

      c1=${k}        c2=${acn[$k]}
      i1=${iip[$c1]} i2=${iip[$c2]}
      v1=${ivp[$i1]} v2=${ivp[$i2]}

      _v[i34VP$v1]=$i2
      _v[i34VP$v2]=$i1

      ((_m[$k] & (_visible | _hidden) )) || continue
      messy "[con_mark=i34$k]" mark "i34tmp$k"
    done

    for k in A B C D; do
      ((_m[$k] & (_visible | _hidden) )) || continue
      messy "[con_mark=i34tmp$k]" mark "i34${acn[$k]}"
    done

    
  else # swap within family

    c1=${m1#i34}   c2=${m2#i34}
    i1=${iip[$c1]} i2=${iip[$c2]}
    v1=${ivp[$i1]} v2=${ivp[$i2]}

    _v[i34VP$v1]=$i2
    _v[i34VP$v2]=$i1

    # dont use AFF ?
    tmrk="${i3list[AFF]}"
    tspl="${i3list[S${tmrk}]}"
    tdim=${ori[sizefam]}

  fi

  # invert split
  ((tspl+tdim)) && applysplits "$tmrk=$((tdim-tspl))"

  messy "[con_id=${i3list[TWC]}]" focus
}
