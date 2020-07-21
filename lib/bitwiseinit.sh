#!/bin/bash

bitwiseinit() {
  
  _m[A]=$((1 << 0)) _m[B]=$((1 << 1))
  _m[C]=$((1 << 2)) _m[D]=$((1 << 3))

  _m[AB]=$((_m[A] | _m[B])) _m[AC]=$((_m[A] | _m[C]))
  _m[BD]=$((_m[B] | _m[D])) _m[CD]=$((_m[C] | _m[D]))

  _m[ABCD]=$((_m[AB]|_m[CD]))
  
  for k in "${!_m[@]}"; do _n[${_m[$k]}]=$k ; done

  # i3list[LEX]=DCBA # Existing containers (LVI+LHI)
  # i3list[LVI]=DCBA # Visible i3fyra containers

  for k in A B C D ; do
    [[ ${i3list[LEX]} =~ $k ]] \
      && _existing=$((_existing | _m[k]))
    [[ ${i3list[LVI]} =~ $k ]] \
      && _visible=$((_visible  | _m[k]))
  done
}
