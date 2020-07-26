#!/bin/env bash

applysplits(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local i tsn dir trg
  declare -i tsv

  for i in ${1}; do
    tsn=${i%=*} # target name of split
    tsv=${i#*=} # target value of split

    [[ $tsn = "${ori[main]}" ]] \
      && trg="X${ori[fam1]}" dir=${ori[resizemain]} \
      || trg=${tsn:0:1}      dir=${ori[resizefam]}

    ((tsv<0)) && tsv=$((ori[sizemain]-(tsv*-1)))

    # i3list[XAC | XAB] has value of the workspace they are at
    ((i3list[$trg] == i3list[WSF] || _m[$trg] & _visible)) && {
      # i3list[Sxx] = current/actual split xx
      i3list[S${tsn}]=${tsv}
      messy "[con_mark=i34$trg]" resize set "$dir" "$tsv" px
    }

    # i3list[Mxx] = last/stored    split xx
    # store split even if its not visible
    _v["i34M${tsn}"]=$tsv

  done
}
