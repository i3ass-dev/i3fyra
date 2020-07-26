#!/usr/bin/env bash

main(){

  __o[verbose]=1

  ((__o[verbose])) && {
    declare -gi _stamp
    _stamp=$(date +%s%N)
    ERM "---i3fyra start---"
  }

  trap 'cleanup' EXIT

  declare -gA _v         # "i3var"s to set
  declare -g  _msgstring # combined i3-msg
  declare -g  _sizstring # combined resize i3-msg

  declare -gi _visible _hidden
  declare -gi _famact # ?

  # evaluate the output of i3list or --array
  declare -g  _array
  declare -gA i3list

  [[ -z ${_array:=${__o[array]}} ]] && {
    mapfile -td $'\n\s' lopt <<< "${__o[target]:-}"
    _array=$(i3list "${lopt[@]}")
    unset 'lopt[@]'
  }

  eval "$_array"

  : "${i3list[WSF]:=${I3FYRA_WS:-${i3list[WSA]}}}"

  # ori - common values dependent on I3FYRA_ORIENTATION
  declare -gA ori 
  orientationinit

  # create bitmasks
  declare -gA _m  # bitwise masks (_m[A]=1)
  declare -ga _n  # bitwise names (_n[1]=A)
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
    ERH "no valid options $*"

  fi

  [[ -n ${i3list[SIBFOC]} ]] \
    && messy "[con_mark=i34${i3list[SIBFOC]}]" focus child

}

___source="$(readlink -f "${BASH_SOURCE[0]}")"  #bashbud
___dir="${___source%/*}"                        #bashbud
source "$___dir/init.sh"                        #bashbud
main "$@"                                       #bashbud
