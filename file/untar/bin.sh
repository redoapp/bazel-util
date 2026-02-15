#!/usr/bin/env bash
set -euo pipefail

options=''
while [[ $1 == --?* ]]; do
    options+=" $1"
    shift
done
[[ $1 != -- ]] || shift

dir="$1"
shift

mkdir -p "$dir"
for f in "$@"; do
  tar xf "$f" -C "$dir" $options 2> /dev/null
done
