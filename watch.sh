#!/bin/bash

_source=$(readlink -f "${BASH_SOURCE[0]}")
_dir=${_source%/*}
ta=$(< "$_dir/tests/array")

while read -r ; do
  clear
  bashbud --bump "$_dir"
  shellcheck "$_dir/program.sh" && {

    time(
      while ((++i<50));do 
        "$_dir/program.sh" \
           --move up       \
           --array "$ta"   \
           --dryrun
      done > /dev/null 2>&1
    )
    :
  }
done < <(
  inotifywait --event close_write          \
              --recursive --monitor        \
              --exclude 'awklib[.]sh$'     \
              "$_dir"/lib/*.sh             \
              "$_dir/main.sh"              \
              "$_dir/manifest.md"
)
