#!/usr/bin/env bash

___printversion(){
  
cat << 'EOB' >&2
i3fyra - version: 1.025
updated: 2020-08-11 by budRich
EOB
}


# environment variables
: "${I3FYRA_MAIN_CONTAINER:=A}"
: "${I3FYRA_WS:=}"
: "${I3FYRA_ORIENTATION:=horizontal}"


main(){

  # __o[verbose]=1

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

___printhelp(){
  
cat << 'EOB' >&2
i3fyra - An advanced, simple grid-based tiling layout


SYNOPSIS
--------
i3fyra --show|-s CONTAINER [--force|-f] [--array ARRAY] [--verbose] [--dryrun]
i3fyra --float|-a [--array ARRAY] [--verbose] [--dryrun]
i3fyra --hide|-z CONTAINER [--force|-f] [--array ARRAY] [--verbose] [--dryrun]
i3fyra --layout|-l LAYOUT [--force|-f] [--array ARRAY] [--verbose] [--dryrun]
i3fyra --move|-m DIRECTION|CONTAINER [--force|-f] [--speed|-p INT] [--array ARRAY] [--verbose] [--dryrun]
i3fyra --help|-h
i3fyra --version|-v

OPTIONS
-------

--show|-s CONTAINER  
Show target container. If it doesn't exist, it
will be created and current window will be put in
it. If it is visible, nothing happens.


--force|-f  
If set virtual positions will be ignored.


--array ARRAY  
ARRAY should be the output of i3list. It is used
to improve speed when i3fyra is executed from a
script that already have the array, f.i. i3run and
i3Kornhe.  


--verbose  
If set information about execution will be
printed to stderr.


--dryrun  
If set no window manipulation will be done during
execution.


--float|-a  
Autolayout. If current window is tiled: floating
enabled If window is floating, it will be put in a
visible container. If there is no visible
containers. The window will be placed in a hidden
container. If no containers exist, container
'A'will be created and the window will be put
there.


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
  
  local i tsn dir trg tfam
  declare -i tsv splitexist size target sibling

  for i in ${1}; do
    tsn=${i%=*} # target name of split
    tsv=${i#*=} # target value of split

    if [[ $tsn = "${ori[main]}" || $tsn = main ]]; then
      tsn=${ori[main]}
      trg="X${ori[fam1]}" 
      dir=${ori[resizemain]} size=${ori[sizemain]}

      # when --layout option is used, invert split
      # if families are inverted
      # container A virtual position (VPA)
      # inverse mainsplit (2|3 || 1|3)
      [[ -n ${__o[layout]} ]] \
        && (( (_isvertical  && i3list[VPA] > 1)    \
           || (!_isvertical && i3list[VPA] % 2) )) \
        && ((tsv *= -1))

      splitexist=1
    else
      trg=${tsn:0:1}
      dir=${ori[resizefam]} size=${ori[sizefam]}

      target=${_m[$trg]}
      [[ ${tfam:=${ori[fam1]}} =~ $trg ]] || tfam=${ori[fam2]}
      sibling=$((_m[$tfam] & ~target))
      splitexist=$((target & _visible && sibling & _visible))
    fi

    ((tsv<0)) && tsv=$((size-(tsv*-1)))

    # i3list[XAC | XAB] has value of the workspace they are at
    ((splitexist)) && {
      # i3list[Sxx] = current/actual split xx
      i3list[S${tsn}]=${tsv}
      sezzy "con_mark=i34$trg" resize set "$dir" "$tsv" px
    }

    # i3list[Mxx] = last/stored    split xx
    # store split even if its not visible
    _v["i34M${tsn}"]=$tsv

  done
}

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

cleanup() {

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}()"

  local qflag k s

  ((__o[verbose])) || qflag='-q'

  ((${#_v[@]})) && varset

  [[ -n $_msgstring ]] && i3-msg "${qflag:-}" "$_msgstring"
  ((${#_r[@]})) && {
    for k in "${!_r[@]}"; do s+="[$k] ${_r[$k]};" ; done
    i3-msg "${qflag:-}" "$s"
  }

  ((__o[verbose])) && {
    local delta=$(( ($(date +%s%N)-_stamp) /1000 ))
    local time=$(((delta / 1000) % 1000))
    ERM  "---i3fyra done: ${time}ms---"
  }
}

containercreate(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"

  local trg=$1 
  local ghost="i34${trg}GHOST"

  # mainsplit is not created
  [[ -z ${i3list[X${ori[main]}]} ]] && initfyra

  [[ -z ${i3list[TWC]} ]] \
    && ERX "can't create container without window"

  dummywindow "$ghost"

  messy "[con_mark=$ghost]"            \
    move to mark "i34X${ori[main]}",   \
    split "${ori[charmain]}", layout tabbed
    
  messy "[con_id=${i3list[TWC]}]" \
    floating disable, move to mark "$ghost"
  messy "[con_mark=$ghost]" focus, focus parent
  messy mark "i34${trg}"
    
  # after creation, move cont to scratch
  messy "[con_mark=$ghost]" kill

  # run container show to show container to place
  # container in correct family, set _hidden
  # to trigger that functionality
  ((_hidden |= _m[$trg]))
  containershow "$trg"
}

containerhide(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local trg=$1
  local tfam sib main

  [[ ${#trg} -gt 1 ]] && {
    multihide "$trg"
    return
  }

  declare -i target sibling splitmain splitfam

  main=${ori[main]}
  [[ ${tfam:=${ori[fam1]}} =~ $trg ]] || tfam=${ori[fam2]}

  splitmain=${i3list[S$main]:=0}
  splitfam=${i3list[S$tfam]:=0}

  target=${_m[$trg]}
  sibling=$((_m[$tfam] & ~target))
  sib=${_n[$sibling]}

  messy "[con_mark=i34${trg}]" move scratchpad

  ((_visible &= ~target))
  ((_hidden  |= target))

  # if trg is last of it's fam, note it.
  # else focus sib
  ((! (sibling & _visible) ))  \
    && _v["i34F${tfam}"]=$trg  \
    || i3list[SIBFOC]=$sib

  # note splits
  ((splitmain && splitmain!=ori[sizemain])) && {
    _v["i34M${main}"]=$splitmain
    i3list[M${main}]=$splitmain
    _v["i34M${tfam}"]=$splitfam
    i3list[M${tfam}]=$splitfam
  }

}



containershow(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  # show target ($1/trg) container (A|B|C|D)
  # if it already is visible, do nothing.
  # if it doesn't exist, create it 
  local trg=$1
  declare -i target=${_m[$trg]}

  ((target & _m[ABCD])) || ERX "$trg not valid container"

  if ((target & _visible)); then
    return 0
  
  elif ((target & _hidden)); then

    declare -i family sibling dest tspl tdim swapon
    local tfam sib tdest tmrk main 

    main=${ori[main]}
    [[ ${tfam:=${ori[fam1]}} =~ $trg ]] || tfam=${ori[fam2]}

    family=${_m[$tfam]}
    sibling=$((family & ~target))
    dest=$((sibling & _visible ? family : _m[$main]))
    sib=${_n[$sibling]}
    tdest=i34X${_n[$dest]}

    swapon=$((_m[ABCD] & ~_m[$main]))

    # remove target from hidden here otherwise
    # familycreation gets borked up
    ((_hidden &= ~target))

    if ((dest == _m[$main])) ; then

      familyshow "$trg"

    else
      # WSA = active workspace
      messy "[con_mark=i34${trg}]" \
        move to workspace "${i3list[WSF]}", \
        floating disable, move to mark "$tdest"

      tspl=${i3list[M${tfam}]}
      tdim=${ori[sizefam]}     
      tmrk=$tfam

      ((_visible |= target))

      ((sibling & swapon)) && {
        messy "[con_mark=i34$trg]" \
          swap container with mark "i34$sib"
      }

      ((tspl && (tdim==tspl || !_famact) )) && {
          i3list[S${tmrk}]=$((tdim/2))
          applysplits "$tmrk=$tspl"
      }

    fi

  else
    containercreate "$trg"
  fi
}

dummywindow() {

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}()"

  local mark id
  
  mark=${1:?first argument not a mark name}

  ((__o[dryrun])) && id=777 || id="$(i3-msg open)"
  messy "[con_id=${id//[^0-9]/}]" floating disable, mark "$mark"
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
  
  local trg=$1 tfam ghost
  declare -i target=${_m[$trg]}

  [[ ${tfam:=${ori[fam1]}} =~ $trg ]] || tfam=${ori[fam2]}

  ghost="i34${tfam}GHOST"

  # messy "[con_mark=i34X${tfam}]" unmark

  dummywindow "$ghost"
  messy "[con_mark=$ghost]"             \
    move to mark "i34X${ori[main]}",    \
    split "${ori[charfam]}",            \
    layout tabbed,                      \
    move "${ori[movemain]}"

  messy "[con_mark=i34${trg}\$]"        \
    move to workspace "${i3list[WSF]}", \
    floating disable,                   \
    move to mark "$ghost",              \
    layout "split${ori[charfam]}",      \
    split "${ori[charfam]}",            \
    focus, focus parent

  messy mark "i34X${tfam}"
  # combine with above?
  messy "[con_mark=i34X${tfam}]" \
    move "${ori[movemain]}"

  messy "[con_mark=$ghost]" kill
  
  i3list[X${tfam}]=${i3list[WSF]}
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

  declare -i famw famh famx famy fams

  fams=$(( (_isvertical ? i3list[WFH] : i3list[WFW]) - i3list[S${ori[main]}] ))
  ((fams < 0)) && ((fams *= -1))

  famw=$((_isvertical ? i3list[WFW] : fams ))
  famh=$((_isvertical ? fams : i3list[WFH]))
  famx=$((_isvertical ? 0 : i3list[S${ori[main]}]))
  famy=$((_isvertical ? i3list[S${ori[main]}] : 0))

  messy "[con_mark=i34X${tfam}]" floating enable, \
    resize set "$famw" "$famh",                   \
    move absolute position "$famx" px "$famy" px, \
    move scratchpad

  _v["i34F${tfam}"]=${famchk}
  _v["i34M${ori[main]}"]=${i3list[S${ori[main]}]:=0}
  _v["i34M${tfam}"]=${i3list[S${tfam}]:=0}

}

familyshow(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"

  local arg=$1 ourfam trg theirfam

  [[ ${ourfam:=${ori[fam1]}} =~ ${arg:0:1} ]] \
    || ourfam=${ori[fam2]}

  declare -i i target newfamily
  declare -i ourfamily theirfamily firstfam

  ourfamily=${_m[$ourfam]}

  # our family doesn't exist
  # familycreate expects single char arg
  # where arg is an already created container
  [[ -z ${i3list[X$ourfam]} ]] && {
    familycreate "${arg:0:1}"
    newfamily=1
  }

  theirfamily=$((_m[ABCD] & ~ourfamily))
  theirfam=${_n[$theirfamily]}

  _famact=1
  for ((i=0;i<${#ourfam};i++)); do
    trg=${ourfam:$i:1}
    target=${_m[$trg]}
    if ((target & _hidden)); then
      ((_hidden &= ~target))
      ((_visible |= target))
    fi
  done

  i3list[S${ori[main]}]=${ori[sizemainhalf]}

  ((newfamily)) || messy "[con_mark=i34X${ourfam}]"    \
                   move to workspace "${i3list[WSF]}", \
                   floating disable,                   \
                   move to mark "i34X${ori[main]}"

  # if $ourfam is the first and the otherfamily
  # is visible swap'em
  firstfam=${_m[${ori[fam1]}]}
  ((ourfamily == firstfam && theirfamily & _visible)) \
    && messy "[con_mark=i34X${ourfam}]" \
       swap container with mark "i34X${theirfam}"

  applysplits "${ori[main]}=${i3list[M${ori[main]}]}"

}

initfyra() {

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}()"

  declare -i wsid
  local split

  # if we aren't on i3fyra workspace, go there
  # and do a new i3list to get the workspace id
  ((!__o[dryrun] && i3list[WSA] != i3list[WSF])) && {
    i3-msg -q workspace "${i3list[WSF]}"
    eval "$(i3list)"
    i3list[WFH]=${i3list[WAH]}
    i3list[WFW]=${i3list[WAW]}
  }
  
  wsid=${i3list[WAI]}
  messy "[con_id=$wsid]"           \
    mark "i34X${ori[main]}",       \
    split "${ori[charmain]}",      \
    layout "split${ori[charmain]}"

  for split in ${ori[fam1]} ${ori[fam2]} ${ori[main]}; do
    [[ -n ${i3list[M${split}]} ]] && continue
    [[ $split = "${ori[main]}" ]] \
      && size=${ori[sizemainhalf]} \
      || size=${ori[sizefamhalf]}
    i3list[M${split}]=$size
    _v["i34M$split"]=$size
  done

  _v["i34F${ori[fam1]}"]=X
  _v["i34F${ori[fam2]}"]=X
}

messy() {

  # arguments are valid i3-msg arguments
  # separate resize commands and execute
  # all commands at once in cleanup()
  (( __o[verbose] )) && ERM "m $*"
  (( __o[dryrun]  )) || _msgstring+="$*;"
}

sezzy() {
  local criterion=$1 args
  shift
  args=$*
  (( __o[verbose] )) && ERM "r [$criterion] $args"
  (( __o[dryrun]  )) || _r["$criterion"]=$args
}

multihide(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"
  
  local arg=$1 trg trgs i f1=${ori[fam1]} f2=${ori[fam2]}

  # only hide visible containers in arg
  for (( i = 0; i < ${#arg}; i++ )); do
    trg=${arg:$i:1}
    ((_m[$trg] & _visible)) && trgs+=$trg
  done

  ((${#trgs})) || return
  
  # hide whole families if present in arg and visible
  [[ $trgs =~ ${f1:0:1} && $trgs =~ ${f1:1:1} ]] \
    && trgs=${trgs//[$f1]/} && familyhide "$f1"
  
  [[ $trgs =~ ${f2:0:1} && $trgs =~ ${f2:1:1} ]] \
    && trgs=${trgs//[$f2]/} && familyhide "$f2"

  # hide rest if any
  ((${#trgs})) && for ((i=0;i<${#trgs};i++)); do
    containerhide "${trgs:$i:1}"
  done
}

orientationinit() {

  declare -gi _isvertical

  declare -i sw=${i3list[WFW]:-${i3list[WAW]}}
  declare -i sh=${i3list[WFH]:-${i3list[WAH]}}
  declare -i swh=$((sw/2))
  declare -i shh=$((sh/2))

  if [[ ${I3FYRA_ORIENTATION,,} = vertical ]]; then
    _isvertical=1
    ori=(

      [main]=AC [fam1]=AB [fam2]=CD

      [charmain]=v        [charfam]=h
      [movemain]=down     [movefam]=right
      [resizemain]=height [resizefam]=width
      [sizemain]=$sh      [sizefam]=$sw 
      [sizemainhalf]=$shh [sizefamhalf]=$swh

    )
  else
    _isvertical=0
    ori=(

      [main]=AB [fam1]=AC [fam2]=BD

      [charmain]=h        [charfam]=v
      [movemain]=right    [movefam]=down
      [resizemain]=width  [resizefam]=height
      [sizemain]=$sw      [sizefam]=$sh
      [sizemainhalf]=$swh [sizefamhalf]=$shh

    )
  fi
}

swapmeet(){

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}($*)"

  local m1=$1 m2=$2 tmrk k 
  local c1 c2 i1 i2 v1 v2

  declare -i tspl tdim i
  declare -A acn

  declare -a ivp
  declare -A iip

  iip=([A]=0 [B]=1 [C]=2 [D]=3)

  for k in "${!iip[@]}"; do
    ivp[${i3list[VP$k]}]=$k
  done

  messy "[con_mark=${m1}]"  swap mark "${m2}", mark i34tmp
  messy "[con_mark=${m2}]"  mark "${m1}"
  messy "[con_mark=i34tmp]" mark "${m2}"
  
  # acn[oldname]=newname
  declare -A acn

  # swap families, rename all containers
  if [[ $m1 =~ X ]]; then

    ((_isvertical)) \
      && acn=([A]=C [B]=D [C]=A [D]=B) \
      || acn=([A]=B [B]=A [C]=D [D]=C)

    tdim=${ori[sizemain]}
    tmrk=${ori[main]}
    tspl=${i3list[S$tmrk]}

    _v[i34M${ori[fam1]}]=${i3list[M${ori[fam2]}]}
    _v[i34M${ori[fam2]}]=${i3list[M${ori[fam1]}]}


    for k in A B C D; do

      c1=${k}             c2=${acn[$k]}
      i1=${iip[$c1]}      i2=${iip[$c2]}
      v1=${ivp[$i1]:=$i1} v2=${ivp[$i2]:=$i2}

      _v[i34VP$v1]=$i2
      _v[i34VP$v2]=$i1

      ((_m[$k] & (_visible | _hidden) )) || continue
      messy "[con_mark=i34$k]" mark "i34tmp$k"
    done

    for k in A B C D; do
      ((_m[$k] & (_visible | _hidden) )) || continue
      messy "[con_mark=i34tmp$k]" mark "i34${acn[$k]}"
    done

    
  else # swap within family

    c1=${m1#i34}   c2=${m2#i34}
    i1=${iip[$c1]} i2=${iip[$c2]}
    v1=${ivp[$i1]} v2=${ivp[$i2]}

    _v[i34VP$v1]=$i2
    _v[i34VP$v2]=$i1

    # dont use AFF ?
    tmrk="${i3list[AFF]}"
    tspl="${i3list[S${tmrk}]}"
    tdim=${ori[sizefam]}

  fi

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

  ((__o[verbose])) && ERM "f ${FUNCNAME[0]}(${_v[*]})"

  local key val json re mark

  json=$(i3-msg -t get_marks)

  for key in "${!_v[@]}"; do
    val=${_v[$key]}
    re="\"(${key}=[^\"]+)\""
    [[ $json =~ $re ]] && mark="${BASH_REMATCH[1]}"

    if [[ -z $mark ]]; then
      dummywindow "${key}=${val}"
      messy "[con_mark=${key}]" move scratchpad
    else
      messy "[con_mark=${key}]" mark "${key}=${val}"
    fi
    unset mark
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
  local wall trgpar wizoutput groupsize
  declare -i trgcon family sibling target relatives sibdir

  ((__o[dryrun])) && [[ -z ${wizoutput:=${i3list[VISWIZ]}} ]] \
    && wizoutput='trgcon=3333 wall=up trgpar=C groupsize=1' 

  : "${wizoutput:=$(i3viswiz -p "$dir" | head -1)}"

  eval "$wizoutput"

  wizoutput="tx=${trgx:=} ty=${trgy:=} con=${trgcon:=} "
  wizoutput+="wall=${wall:=} par=${trgpar:=} size=${groupsize:=}"

  ((__o[verbose])) && ERM "w $wizoutput"

  unset trgx trgy sx sy sw sh

  declare -A swapon

  swapon[u]=${_m[AB]} swapon[d]=${_m[CD]}
  swapon[l]=${_m[AC]} swapon[r]=${_m[BD]}

  ((_isvertical)) \
    && sibdir=$((_m[l]|_m[r])) \
    || sibdir=$((_m[u]|_m[d]))
    
  target=${_m[${i3list[TWP]}]}
  family=${_m[${i3list[TFF]}]}
  sibling=${_m[${i3list[TFS]}]}
  relatives=${_m[${i3list[TFO]}]}

  if [[ ${wall:-} != none ]]; then # hit wall, toggle something

    if ((_m[$dir] & sibdir)); then # sibling toggling
      
      local sib=${_n[$sibling]}

      if ((sibling & _visible)); then
        containerhide "$sib"
      elif ((sibling & _hidden)); then
        containershow "$sib"
        ((sibling & swapon[$dir])) \
          && swapmeet "i34$sib" "i34${_n[$target]}"
      elif ((groupsize > 1)); then # sibling doesn't exist
        # groupsize comes from viswiz and is the number
        # of real siblings in the current container
        # if its not more then one, do nothing
        windowmove "$sib"
        ((sibling & swapon[$dir])) \
          || swapmeet "i34$sib" "i34${_n[$target]}"
      fi
    
    else # family toggling

      local rel=${_n[$relatives]}

      if ((relatives & _visible)); then
        familyhide "$rel"
      elif ((relatives & _hidden)); then
        familyshow "$rel"
        ((relatives & swapon[$dir])) \
          && swapmeet "i34X$rel" "i34X${_n[$family]}"
      elif ((groupsize > 1)); then # relatives doesn't exist
        # groupsize comes from viswiz and is the number
        # of real siblings in the current container
        # if its not more then one, do nothing
        windowmove "${rel:0:1}"
        ((relatives & swapon[$dir])) \
          || swapmeet "i34X$rel" "i34X${_n[$family]}"
      fi
    fi

  else # trgpar is visible
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
    --options "s:faz:l:m:p:hv" \
    --longoptions "show:,force,array:,verbose,dryrun,float,hide:,layout:,move:,speed:,help,version," \
    -- "$@" || exit 98
)"

eval set -- "$options"
unset options

while true; do
  case "$1" in
    --show       | -s ) __o[show]="${2:-}" ; shift ;;
    --force      | -f ) __o[force]=1 ;; 
    --array      ) __o[array]="${2:-}" ; shift ;;
    --verbose    ) __o[verbose]=1 ;; 
    --dryrun     ) __o[dryrun]=1 ;; 
    --float      | -a ) __o[float]=1 ;; 
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


