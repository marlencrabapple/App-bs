#!/usr/bin/env ksh

for in in "$@"; do
  if [[ -f "$in" ]]; then
    mkdir "$(basename "$archive")"
  elif [[ -d "$in" ]]; then
    ...
  fi



