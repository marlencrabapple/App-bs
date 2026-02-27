#!/usr/bin/env ksh
[[ "${DEBUG:-0}" -gt 0 ]] && set -x

#set -o...

workdir="$BS_ROOT/pkgbuild/work"

function buildpkgs {
  typeset -a pkglist=("$@")
  first="${pkglist[*]:0:1}"
  count=${#pkglist[*]}
  typeset -a buildfail

  wkchroot="$first+$((count - 1))-$(date +%s)"

  #  for targetchroot in "$BS_CHROOT" "$CHROOT/archlinux-x86_64-ivybridge"; do
  for pkg in "${pkglist[@]}"; do
    pkgbase="$(pkgbase "$(basename "$pkg")")"
    cd "$workdir/$pkg" || exit $?

    git switch -c worktree-$(date +%s)
    git add PKGBUILD .SRCINFO
    git commit -S -m "..."
    git stash -a
    git fetch --all
    git pull --rebase

    nvim PKGBUILD

    makechrootpkg -r$targetchroot -l"$wkchroot" -Cun - -Lisf
    [[ $? -ne 0 ]] && buildfail+=("$pkg")

    bs-repoadd $BS_ROOT/pkgdest/$pkg*{any,x86_64_v3}.pkg.tar.zst

    cd "$workdir"
  done
  #  done
}

buildpkgs "$@"
