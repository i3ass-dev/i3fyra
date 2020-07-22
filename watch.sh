#!/bin/bash

_source=$(readlink -f "${BASH_SOURCE[0]}")
_dir=${_source%/*}
ta=$(< "$_dir/tests/array")

trap 'tput clear' SIGWINCH

cmd1=("$_dir/program.sh" --move left --array "$ta" --dryrun)
# cmd2=("$_dir/program.sh" --move up --array "$ta" --dryrun)

while read -r ; do
  clear
  bashbud --bump "$_dir"
  shellcheck "$_dir/program.sh" && {
    "${cmd1[@]}" --verbose
    time(
      while ((++i<50));do 
        "${cmd1[@]}"
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
