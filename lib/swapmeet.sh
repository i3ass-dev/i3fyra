#!/bin/bash

swapmeet(){
  local m1=$1
  local m2=$2
  local i k cur
  
  # array with containers (k=current name, v=twin name)
  declare -A acn 

  i3-msg -q "[con_mark=${m1}]"  swap mark "${m2}", mark i34tmp
  i3-msg -q "[con_mark=${m2}]"  mark "${m1}"
  i3-msg -q "[con_mark=i34tmp]" mark "${m2}"

  # if targets are families, remark all containers 
  # with their twins
  if [[ $m1 =~ X ]]; then
    if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
      tspl="${i3list[SAC]}" tdim="${i3list[WFH]}"
      tmrk=AC
    else
      tspl="${i3list[SAB]}" tdim="${i3list[WFW]}"
      tmrk=AB
    fi
  else
    tmrk="${i3list[AFF]}"
    tspl="${i3list[S${tmrk}]}"
    [[ ${I3FYRA_ORIENTATION,,} = vertical ]] \
      && tdim="${i3list[WFW]}" \
      || tdim="${i3list[WFH]}"
  fi

  { [[ -n $tspl ]] || ((tspl != tdim)) ;} && {
    # invert split
    tspl=$((tdim-tspl))
    eval "applysplits '$tmrk=$tspl'"
  }

  # family swap, rename all existing containers with their twins
  if [[ $m1 =~ X ]]; then 
    for (( i = 0; i < ${#i3list[LEX]}; i++ )); do
      cur=${i3list[LEX]:$i:1}
      if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
        case $cur in
          A ) acn[$cur]=C ;;
          B ) acn[$cur]=D ;;
          C ) acn[$cur]=A ;;
          D ) acn[$cur]=B ;;
        esac
      else
        case $cur in
          A ) acn[$cur]=B ;;
          B ) acn[$cur]=A ;;
          C ) acn[$cur]=D ;;
          D ) acn[$cur]=C ;;
        esac
      fi
      i3-msg -q "[con_mark=i34${cur}]" mark "i34tmp${cur}"
    done
    for k in "${!acn[@]}"; do
      i3-msg -q "[con_mark=i34tmp${k}]" mark "i34${acn[$k]}"
    done
    if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
      i3var set i3MAB "${i3list[MBD]}"
      i3var set i3MCD "${i3list[MAC]}"
    else
      i3var set i3MAC "${i3list[MBD]}"
      i3var set i3MBD "${i3list[MAC]}"
    fi
  else # swap within family, rename siblings
    for (( i = 0; i < ${#i3list[AFF]}; i++ )); do
      cur=${i3list[AFF]:$i:1}
      if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
        case $cur in
          A ) acn[$cur]=B ;;
          B ) acn[$cur]=A ;;
          C ) acn[$cur]=D ;;
          D ) acn[$cur]=C ;;
        esac
      else
        case $cur in
          A ) acn[$cur]=C ;;
          B ) acn[$cur]=D ;;
          C ) acn[$cur]=A ;;
          D ) acn[$cur]=B ;;
        esac
      fi
      i3-msg -q "[con_mark=i34${cur}]" mark "i34tmp${cur}"
    done
    for k in "${!acn[@]}"; do
      i3-msg -q "[con_mark=i34tmp${k}]" mark "i34${acn[$k]}"
    done
  fi

}
