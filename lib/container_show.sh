#!/bin/bash

container_show() {

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local target=$1 target_family new_family

  [[ ${#target} -gt 1 ]] && {
    multi_show "$target"
    return
  }

  if [[ ${i3list[LVI]} =~ $target ]]; then
    return
  elif [[ ${i3list[LEX]} =~ $target ]]; then
    messy "[con_mark=i34${target}]" \
      move to workspace "${i3list[WSF]}", \
      floating disable
  else
    container_create "$target"
  fi

  [[ ${ori[fam1]} =~ $target ]] \
    && target_family=${ori[fam1]} \
    || target_family=${ori[fam2]}

  [[ ${i3list[X$target_family]} ]] || new_family=1
  family_show "$target_family" "$target"

  i3list[LHI]=${i3list[LHI]/$target/}
  i3list[LVI]+=$target

  ((new_family)) || {
    messy "[con_mark=i34$target]" \
      move to mark "i34X$target_family"

    [[ $target = "${target_family:0:1}" ]] && {
      messy "[con_mark=i34$target]" \
        swap mark "i34${target_family:1:1}"
    }

    tspl=${i3list[M${target_family}]}
    tdim=${ori[sizefam]}

    ((tspl  )) && {
      i3list[S${target_family}]=$((tdim/2))
      apply_splits "${target_family}=$tspl"
    }
  }
}
