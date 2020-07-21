#!/bin/bash

messy() {
  ERM "msg: $*"
  i3-msg -q "$@"
}
