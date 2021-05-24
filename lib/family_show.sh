#!/bin/bash

family_show() {

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"

  local target_family=$1 target_container=${2:-}
  local other_family

  ((i3list["X${target_family}"] == i3list[WSF])) \
    && return

  if [[ -z ${i3list[X${target_family}]} ]]; then
    [[ $target_container ]] && {
      family_create "$target_family" "$target_container"
    }
  elif ((i3list["X${target_family}"] != i3list[WSF])); then

    messy "[con_mark=i34X${target_family}]" \
      move to workspace "${i3list[WSF]}", \
      floating disable

    if [[ ${i3list["X${ori[main]}"]} ]]; then

      messy "[con_mark=i34X${ori[main]}]"     \
        split h
      messy "[con_mark=i34X${target_family}]" \
        move to mark "i34X${ori[main]}"

    else
      messy "[con_mark=i34X${target_family}]" \
        layout splith, \
        focus, focus parent
      messy mark "i34X${ori[main]}"
    fi
  fi

  # when target family is AC or AB, it is 
  # the "first" family in the main container
  # if the other family is visible, 
  # we need to swap them
  [[ $target_family =~ A ]] && {

    [[ ${ori[fam1]} =~ A ]] \
      && other_family=${ori[fam2]} \
      || other_family=${ori[fam1]}

    ((i3list["X${other_family}"] == i3list[WSF])) \
      && messy "[con_mark=i34X${target_family}]"  \
           swap mark "i34X${other_family}"
  }

  apply_splits "${ori[main]}=${i3list[M${ori[main]}]}"
}
