#!/usr/bin/env ksh
set -x -ofunctrace

for in in ./*; do
  if [[ -x "$in/dnscrypt-proxy" ]]; then
    archive="$(basename "$(pwd)")-$(basename "$in")"
    DESTFNAME="$archive" ctzst.sh "$in"

    GNUPGHOME=/bs/.gnupg-ian@domains \
      gpg -u 4D8733704B740FC4B330EF5E8FFAD8B7BA73987 -sb "$archive.tar.zst"

    for bin in sha512sum b2sum; do
      "$bin" "./$archive.tar.zst"{,.sig} | tee -a "$bin.txt"
    done
  fi
done
