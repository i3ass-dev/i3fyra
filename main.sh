#!/usr/bin/env bash

main(){

  __o[verbose]=1

  ((__o[verbose])) && {
    declare -gi _stamp
    _stamp=$(date +%s%N)
    ERM $'\n'"---i3fyra start---"
  }

  trap 'cleanup' EXIT

  declare -gA _v         # "i3var"s to set
  declare -gA _r         # resize commands
  declare -g  _msgstring # combined i3-msg

  declare -gi _visible _hidden
  declare -gi _famact # ?

  # evaluate the output of i3list or --array
  declare -g  _array
  declare -gA i3list

  [[ -z ${_array:=${__o[array]}} ]] && _array=$(i3list)

  eval "$_array"

  : "${i3list[WSF]:=${I3FYRA_WS:-${i3list[WSA]}}}"

  # ori - common values dependent on I3FYRA_ORIENTATION
  declare -gA ori 
  orientationinit

  # create bitmasks
  declare -gA _m  # bitwise masks (_m[A]=1)
  declare -ga _n  # bitwise names (_n[1]=A)
  bitwiseinit

  local target
  
  # rename mainsplit to "main" in layout otherwise
  # it gets messed up when transforming the container names
  # applysplits() accepts both main=SIZE, AB=SIZE, and AC=SIZE
  [[ -n ${__o[layout]} ]] && __o[layout]=${__o[layout]//${ori[main]}/main}
  target=${__o[show]:-${__o[hide]:-${__o[layout]:-${__o[move]}}}}

  # if target is A|B|C|D, "transform" to virtual position
  ((__o[force])) || {
    declare -i vpos
    q=(A B C D)
    for k in "${!q[@]}"; do
      vpos=${i3list[VP${q[$k]}]:=$k}
      (( k != vpos )) && [[ $target =~ ${q[k]} ]] \
        && target=${target//${q[$k]}/@@$vpos}
    done

    [[ $target =~ @@ ]] && for k in "${!q[@]}"; do
      target=${target//@@$k/${q[$k]}}
    done
  }
  
  

  if [[ -n ${__o[show]} ]]; then
    containershow "$target"

  elif [[ -n ${__o[hide]} ]]; then
    containerhide "$target"

  elif [[ -n ${__o[layout]} ]]; then
    applysplits "$target"

  elif ((__o[float])); then
    togglefloat
    messy "[con_id=${i3list[AWC]}]" focus

  elif [[ -n ${__o[move]} ]]; then
    windowmove "$target"
    [[ -z ${i3list[SIBFOC]} ]] \
      && messy "[con_id=${i3list[AWC]}]" focus

  else
    ERH "no valid options $*"

  fi

  # [[ -n ${i3list[SIBFOC]} ]] \
  #   && messy "[con_mark=i34${i3list[SIBFOC]}]" focus child

}

___source="$(readlink -f "${BASH_SOURCE[0]}")"  #bashbud
___dir="${___source%/*}"                        #bashbud
source "$___dir/init.sh"                        #bashbud
main "$@"                                       #bashbud
