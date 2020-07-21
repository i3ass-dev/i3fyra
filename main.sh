#!/usr/bin/env bash

main(){
  
  local cmd target

  declare -A _m # bitwise masks _m[A]=1
  declare -a _n # bitwise names _n[1]=A

  declare -i _existing
  declare -i _visible
  declare -i _isvertical=0

  declare -i _famact # ?

  ERM fyra start $'\n'

  [[ ${I3FYRA_ORIENTATION,,} = vertical ]] \
    && _isvertical=1

  if [[ -n ${__o[show]} ]]; then
    cmd=containershow
    target="${__o[show]}"
  elif [[ -n ${__o[hide]} ]]; then
    cmd=containerhide
    target="${__o[hide]}"
  elif [[ -n ${__o[layout]} ]]; then
    cmd=applysplits
    target="${__o[layout]}"
  elif ((__o[float])); then
    cmd=togglefloat
  elif [[ -n ${__o[move]} ]]; then
    cmd=windowmove
    target="${__o[move]}"
  fi

  declare -A i3list # globals array

  # lopt = i3list options
  mapfile -td $'\n\s' lopt <<< "${__o[target]:-}"
  eval "${__o[array]:-$(i3list "${lopt[@]}")}"
  unset 'lopt[@]'

  bitwiseinit

  ((__o[test])) && {
    echo $_isvertical
    ERM "v: $_visible"
    ERM "e: $_existing"
    exit
  }

  [[ -z ${i3list[WSF]} ]] \
    && i3list[WSF]=${I3FYRA_WS:-${i3list[WSA]}}

  ${cmd} "${target}" # run command

  {
    [[ $cmd = windowmove ]] && [[ -z ${i3list[SIBFOC]} ]] \
        && i3-msg -q "[con_id=${i3list[AWC]}]" focus

    [[ $cmd = togglefloat ]] \
        && i3-msg -q "[con_id=${i3list[AWC]}]" focus

    [[ -n ${i3list[SIBFOC]} ]] \
      && i3-msg -q "[con_mark=i34${i3list[SIBFOC]}]" focus child
  }

  ERM  $'\n'"fyra done ${_n[1]}"$'\n'
  
}

___source="$(readlink -f "${BASH_SOURCE[0]}")"  #bashbud
___dir="${___source%/*}"                        #bashbud
source "$___dir/init.sh"                        #bashbud
main "$@"                                       #bashbud
