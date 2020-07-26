#!/bin/env bash

applysplits(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local i tsn dir trg tfam
  declare -i tsv resizedo size target sibling

  for i in ${1}; do
    tsn=${i%=*} # target name of split
    tsv=${i#*=} # target value of split

    if [[ $tsn = "${ori[main]}" ]]; then
      trg="X${ori[fam1]}" 
      dir=${ori[resizemain]} size=${ori[sizemain]}
      resizedo=$((i3list[$trg] == i3list[WSF]))
    else
      trg=${tsn:0:1}
      dir=${ori[resizefam]} size=${ori[sizefam]}

      target=${_m[$trg]}
      [[ ${tfam:=${ori[fam1]}} =~ $trg ]] || tfam=${ori[fam2]}
      sibling=$((_m[$tfam] & ~target))
      resizedo=$((target & _visible && sibling & _visible))
    fi

    ((tsv<0)) && tsv=$((size-(tsv*-1)))

    # i3list[XAC | XAB] has value of the workspace they are at
    ((resizedo)) && {
      # i3list[Sxx] = current/actual split xx
      i3list[S${tsn}]=${tsv}
      messy "[con_mark=i34$trg]" resize set "$dir" "$tsv" px
    }

    # i3list[Mxx] = last/stored    split xx
    # store split even if its not visible
    _v["i34M${tsn}"]=$tsv

  done
}
