#!/bin/bash

messy() {
  # arguments are valid i3-msg arguments
  # separate resize commands and execute
  # all commands at once in cleanup()
  (( __o[verbose] )) && ERM "m $*"
  (( __o[dryrun]  )) || _msgstring+="$*;"
  # (( __o[dryrun]  )) || {
  #   i3-msg "$*"
  #   sleep .555
  # }
}

sezzy() {
  local criterion=$1 args
  shift
  args=$*
  (( __o[verbose] )) && ERM "r [$criterion] $args"
  (( __o[dryrun]  )) || new_size["$criterion"]=$args
}
