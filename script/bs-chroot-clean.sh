#!/usr/bin/env ksh
[[ "${DEBUG:-0}" -eq 1 ]] && set -x -ofunctrace
set -e

[[ -z "$BS_CHROOT" ]] && >&2 echo "BS_CHROOT is not set" && exit 1

cd "$BS_CHROOT" || exit $?

tmpname="$(slugify "$(basename "$(pwd)")/root)")-$(epoch)"
sudo mv -v "$BS_CHROOT/root" ../"$tmpname"
sudo rm -rv "$BS_CHROOT"/*
sudo mv -v ../"$tmpname" "$BS_CHROOT/root"

[[ $? -eq 0 ]] && echo "Successfully cleaned chroot ($BS_CHROOT)"
