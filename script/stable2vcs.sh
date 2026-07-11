#!/usr/bin/env ksh

set -x

pkgname=("$@")

for pkg in $(expac -S '%n' "${pkgname[@]}"); do
  [[ -d "$pkg" ]] || pkgctl repo clone --protocol https "$pkg"
  [[ "$?" -eq 0 ]] || continue
  [[ -d "${pkg}-git" ]] || cp -vaf "$pkg" "${pkg}-git"
done
