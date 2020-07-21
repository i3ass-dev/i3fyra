multihide(){

  ERM "multihide"
  ERM "========="

  local trg real i t

  trg="$1"

  declare -i targets
  for (( i = 0; i < ${#trg}; i++ )); do
    [[ ${trg:$i:1} =~ [${i3list[LVI]}] ]] || continue
    t=${trg:$i:1}
    ((targets |= _m[t]))
    real+=$t
  done

  ((targets)) || {
    ERR multihide failed, none of the containers visible
    return
  }

  [[ ${#real} -eq 1 ]] && containerhide "$real" && return

  if ((_isvertical)); then
    ((targets & _m[A] && targets & _m[B])) \
      && real=${real//[AB]/} && familyhide AB
    ((targets & _m[C] && targets & _m[D])) \
      && real=${real/[CD]/} && familyhide CD
  else
    ((targets & _m[A] && targets & _m[C])) \
      && real=${real/[AC]/} && familyhide AC
    ((targets & _m[B] && targets & _m[D])) \
      && real=${real/[BD]/} && familyhide BD
  fi

  for (( i = 0; i < ${#real}; i++ )); do
    containerhide "${real:$i:1}"
  done
}
