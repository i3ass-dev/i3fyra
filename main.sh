#!/bin/bash

main(){

  local arg

  for _action in assign-to move show hide layout float; do
    [[ ${arg:=${__o[$_action]}} ]] && break
  done

  [[ $arg ]] || ERX "not a valid operation: $0 $*"

  initialize_globals

  ((__o[force])) || arg=$(virtual_position "$arg")

  case "$_action" in

    move )
      if [[ $arg =~ ^[ABCD]$ ]]; then
        active_move_to_container "$arg"
      elif [[ ${arg:0:1} =~ [urld] ]]; then
        active_move_in_direction "${arg:0:1}"
      else
        ERX "'$arg' is not a valid argument for --move"
      fi
    ;;

    show   ) container_show "$arg" ;;
    hide   ) container_hide "$arg" ;;
    layout ) apply_splits "$arg"   ;;
    float  ) float_toggle          ;;

  esac
}

___source="$(readlink -f "${BASH_SOURCE[0]}")"  #bashbud
___dir="${___source%/*}"                        #bashbud
source "$___dir/init.sh"                        #bashbud
main "${@}"                                     #bashbud
