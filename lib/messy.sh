#!/bin/bash

messy() {
  ERM "m $*"
  i3-msg -q "$@"
}
