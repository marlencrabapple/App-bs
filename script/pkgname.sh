#!/usr/bin/env ksh

pkgin=("$@")

[[ "${DEBUG:-0}" -eq 1 ]] && set -ofunctrace -x

for in in "${pkgin[@]}"; do expac -Ss '%n' "$in"; status="$?"; 
  if [[ "${status} -gt 0 ]]; then
    >&2 echo "ERROR: expac excited with a non-zero status"
    >&2 echo "Could not resolve '$in'"

    [[ "${IGNORE_ERROR:-0}" -ne 1 ]] || exit "$status"
    
    errc="$( errc +1 ))"
  else
    pkgout[]+="$in";
  fi
done

[[ "$IGNORE_ERROR" -eq 1 ]] && [[ $errc -gt 0 ]] && errstr="(with $srrc errors)"

>&2 echo "Successfully resolved ${errstr:-""}the following packages:"
echo "${pkgout[@]}"
