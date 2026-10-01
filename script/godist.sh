#!/usr/bin/env ksh
set -x -ofunctrace

function mkdist {
  _distname="$(basename "$SRCDIR")-$(git -C "$SRCDIR" describe --long --tags)"
  distname="$_distname"
  rel=1

  while [[ -d "$distname" ]]; do
    distname="$_distname-$rel"
    rel="$((rel + 1))"
  done

  mkdir "$distname" || return "$?"
  dist_outdir="${OUTDIR:-$distname}"
  #olddir="${OLDDIR:-.old-$(epoch)}"
  installdir="${INSTALLDIR:-./}"

  typeset -a DIGESTBIN=("${TARGET[@]}")
  [[ ${#DIGESTBIN[@]} -gt 0 ]] ||
    DIGESTBIN=(b2sum sha512sum)

  (
    cd "$installdir" || return $?

    typeset -a TARGET=("${TARGET[@]}")
    [[ ${#TARGET[@]} -gt 0 ]] ||
      TARGET=(./{linux,darwin,windows}_{arm*,amd*})

    for target in "${TARGET[@]}"; do
      targetbase="$distname-$(basename "$target")"
      distarch_fn="$targetbase.tar.zst"
      targetdir="$dist_outdir/$targetbase"
      distarch="$dist_outdir/$distarch_fn"

      [[ -d "$target" ]] || continue

      cp -vaf "$target" "$targetdir"

      (
        cd "$dist_outdir"
        ctzst.sh "$targetbase"
        [[ "$?" -eq 0 ]] && rm -rv "$targetbase"

        export GNUPGHOME
        gpg --verbose -sb ./"$distarch_fn"
      )

      for bin in "${DIGESTBIN[@]}"; do
        [[ -x "$bin" ]] || bin="$(which "$bin")"

        "$bin" "$distarch"{.sig,} |
          tee -a "$dist_outdir/$(basename "$bin").txt"
      done
    done
  )
}

mkdist "$@"
