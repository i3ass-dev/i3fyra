#!/bin/bash

bitwiseinit() {
  
  local k
  declare -i i

  for k in A B C D l r u d; do
    _m[$k]=$((3<<(2*i++) ))
  done

  _m[AB]=$((_m[A] | _m[B])) _m[AC]=$((_m[A] | _m[C]))
  _m[BD]=$((_m[B] | _m[D])) _m[CD]=$((_m[C] | _m[D]))

  _m[ABCD]=$((_m[AB]|_m[CD]))
  
  for k in "${!_m[@]}"; do _n[${_m[$k]}]=$k ; done

  # i3list[LEX]=DCBA # Existing containers (LVI+LHI)
  # i3list[LVI]=DCBA # Visible i3fyra containers

  for k in A B C D ; do
    [[ ${i3list[LHI]} =~ $k ]] && ((_hidden |= _m[$k]))
    [[ ${i3list[LVI]} =~ $k ]] && ((_visible|= _m[$k]))
  done
}
