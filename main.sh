#!/usr/bin/env bash

main(){

  __o[verbose]=1

  trap 'cleanup' EXIT

  declare -gA _m         # bitwise masks _m[A]=1
  declare -gA i3list     # globals array
  declare -ga _n         # bitwise names _n[1]=A
  declare -ga _v         # "i3var"s to set
  declare -g  _msgstring # combined i3-msg
  declare -g  _sizstring # combined resize i3-msg

  declare -gi _existing
  declare -gi _visible
  declare -gi _isvertical=0

  declare -gi _famact # ?

  declare -gi _stamp

  ((__o[verbose])) && {
    _stamp=$(date +%s%N)
    ERM " "
  }

  [[ ${I3FYRA_ORIENTATION,,} = vertical ]] \
    && _isvertical=1

  # evaluate the output of i3list or --array
  if [[ -n ${__o[array]} ]]; then
    eval "${__o[array]}"
  else
    mapfile -td $'\n\s' lopt <<< "${__o[target]:-}"
    eval "$(i3list "${lopt[@]}")"
    unset 'lopt[@]'
  fi

  ((i3list[WSF])) && i3list[WSF]=${I3FYRA_WS:-${i3list[WSA]}}

  bitwiseinit

  if [[ -n ${__o[show]} ]]; then
    containershow "${__o[show]}"

  elif [[ -n ${__o[hide]} ]]; then
    containerhide "${__o[hide]}"

  elif [[ -n ${__o[layout]} ]]; then
    applysplits "${__o[layout]}"

  elif ((__o[float])); then
    togglefloat
    messy "[con_id=${i3list[AWC]}]" focus

  elif [[ -n ${__o[move]} ]]; then
    windowmove "${__o[move]}"
    [[ -z ${i3list[SIBFOC]} ]] \
      && messy "[con_id=${i3list[AWC]}]" focus

  else
    ERH "no valid options"

  fi

  [[ -n ${i3list[SIBFOC]} ]] \
    && messy "[con_mark=i34${i3list[SIBFOC]}]" focus child

}

___source="$(readlink -f "${BASH_SOURCE[0]}")"  #bashbud
___dir="${___source%/*}"                        #bashbud
source "$___dir/init.sh"                        #bashbud
main "$@"                                       #bashbud
