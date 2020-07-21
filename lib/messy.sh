#!/bin/bash

messy() {
  ((__o[verbose])) && ERM "m $*"
  _msg+=("$*;")
  # i3-msg -q "$@"
}
