#!/bin/bash

messy() {

  # arguments are valid i3-msg arguments
  # separate resize commands and execute
  # all commands at once in cleanup()
  (( __o[verbose] )) && ERM "m $*"
  (( __o[dryrun]  )) || {
    [[ $* =~ resize ]] \
      && _sizstring+="$*;" \
      || _msgstring+="$*;"
  }
  
}
