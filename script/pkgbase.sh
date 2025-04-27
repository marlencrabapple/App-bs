[[ "${PKGBASE_DEBUG:-${BS_DEBUG:-0}}" -ne 0 ]] && set -x && DEBUG=1

pacinfo_import() {
  pkgstr="$1"
  printrepo="$2"

  pacinfo="$(pacinfo "$pkgstr" <&-)"
  err=$?

  if [[ "$err" -eq 0 ]]; then
    local pkgbase=""
    local pkgrepo=""

    $(perl -e 'use v5.40; my (%matches) = $ARGV[0] =~ /(Base|Repository):\s+([a-z0-9\-_]+)/g; say join "\n", map { "export pkg" . lc substr($_, 0, 4) . "=$matches{$_}" } keys %matches' "$pacinfo")

    local err="$?"

    [[ -z "$pkgbase" ]] && [[ -z "$pkgrepo" ]] && exit $err
    [[ "$err" -eq 0 ]] || exit $err

    echo "${printrepo:+"$pkgrepo/"}$pkgbase" && return 0
  fi
}

res=()

for pkg in "$@"; do
    res+=("$(pacinfo_import "$pkg")")
done

echo "$(perl -e 'use v5.40; use List::Util; say join " ", List::Util::uniqstr @ARGV' "${res[@]}")"
