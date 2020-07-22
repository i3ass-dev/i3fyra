#!/bin/bash

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
