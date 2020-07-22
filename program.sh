#!/usr/bin/env bash

___printversion(){
  
cat << 'EOB' >&2
i3fyra - version: 0.723
updated: 2020-07-22 by budRich
EOB
}


# environment variables
: "${I3FYRA_MAIN_CONTAINER:=A}"
: "${I3FYRA_WS:=1}"
: "${I3FYRA_ORIENTATION:=horizontal}"


main(){

  __o[verbose]=1

  trap 'cleanup' EXIT

  declare -gA _m         # bitwise masks _m[A]=1
  declare -gA i3list     # globals array
  declare -ga _n         # bitwise names _n[1]=A
  declare -ga _v         # "i3var"s to set
  declare -g  _msgstring # combined i3-msg
  declare -g  _sizstring # combined resize i3-msg

  declare -gi _existing _visible _hidden
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

___printhelp(){
  
cat << 'EOB' >&2
i3fyra - An advanced, simple grid-based tiling layout


SYNOPSIS
--------
i3fyra --show|-s CONTAINER [--array ARRAY] [--verbose] [--dryrun]
i3fyra --float|-a [--target|-t CRITERION] [--array ARRAY] [--verbose] [--dryrun]
i3fyra --hide|-z CONTAINER [--array ARRAY] [--verbose] [--dryrun]
i3fyra --layout|-l LAYOUT [--array ARRAY] [--verbose] [--dryrun]
i3fyra --move|-m DIRECTION|CONTAINER [--speed|-p INT]  [--target|-t CRITERION] [--array ARRAY] [--verbose] [--dryrun]
i3fyra --help|-h
i3fyra --version|-v

OPTIONS
-------

--show|-s CONTAINER  
Show target container. If it doesn't exist, it
will be created and current window will be put in
it. If it is visible, nothing happens.


--array ARRAY  

--verbose  

--dryrun  

--float|-a  
Autolayout. If current window is tiled: floating
enabled If window is floating, it will be put in a
visible container. If there is no visible
containers. The window will be placed in a hidden
container. If no containers exist, container
'A'will be created and the window will be put
there.


--target|-t CRITERION  
Criteria is a string passed to i3list to use a
different target then active window.  

Example:  
$ i3fyra --move B --target "-i sublime_text" this
will target the first found window with the
instance name sublime_text. See i3list(1), for all
available options.


--hide|-z CONTAINER  
Hide target containers if visible.  


--layout|-l LAYOUT  
alter splits Changes the given splits. INT is a
distance in pixels. AB is on X axis from the left
side if INT is positive, from the right side if it
is negative. AC and BD is on Y axis from the top
if INT is positive, from the bottom if it is
negative. The whole argument needs to be quoted.
Example:  
$ i3fyra --layout 'AB=-300 BD=420'  



--move|-m CONTAINER  
Moves current window to target container, either
defined by it's name or it's position relative to
the current container with a direction:
[l|left][r|right][u|up][d|down] If the container
doesnt exist it is created. If argument is a
direction and there is no container in that
direction, Connected container(s) visibility is
toggled. If current window is floating or not
inside ABCD, normal movement is performed.
Distance for moving floating windows with this
action can be defined with the --speed option.
Example: $ i3fyra --speed 30 -m r Will move
current window 30 pixels to the right, if it is
floating.


--speed|-p INT  
Distance in pixels to move a floating window.
Defaults to 30.


--help|-h  
Show help and exit.


--version|-v  
Show version and exit
EOB
}


applysplits(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local i tsn dir mrk
  declare -i tsv par parw parh

  # i3list[WF-W/H] - i3fyra workspace W/H
  # i3list[WA-W/H] - active workspace W/H
  parw=${i3list[WFW]:-"${i3list[WAW]}"}
  parh=${i3list[WFH]:-"${i3list[WAH]}"}

  for i in ${1}; do
    tsn=${i%=*} # target name of split
    tsv=${i#*=} # target value of split

    if ((_isvertical)); then
      [[ $tsn = AC ]] \
        && par=$parh dir=height mrk=i34XAB \
        || par=$parw dir=width  mrk=i34${tsn:0:1}
    else
      [[ $tsn = AB ]] \
        && par=$parw dir=width  mrk=i34XAC \
        || par=$parh dir=height mrk=i34${tsn:0:1}
    fi

    ((tsv<0)) && tsv=$((par-(tsv*-1)))

    messy "[con_mark=${mrk}]" resize set "$dir" "$tsv" px

    # i3list[Sxx] = current/actual split xx
    # i3list[Mxx] = last/stored    split xx
    i3list[S${tsn}]=${tsv}
    _v+=("i34M${tsn}" "${tsv}")

  done
}

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
    [[ ${i3list[LHI]} =~ $k ]] && ((_hidden |= _m[$k]))
    [[ ${i3list[LVI]} =~ $k ]] && ((_visible|= _m[$k]))
  done

  _existing=$((_hidden | _visible))
}

cleanup() {

  local qflag

  ((__o[verbose])) || qflag='-q'

  ((${#_v[@]}))   && varset "${_v[@]}"

  [[ -n $_msgstring ]] && i3-msg "${qflag:-}" "$_msgstring"
  [[ -n $_sizstring ]] && i3-msg "${qflag:-}" "$_sizstring"

  ((__o[verbose])) && {
    _=${_n[1]}
    _=$_isvertical
    _=$_existing
    local delta=$(( ($(date +%s%N)-_stamp) /1000 ))
    local time=$(((delta / 1000) % 1000))
    ERM  $'\n'"${time}ms"
    ERM "----------------------------"
  }
}

containercreate(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"

  local trg=$1

  [[ -z ${i3list[TWC]} ]] \
    && ERX "can't create container without window"

  dummywindow dummy

  messy "[con_mark=dummy]" split h, layout tabbed
  messy "[con_id=${i3list[TWC]}]" \
    floating disable, move to mark dummy
  messy "[con_mark=dummy]" focus, focus parent
  messy mark "i34${trg}"
  messy "[con_mark=dummy]" kill
    
  # after creation, move cont to scratch
  messy "[con_mark=i34${trg}]" focus, floating enable, \
    move absolute position 0 px 0 px, \
    resize set $((i3list[WFW]/2)) px $((i3list[WFH]/2)) px, \
    move scratchpad
  # add to trg to hid
  i3list[LHI]+=$trg

  ((_hidden |= _m[$trg]))
  # run container show to show container
  containershow "$trg"
}

containerhide(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg=$1
  local tfam sib mainsplit

  [[ ${#trg} -gt 1 ]] && multihide "$trg" && return

  declare -i family target sibling ref1 ref2 mainsize famsize

  target=${_m[$trg]}

  if ((_isvertical)); then
    mainsplit=AC
    ref1=${i3list[WFH]}
    ref2=${i3list[WFW]}
    family=$((target & _m[AB]?_m[AB]:_m[CD]))
  else
    mainsplit=AB
    ref1=${i3list[WFW]}
    ref2=${i3list[WFH]}
    family=$((target & _m[AC]?_m[AC]:_m[BD]))
  fi

  tfam=${_n[$family]}
  mainsize=${i3list[S$mainsplit]}
  famsize=${i3list[S$tfam]}

  sibling=$((family & ~target))
  sib=${_n[$sibling]}

  messy "[con_mark=i34${trg}]" move scratchpad

  # add to trg to hid
  i3list[LHI]+=$trg
  i3list[LVI]=${i3list[LVI]/$trg/}
  i3list[LVI]=${i3list[LVI]:-X}

  ((_visible &= ~target))
  ((_hidden  |= target))

  # if trg is last of it's fam, note it.
  # else focus sib
  ((! (sibling & _visible) ))       \
    && _v+=("i34F${tfam}" "$trg") \
    || i3list[SIBFOC]=$sib

  # note splits
  ((mainsize && mainsize!=ref1)) && {
    _v+=("i34M${mainsplit}" "$mainsize")
    i3list[M${mainsplit}]=$mainsize
  }

  ((famsize && famsize!=ref2)) && {
    _v+=("i34M${tfam}" "$famsize")
    i3list[M${tfam}]=$famsize
  }
}



containershow(){
  # show target ($1/trg) container (A|B|C|D)
  # if it already is visible, do nothing.
  # if it doesn't exist, create it 
  local trg=$1 tfam sib tdest tmrk

  declare -i target family sibling dest tspl tdim famshow
  declare -a swap=()

  target=${_m[$trg]}

  ((target & _m[ABCD])) || ERX "$trg not valid container"

  if ((target & _visible)); then
    return 0

  # if if no containers are visible create layout
  elif ((!_visible)); then
    layoutcreate "$trg"
  
  elif ((target & _hidden)); then
    
    ((_isvertical)) \
      && family=$((target & _m[AB]?_m[AB]:_m[CD])) \
      || family=$((target & _m[AC]?_m[AC]:_m[BD]))

    sibling=$((family & ~target))

    # if sibling is visible, dest (destination)
    # is family otherwise main container
    dest=$(( sibling & _visible ? family :
             (_isvertical ? _m[AC] : _m[AB]) ))

    tfam=${_n[$family]}
    sib=${_n[$sibling]}
    tdest=i34X${_n[$dest]}    

    # if tdest is main container, trg is first in family
    if ((_isvertical && dest == _m[AC])); then
      familycreate "$trg"
      famshow=1
    
    elif ((!_isvertical && dest == _m[AB])); then
      familycreate "$trg"
      famshow=1
    else
      # WSA = active workspace
      messy "[con_mark=i34${trg}]" \
        move to workspace "${i3list[WSA]}", \
        floating disable, move to mark "$tdest"
    fi

    if ((_isvertical)); then
      mainsplit=AC
      mainfam=AB
      sibgroup=BD
      size1=${i3list[WFH]}
      size2=${i3list[WFW]}
    else
      mainsplit=AB
      mainfam=AC
      sibgroup=CD
      size1=${i3list[WFW]}
      size2=${i3list[WFH]}
    fi

    # swap - what to swap
    ((dest == _m[$mainsplit] && sibling & _m[$mainfam])) \
      && swap=("X$tfam" "X${i3list[LAL]/$tfam/}")

    ((dest == _m[$tfam] && sibling & _m[$sibgroup])) \
      && swap=("$trg" "$sib")

    if ((dest == _m[$mainsplit])); then
      tspl=${i3list[M$mainsplit]}  # stored split
      tdim=$size1                  # workspace width
      tmrk=$mainsplit
    else
      tspl=${i3list[M${tfam}]}
      tdim=$size2     
      tmrk=$tfam 
    fi

    ((${#swap[@]})) && {
      messy "[con_mark=i34${swap[0]}]" \
        swap container with mark "i34${swap[1]}"
    }

    ((tspl)) \
      && ((tdim==size2 || !_famact)) && {
        i3list[S${tmrk}]=$((tdim/2))
        applysplits "$tmrk=$tspl"
    }

    ((_visible |= target))
    ((_hiddent &= ~target))

    # bring the whole family
    ((famshow && sibling & _hidden)) && containershow "$sib"

  else
    containercreate "$trg"
  fi
}

dummywindow() {

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}()"

  local mark id
  
  mark=${1:?first argument not a mark name}

  if ((__o[dryrun])); then
    id=777
  else
    id="$(i3-msg open)"
    id="${id//[^0-9]/}"
  fi

  messy "[con_id=$id]" floating disable, mark "$mark"
}

set -E
trap '[ "$?" -ne 98 ] || exit 98' ERR

ERX() { >&2 echo  "[ERROR] $*" ; exit 98 ;}
ERR() { >&2 echo  "[WARNING] $*"  ;}
ERM() { >&2 echo  "$*"  ;}
ERH(){
  ___printhelp >&2
  [[ -n "$*" ]] && printf '\n%s\n' "$*" >&2
  exit 98
}

familycreate(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg tfam ofam
  trg=$1

  if [[ $trg =~ A|C ]];then
    tfam=AC
    ofam=BD
  else
    ofam=AC
    tfam=BD
  fi

  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    if [[ $trg =~ A|B ]];then
      tfam=AB
      ofam=CD
    else
      ofam=AB
      tfam=CD
    fi
  fi

  messy "[con_mark=i34X${tfam}]" unmark

  dummywindow dummy
  
  messy "[con_mark=dummy]" \
    move to mark "i34X${ofam}", split v, layout tabbed

  messy "[con_mark=i34${trg}]" \
    move to workspace "${i3list[WSA]}", \
    floating disable, \
    move to mark dummy
  messy "[con_mark=dummy]" focus, focus parent
  messy mark i34X${tfam}

  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    messy "[con_mark=dummy]" layout splith, split h
    messy "[con_mark=dummy]" kill
    messy "[con_mark=i34X${tfam}]" move down
  else
    messy "[con_mark=dummy]" layout splitv, split v
    messy "[con_mark=dummy]" kill
    messy "[con_mark=i34X${tfam}]" move right
  fi

}

familyhide(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local tfam=$1
  local trg famchk tfammem i

  for (( i = 0; i < 2; i++ )); do
    trg=${tfam:$i:1}
    if [[ ${trg} =~ [${i3list[LVI]}] ]]; then
      messy "[con_mark=i34${trg}]" focus, floating enable, \
        move absolute position 0 px 0 px, \
        resize set \
        "$((i3list[WFW]/2))" px \
        "$((i3list[WFH]/2))" px, \
        move scratchpad

      i3list[LHI]+=$trg
      i3list[LVI]=${i3list[LVI]/$trg/}

      famchk+=${trg}
    fi
  done

  # i3var set "i34F${tfam}" "${famchk}"
  # i3var set "i34MAB" "${i3list[SAB]}"
  # i3var set "i34M${tfam}" "${i3list[S${tfam}]}"
  _v+=("i34F${tfam}" "${famchk}")
  _v+=("i34MAB" "${i3list[SAB]}")
  _v+=("i34M${tfam}" "${i3list[S${tfam}]}")

}

familyshow(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"

  local fam=$1
  local tfammem="${i3list[F${fam}]}"
  # F${fam} - family memory

  _famact=1
  for (( i = 0; i < ${#tfammem}; i++ )); do
    [[ ${tfammem:$i:1} =~ [${i3list[LHI]}] ]] \
      && containershow "${tfammem:$i:1}"
  done

  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    i3list[SAC]=$((i3list[WFH]/2))
    applysplits "AC=${i3list[MAC]}"
  else
    i3list[SAB]=$((i3list[WFW]/2))
    applysplits "AB=${i3list[MAB]}"
  fi
}

layoutcreate(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg fam

  trg=$1

  messy workspace "${i3list[WSF]}"

  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    [[ $trg =~ A|B ]] && fam=AB || fam=CD 
    messy "[con_mark=i34XAC]" unmark
  else
    [[ $trg =~ A|C ]] && fam=AC || fam=BD
    messy "[con_mark=i34XAB]" unmark
  fi

  dummywindow dummy
  
  messy "[con_mark=dummy]" \
    split v, layout tabbed
  
  messy "[con_mark=i34${trg}]" \
    move to workspace "${i3list[WSA]}", \
    floating disable, \
    move to mark dummy

  messy "[con_mark=dummy]" focus parent
  messy mark i34X${fam}, focus parent

  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    messy "[con_mark=dummy]" layout splith, split h
    messy "[con_mark=dummy]" kill
    messy "[con_mark=i34XAC]" layout splitv, split v
  else
    messy "[con_mark=dummy]" layout default, split v
    messy "[con_mark=dummy]" kill
    messy "[con_mark=i34XAB]" layout splith, split h
  fi

}

messy() {

  (( __o[verbose] )) && ERM "m $*"

  (( __o[dryrun]  )) || {
    if [[ $* =~ resize ]]; then
      _sizstring+="$*;"
    else
      _msgstring+="$*;"
    fi
  }

  # i3-msg -q "$*"
}

multihide(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg real i

  trg="$1"

  for (( i = 0; i < ${#trg}; i++ )); do
    [[ ${trg:$i:1} =~ [${i3list[LVI]}] ]] && real+=${trg:$i:1}
  done

  [[ -z $real ]] && return
  [[ ${#real} -eq 1 ]] && containerhide "$real" && return
  
  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    [[ "A" =~ [$real] ]] && [[ "B" =~ [$real] ]] \
      && real=${real/A/} real=${real/B/} && familyhide AB
    [[ "C" =~ [$real] ]] && [[ "D" =~ [$real] ]] \
      && real=${real/C/} real=${real/D/} && familyhide CD
  else
    [[ "A" =~ [$real] ]] && [[ "C" =~ [$real] ]] \
      && real=${real/A/} real=${real/C/} && familyhide AC
    [[ "B" =~ [$real] ]] && [[ "D" =~ [$real] ]] \
      && real=${real/B/} real=${real/D/} && familyhide BD
  fi

  for (( i = 0; i < ${#real}; i++ )); do
    containerhide "${real:$i:1}"
  done
}

swapmeet(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local m1=$1
  local m2=$2
  local i k cur
  
  # array with containers (k=current name, v=twin name)
  declare -A acn 

  messy "[con_mark=${m1}]"  swap mark "${m2}", mark i34tmp
  messy "[con_mark=${m2}]"  mark "${m1}"
  messy "[con_mark=i34tmp]" mark "${m2}"

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
      messy "[con_mark=i34${cur}]" mark "i34tmp${cur}"
    done
    for k in "${!acn[@]}"; do
      messy "[con_mark=i34tmp${k}]" mark "i34${acn[$k]}"
    done
    if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
      _v+=(i3MAB "${i3list[MBD]}")
      _v+=(i3MCD "${i3list[MAC]}")
      # i3var set i3MAB "${i3list[MBD]}"
      # i3var set i3MCD "${i3list[MAC]}"
    else
      _v+=(i3MAC "${i3list[MBD]}")
      _v+=(i3MBD "${i3list[MAC]}")
      # i3var set i3MAC "${i3list[MBD]}"
      # i3var set i3MBD "${i3list[MAC]}"
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
      messy "[con_mark=i34${cur}]" mark "i34tmp${cur}"
    done
    for k in "${!acn[@]}"; do
      messy "[con_mark=i34tmp${k}]" mark "i34${acn[$k]}"
    done
  fi

}

togglefloat(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}()"
  
  local trg

  # AWF - 1 = floating; 0 = tiled
  if ((i3list[AWF]==1)); then

    # WSA != i3fyra && normal tiling
    if ((i3list[WSA]!=i3list[WSF])); then
      messy "[con_id=${i3list[AWC]}]" floating disable
      return
    fi

    # AWF == 1 && make AWC tiled and move AWC to trg
    if [[ ${i3list[CMA]} =~ [${i3list[LVI]:-}] ]]; then
      trg="${i3list[CMA]}" 
    elif [[ -n ${i3list[LVI]:-} ]]; then
      trg=${i3list[LVI]:0:1}
    elif [[ -n ${i3list[LHI]:-} ]]; then
      trg=${i3list[LHI]:0:1}
    else
      trg="${i3list[CMA]}"
    fi

    if [[ $trg =~ [${i3list[LEX]:-}] ]]; then
      containershow "$trg"
      messy "[con_id=${i3list[AWC]}]" floating disable, \
        move to mark "i34${trg}"
    else
      # if $trg container doesn't exist, create it
      containershow "$trg"
    fi
  else
    # AWF == 0 && make AWC floating
    messy "[con_id=${i3list[AWC]}]" floating enable
  fi
}

varset() {

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"

  local key val json re mark

  json=$(i3-msg -t get_marks)

  while [[ -n $1 ]]; do
    key=$1 val=$2
    shift 2
    re="\"(${key}=[^\"]+)\""
    [[ $json =~ $re ]] && mark="${BASH_REMATCH[1]}"

    if [[ -z $mark ]]; then
      dummywindow "${key}=${val}"
      messy "[con_mark=${key}]" move scratchpad
    else
      messy "[con_mark=${key}]" mark "${key}=${val}"
    fi
  done
}

windowmove(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  local dir=$1
  local trgcon wall trgpar ldir newcont

  # if dir is a container, show/create that container
  # and move the window there

  [[ $dir =~ A|B|C|D ]] && {

    [[ ! ${i3list[LEX]:-} =~ $dir ]] \
      && newcont=1 || newcont=0

    containershow "$dir"

    if ((newcont!=1)); then
      messy "[con_id=${i3list[TWC]}]" \
        focus, floating disable, \
        move to mark "i34${dir}", focus
    fi
    exit

  }

  # else make sure direction is lowercase u,l,d,r
  dir=${dir,,}
  dir=${dir:0:1}

  # "exit if $dir not valid"
  [[ ! $dir =~ u|r|l|d ]] \
    && ERX "$dir not a valid direction."

  case $dir in
    l ) ldir=left  ;;
    r ) ldir=right ;;
    u ) ldir=up    ;;
    d ) ldir=down  ;;
  esac

  # if window is floating, move with i3Kornhe
  ((i3list[AWF]==1)) && { i3Kornhe m $ldir; exit ;}

  # get visible info from i3viswiz
  # trgcon is the container currently at target pos
  # trgpar is the parent of trgcon (A|B|C|D)

  eval "$(i3viswiz -p "$dir" | head -1)"

  if [[ ${wall:-} != none ]]; then

    # sibling toggling
    if [[ $dir =~ u|d ]]; then
      if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
        # if relatives is visible, hide 'em
        if [[ ${i3list[LVI]} =~ [${i3list[AFO]}] ]]; then
          familyhide "${i3list[AFO]}"
        else
            # else show container, add to swap
            familyshow "${i3list[AFO]}"
            {
              { [[ $dir = u ]] && [[ ${i3list[AFO]} = AB ]] ; } || \
              { [[ $dir = d ]] && [[ ${i3list[AFO]} = CD ]] ; }
            } && toswap=("i34X${i3list[AFO]}" "i34X${i3list[AFF]}")
        fi
      else
        # if sibling is visible, hide it
        if [[ ${i3list[AFS]} =~ [${i3list[LVI]}] ]]; then
          containerhide "${i3list[AFS]}"
        else
            # else show container, add to swap
            containershow "${i3list[AFS]}"
            {
              { [[ $dir = u ]] && [[ ${i3list[AFS]} =~ [AB] ]] ; } || \
              { [[ $dir = d ]] && [[ ${i3list[AFS]} =~ [CD] ]] ; }
            } && toswap=("i34${i3list[AFS]}" "i34${i3list[AWP]}")
        fi
      fi

    # family toggling
    elif [[ $dir =~ l|r ]]; then
      if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
        # if sibling is visible, hide it
        if [[ ${i3list[AFS]} =~ [${i3list[LVI]}] ]]; then
          containerhide "${i3list[AFS]}"
        else
            # else show container, add to swap
            containershow "${i3list[AFS]}"
            {
              { [[ $dir = l ]] && [[ ${i3list[AFS]} =~ [AC] ]] ; } || \
              { [[ $dir = r ]] && [[ ${i3list[AFS]} =~ [BD] ]] ; }
            } && toswap=("i34${i3list[AFS]}" "i34${i3list[AWP]}")
        fi
      else
        # if relatives is visible, hide 'em
        if [[ ${i3list[LVI]} =~ [${i3list[AFO]}] ]]; then
          familyhide "${i3list[AFO]}"
        else
            # else show container, add to swap
            familyshow "${i3list[AFO]}"
            {
              { [[ $dir = l ]] && [[ ${i3list[AFO]} = AC ]] ; } || \
              { [[ $dir = r ]] && [[ ${i3list[AFO]} = BD ]] ; }
            } && toswap=("i34X${i3list[AFO]}" "i34X${i3list[AFF]}")
        fi
      fi
    fi
    
    [[ -n ${toswap[1]:-} ]] \
      && swapmeet "${toswap[0]}" "${toswap[1]}" \
      && messy "[con_id=${i3list[TWC]}]" focus

  else
    # trgpar is visible, if layout is tabbed just move it
    if [[ ${i3list[C${trgpar}L]} =~ tabbed|stacked ]]; then
      
      messy "[con_id=${i3list[TWC]}]" \
        focus, floating disable, \
        move to mark "i34${trgpar}", focus

        
    elif [[ ${i3list[C${trgpar}L]} =~ splitv|splith ]]; then
      # target and current container is the same, move normaly
      if [[ $trgpar = "${i3list[TWP]}" ]]; then
        messy "[con_id=${i3list[TWC]}]" move "$ldir"

      # move below/to the right of the last child of the container  
      elif [[ $dir =~ l|u ]]; then
        messy "[con_id=${i3list[TWC]}]" \
          move to mark "i34${trgpar}", focus

      # move above/to the left of target container
      else
        messy "[con_id=${trgcon}]" mark i34tmp
        messy "[con_id=${i3list[TWC]}]" \
          move to mark "i34tmp", swap mark i34tmp
        messy "[con_id=${trgcon}]" unmark
      fi
    fi
  fi
}

declare -A __o
options="$(
  getopt --name "[ERROR]:i3fyra" \
    --options "s:at:z:l:m:p:hv" \
    --longoptions "show:,array:,verbose,dryrun,float,target:,hide:,layout:,move:,speed:,help,version," \
    -- "$@" || exit 98
)"

eval set -- "$options"
unset options

while true; do
  case "$1" in
    --show       | -s ) __o[show]="${2:-}" ; shift ;;
    --array      ) __o[array]="${2:-}" ; shift ;;
    --verbose    ) __o[verbose]=1 ;; 
    --dryrun     ) __o[dryrun]=1 ;; 
    --float      | -a ) __o[float]=1 ;; 
    --target     | -t ) __o[target]="${2:-}" ; shift ;;
    --hide       | -z ) __o[hide]="${2:-}" ; shift ;;
    --layout     | -l ) __o[layout]="${2:-}" ; shift ;;
    --move       | -m ) __o[move]="${2:-}" ; shift ;;
    --speed      | -p ) __o[speed]="${2:-}" ; shift ;;
    --help       | -h ) ___printhelp && exit ;;
    --version    | -v ) ___printversion && exit ;;
    -- ) shift ; break ;;
    *  ) break ;;
  esac
  shift
done

[[ ${__lastarg:="${!#:-}"} =~ ^--$|${0}$ ]] \
  && __lastarg="" 


main "${@}"


