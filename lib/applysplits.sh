#!/bin/env bash

applysplits(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local i tsn dir trg tfam
  declare -i tsv splitexist size target sibling

  for i in ${1}; do
    tsn=${i%=*} # target name of split
    tsv=${i#*=} # target value of split

    if [[ $tsn = "${ori[main]}" || $tsn = main ]]; then
      tsn=${ori[main]}
      trg="X${ori[fam1]}" 
      dir=${ori[resizemain]} size=${ori[sizemain]}

      # when --layout option is used, invert split
      # if families are inverted
      # container A vertical position (VPA)
      # inverse mainsplit (2|3 || 1|3)
      [[ -n ${__o[layout]} ]] \
        && (( (_isvertical  && i3list[VPA] > 1)    \
           || (!_isvertical && i3list[VPA] % 2) )) \
        && ((tsv *= -1))

      splitexist=1
    else
      trg=${tsn:0:1}
      dir=${ori[resizefam]} size=${ori[sizefam]}

      target=${_m[$trg]}
      [[ ${tfam:=${ori[fam1]}} =~ $trg ]] || tfam=${ori[fam2]}
      sibling=$((_m[$tfam] & ~target))
      splitexist=$((target & _visible && sibling & _visible))
    fi

    ((tsv<0)) && tsv=$((size-(tsv*-1)))

    # i3list[XAC | XAB] has value of the workspace they are at
    ((splitexist)) && {
      # i3list[Sxx] = current/actual split xx
      i3list[S${tsn}]=${tsv}
      sezzy "con_mark=i34$trg" resize set "$dir" "$tsv" px
    }

    # i3list[Mxx] = last/stored    split xx
    # store split even if its not visible
    _v["i34M${tsn}"]=$tsv

  done
}
