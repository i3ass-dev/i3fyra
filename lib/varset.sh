#!/bin/bash

varset() {

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}(${_v[*]})"

  local key val json re mark current_value

  json=$(i3-msg -t get_marks)

  for key in "${!_v[@]}"; do
    val=${_v[$key]}

    re="\"${key}=([^\"]*)\""

    [[ $json =~ $re ]] && current_value=${BASH_REMATCH[1]}

    new_mark="${key}=$val"
    old_mark="${key}=$current_value"

    # this will remove the old mark
    [[ $current_value ]] \
      && messy "[con_id=${i3list[RID]}] mark --toggle --add $old_mark"

    messy "[con_id=${i3list[RID]}] mark --add $new_mark"

    # re="\"(${key}=[^\"]+)\""
    # [[ $json =~ $re ]] && mark="${BASH_REMATCH[1]}"

    # if [[ -z $mark ]]; then
    #   dummywindow "${key}=${val}"
    #   messy "[con_mark=${key}]" move scratchpad
    # else
    #   messy "[con_mark=${key}]" mark "${key}=${val}"
    # fi
    # unset mark
  done
}
