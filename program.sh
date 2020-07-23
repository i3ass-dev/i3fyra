#!/usr/bin/env bash

___printversion(){
  
cat << 'EOB' >&2
i3fyra - version: 0.898
updated: 2020-07-23 by budRich
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
  
  local k
  declare -i i

  for k in A B C D l r u d; do
    _m[$k]=$((1<<i++))
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
  messy "[con_mark=i34${trg}]" move scratchpad

  ((_hidden |= _m[$trg]))
  # run container show to show container
  containershow "$trg"
}

containerhide(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg=$1
  local tfam sib mainsplit

  [[ ${#trg} -gt 1 ]] && {
    multihide "$trg"
    return
  }

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

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  # show target ($1/trg) container (A|B|C|D)
  # if it already is visible, do nothing.
  # if it doesn't exist, create it 
  local trg=$1

  declare -i target
  target=${_m[$trg]}

  ((target & _m[ABCD])) || ERX "$trg not valid container"

  if ((target & _visible)); then
    return 0
  
  elif ((target & _hidden)); then

    # if if no containers are visible create layout
    ((!_visible)) && layoutcreate "$trg"

    declare -i family sibling dest tspl tdim
    declare -i famshow size1 size2

    local tfam sib tdest tmrk mainsplit 
    local mainfam sibgroup

    declare -a swap=()

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

    family=$((target & _m[$mainfam] ? _m[$mainfam] 
           :( _m[ABCD] & ~_m[$mainfam] ) ))

    sibling=$((family & ~target))
    dest=$((sibling & _visible ? family : _m[$mainsplit]))
    tfam=${_n[$family]}
    sib=${_n[$sibling]}
    tdest=i34X${_n[$dest]}

    # if tdest is main container, trg is first in family
    if ((dest == _m[$mainsplit])) ; then

      familycreate "$trg"
      famshow=1

      tspl=${i3list[M$mainsplit]}  # stored split
      tdim=$size1                  # workspace width
      tmrk=$mainsplit

      ((sibling & _m[$mainfam])) \
        && swap=("X$tfam" "X${i3list[LAL]/$tfam/}")

    else
      # WSA = active workspace
      messy "[con_mark=i34${trg}]" \
        move to workspace "${i3list[WSA]}", \
        floating disable, move to mark "$tdest"

      tspl=${i3list[M${tfam}]}
      tdim=$size2     
      tmrk=$tfam

      ((sibling & _m[$sibgroup])) && swap=("$trg" "$sib")

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

    ((_visible |= target)) && ((_hidden &= ~target))

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
  
  local trg ourfam theirfam split dir
  declare -i target ourfamily  theirfamily f1 f2

  trg=$1
  target=${_m[$trg]}

  ((_isvertical)) \
    && split=h dir=down  f1=${_m[AB]} f2=${_m[CD]} \
    || split=v dir=right f1=${_m[AC]} f2=${_m[BD]}

  ourfamily=$((target & f1 ? f1 : f2))
  theirfamily=$((_m[ABCD] & ~ourfamily))
  ourfam=${_n[$ourfamily]} theirfam=${_n[$theirfamily]}

  messy "[con_mark=i34X${ourfam}]" unmark
  dummywindow dummy
  messy "[con_mark=dummy]" \
    move to mark "i34X${theirfam}", split v, layout tabbed

  messy "[con_mark=i34${trg}]" \
    move to workspace "${i3list[WSA]}", \
    floating disable, \
    move to mark dummy
  messy "[con_mark=dummy]" focus, focus parent
  messy mark i34X${ourfam}

  messy "[con_mark=dummy]" \
    layout "split${split}", split "$split"
  messy "[con_mark=dummy]" kill
  messy "[con_mark=i34X${ourfam}]" move "$dir"
}

familyhide(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg famchk tfam=$1

  declare -i target i

  for ((i=0;i<${#tfam};i++)); do

    trg=${tfam:$i:1}
    target=${_m[$trg]}

    if ((target & _visible)); then
      # messy "[con_mark=i34${trg}]" move scratchpad

      ((_visible &= ~target))
      ((_hidden  |= target))

      famchk+=${trg}
    fi
  done

  messy "[con_mark=i34X${tfam}]" move scratchpad

  _v+=("i34F${tfam}" "${famchk}")
  _v+=("i34MAB" "${i3list[SAB]}")
  _v+=("i34M${tfam}" "${i3list[S${tfam}]}")

}

# trg=$1
# target=${_m[$trg]}

# ((_isvertical)) \
#   && split=h dir=down  f1=${_m[AB]} f2=${_m[CD]} \
#   || split=v dir=right f1=${_m[AC]} f2=${_m[BD]}

# ourfamily=$((target & f1 ? f1 : f2))
# theirfamily=$((_m[ABCD] & ~ourfamily))
# ourfam=${_n[$ourfamily]} theirfam=${_n[$theirfamily]}

# messy "[con_mark=i34X${ourfam}]" unmark
# dummywindow dummy
# messy "[con_mark=dummy]" \
#   move to mark "i34X${theirfam}", split v, layout tabbed

# messy "[con_mark=i34${trg}]" \
#   move to workspace "${i3list[WSA]}", \
#   floating disable, \
#   move to mark dummy
# messy "[con_mark=dummy]" focus, focus parent
# messy mark i34X${ourfam}

# messy "[con_mark=dummy]" \
#   layout "split${split}", split "$split"
# messy "[con_mark=dummy]" kill
# messy "[con_mark=i34X${ourfam}]" move "$dir"

familyshow(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"

  local ourfam=$1 trg theirfam

  declare -i i target ourfamily theirfamily

  ourfamily=${_m[$ourfam]}
  theirfamily=$((_m[ABCD] & ~ourfamily))
  theirfam=${_n[$theirfamily]}

  _famact=1
  for ((i=0;i<${#ourfam};i++)); do
    trg=${ourfam:$i:1}
    target=${_m[$trg]}
    ((target & _hidden)) \
      && ((_hidden &= ~target)) && ((_visible |= target))
    # containershow "$trg"
  done

  if ((_isvertical)); then
    split=h dir=down
    i3list[SAC]=$((i3list[WFH]/2))
    splits="AC=${i3list[MAC]}"
  else
    split=v dir=right
    i3list[SAB]=$((i3list[WFW]/2))
    splits="AB=${i3list[MAB]}"
  fi

  messy "[con_mark=i34X${theirfam}]" \
    split "$split", focus, focus parent
  messy mark i34templar
  messy "[con_mark=i34X${ourfam}]" \
    move to workspace "${i3list[WSA]}", \
    floating disable, \
    move to mark "i34templar", \
    move "$dir"
  messy "[con_mark=i34templar]" unmark

  applysplits "$splits"

}

layoutcreate(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg fam s1 s2
  declare -i target f1 f2

  trg=$1
  target=${_m[$trg]}

  ((_isvertical)) \
    && s1=h s2=v f1=${_m[AB]} f2=${_m[CD]} \
    || s1=v s2=h f1=${_m[AC]} f2=${_m[BD]}

  fam=${_n[$((target & f1 ? f1 : f2))]}

  messy workspace "${i3list[WSF]}"
  dummywindow dummy
  
  messy "[con_mark=dummy]" \
    split v, layout tabbed
  
  messy "[con_mark=i34${trg}]" \
    move to workspace "${i3list[WSA]}", \
    floating disable, \
    move to mark dummy

  messy "[con_mark=dummy]" focus parent
  messy mark i34X${fam}, focus parent

  messy "[con_mark=dummy]"  layout "split${s1}", split "$s1"
  messy "[con_mark=dummy]" kill
  messy "[con_mark=i34XAC]" layout "split${s2}", split "$s2"

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
  
  local trg arg targets i

  arg="$1"

  # only hide visible containers in arg
  for (( i = 0; i < ${#arg}; i++ )); do
    trg=${arg:$i:1}
    ((_m[$trg] & _visible)) && targets+=$trg
  done

  ((${#targets} == 0)) && return
  
  # hide whole families if present in arg and visible
  if ((_isvertical)); then
    [[ $targets =~ A && $targets =~ B ]] \
      && targets=${targets//[AB]/} && familyhide AB
    [[ $targets =~ C && $targets =~ D ]] \
      && targets=${targets//[CD]/} && familyhide CD
  else
    [[ $targets =~ A && $targets =~ C ]] \
      && targets=${targets//[AC]/} && familyhide AC
    [[ $targets =~ B && $targets =~ D ]] \
      && targets=${targets//[BD]/} && familyhide BD
  fi

  # hide rest if any
  ((${#targets})) && for ((i=0;i<${#targets};i++)); do
    containerhide "${targets:$i:1}"
  done
}

swapmeet(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local m1=$1 m2=$2 tmrk old
  declare -i tspl tdim i
  declare -A acn

  messy "[con_mark=${m1}]"  swap mark "${m2}", mark i34tmp
  messy "[con_mark=${m2}]"  mark "${m1}"
  messy "[con_mark=i34tmp]" mark "${m2}"


  # family swap, rename all existing containers with their twins
  if [[ $m1 =~ X ]]; then
    # acn[oldname]=newname
    if ((_isvertical)); then
      tspl="${i3list[SAC]}" tdim="${i3list[WFH]}"
      tmrk=AC
      acn=([A]=C [B]=D [C]=A [D]=B)
      _v+=(i3MAB "${i3list[MCD]}")
      _v+=(i3MCD "${i3list[MAB]}")
    else
      tspl="${i3list[SAB]}" tdim="${i3list[WFW]}"
      tmrk=AB
      acn=([A]=B [B]=A [C]=D [D]=C)
      _v+=(i3MAC "${i3list[MBD]}")
      _v+=(i3MBD "${i3list[MAC]}")
    fi

  else # swap within family, rename siblings
    tmrk="${i3list[AFF]}"
    tspl="${i3list[S${tmrk}]}"

    if ((_isvertical)); then
      acn=([A]=B [B]=A [C]=D [D]=C)
      tdim="${i3list[WFW]}"
    else
      acn=([A]=C [B]=D [C]=A [D]=B)
      tdim="${i3list[WFH]}"
    fi
  fi

  for ((i =0;i< ${#i3list[LEX]};i++)); do
    old=${i3list[LEX]:$i:1}
    messy "[con_mark=i34${old}]" mark "i34tmp${old}"
  done

  for ((i =0;i< ${#i3list[LEX]};i++)); do
    old=${i3list[LEX]:$i:1}
    messy "[con_mark=i34tmp${old}]" mark "i34${acn[$old]}"
  done

  # invert split
  ((tspl+tdim)) && applysplits "$tmrk=$((tdim-tspl))"
  messy "[con_id=${i3list[TWC]}]" focus
}

togglefloat(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}()"

  local trg
  declare -i main=${_m[$I3FYRA_MAIN_CONTAINER]}

  # AWF - 1 = floating; 0 = tiled
  if ((i3list[AWF]==1)); then

    # WSA != i3fyra && normal tiling
    if ((i3list[WSA]!=i3list[WSF])); then
      messy "[con_id=${i3list[AWC]}]" floating disable
      return
    fi
    
    if ((main & _visible)); then
      trg=$I3FYRA_MAIN_CONTAINER
    elif ((_visible)); then
      trg=${i3list[LVI]:0:1}
    elif ((_hidden)); then
      trg=${i3list[LHI]:0:1}
    else
      trg=$I3FYRA_MAIN_CONTAINER
    fi

    if (( _m[$trg] & (_visible | _hidden) )); then
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
  local ldir

  declare -i newcont

  # if dir is a container, show/create that container
  # and move the window there
  [[ $dir =~ ^A|B|C|D$ ]] && {

    [[ ${i3list[LEX]} =~ $dir ]] || newcont=1

    containershow "$dir"

    ((newcont)) || messy "[con_id=${i3list[TWC]}]"      \
                          focus, floating disable,      \
                          move to mark "i34${dir}", focus

    return

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
  ((i3list[AWF]==1)) && {
    ((__o[verbose])) && ERM k i3Kornhe "m $ldir"
    ((__o[dryrun]))  || i3Kornhe m $ldir
    exit 
  }

  # get visible info from i3viswiz
  # trgcon is the container currently at target pos
  # trgpar is the parent of trgcon (A|B|C|D)
  local wall trgpar wizoutput
  declare -i trgcon family sibling target relatives sibdir

  ((__o[dryrun])) && [[ -z ${wizoutput:=${i3list[VISWIZ]}} ]] \
    && wizoutput='trgcon=3333 wall=up trgpar=C' 

  : "${wizoutput:="$(i3viswiz -p "$dir" | head -1)"}"

  eval "$wizoutput"
  unset trgx trgy sx sy sw sh

  declare -A swapon

  if ((_isvertical)); then
    sibdir=$((_m[l]|_m[r]))
    swapon[l]=${_m[AC]} swapon[r]=${_m[BD]}
    swapon[u]=${_m[AB]} swapon[d]=${_m[CD]}

  else
    sibdir=$((_m[u]|_m[d]))
    swapon[u]=${_m[AB]} swapon[d]=${_m[CD]}
    swapon[l]=${_m[AC]} swapon[r]=${_m[BD]}

  fi

  target=${_m[${i3list[AWP]}]}
  family=${_m[${i3list[AFF]}]}
  sibling=${_m[${i3list[AFS]}]}
  relatives=${_m[${i3list[AFO]}]}

  # moving in to screen edge (wall), toggle something
  if [[ ${wall:-} != none ]]; then

    # sibling toggling
    if ((_m[$dir] & sibdir)); then
      if ((sibling & _visible)); then
        containerhide "${_n[$sibling]}"
      else
        containershow "${_n[$sibling]}"
        ((sibling & swapon[$dir])) \
          && swapmeet "i34${_n[$sibling]}" "i34${_n[$target]}"
      fi
    # family toggling
    else
      if ((relatives & _visible)); then
        familyhide "${_n[$relatives]}"
      else
        familyshow "${_n[$relatives]}"
        ((relatives & swapon[$dir])) \
          && swapmeet "i34X${_n[$relatives]}" "i34X${_n[$family]}"
      fi
    fi

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


