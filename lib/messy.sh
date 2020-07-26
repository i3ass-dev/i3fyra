#!/bin/bash

messy() {

  # arguments are valid i3-msg arguments
  # separate resize commands and execute
  # all commands at once in cleanup()
  (( __o[verbose] )) && ERM "m $*"
  (( __o[dryrun]  )) || _msgstring+="$*;"
}

sezzy() {
  local criterion=$1 args=${@:2}

  (( __o[verbose] )) && ERM "r [$criterion] $args"
  (( __o[dryrun]  )) || _r["$criterion"]=$args
}
