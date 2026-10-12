#!/usr/bin/env ksh
set -x -ofunctrace

function mkdist {
  _distname="$(basename "$SRCDIR")-$(git -C "$SRCDIR" describe --long --tags)"
  distname="$_distname"
  rel=1

  dist_outd="${OUTDIR:+${OUTDIR:-$(pwd)}/}$distname"

  while [[ -d "$dist_outd" ]]; do
    distname="$_distname-$rel"
    rel="$((rel + 1))"
  done

  mkdir -p "$dist_outd" || return "$?"

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
      targetdir="$dist_outd/$targetbase"
      distarch="$dist_outd/$distarch_fn"

      [[ -d "$target" ]] || continue

      cp -vaf "$target" "$targetdir"

      (
        cd "$dist_outd"
        ctzst.sh "$targetbase"
        [[ "$?" -eq 0 ]] && rm -rv "$targetbase"

        export GNUPGHOME
        gpg --verbose ${GPG_PUBID:+-u $GPG_PUBID} -sb ./"$distarch_fn"
      )

      for bin in "${DIGESTBIN[@]}"; do
        [[ -x "$bin" ]] || bin="$(which "$bin")"

        "$bin" "$distarch"{.sig,} |
          tee -a "$dist_outd/$(basename "$bin").txt"
      done
    done
  )
}

mkdist "$@"
