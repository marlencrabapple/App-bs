#!/usr/bin/env bash
#
# Usage: Run inside of a git repository with submodules
#
# Adapted from: https://gist.github.com/nlgranger/9ecc0b4f0a9e1c0079860bdc7cfb11f7#file-pkgbuild_submodule-sh

[[ "${DEBUG:-0}" -eq 1 ]] && set -x

function repo_name() {
  git config --get remote.origin.url | sed 's|.*/\([^/.]*\)\(.git\)*$|\1|g'
}

function configure_repo() {
  [ -f "$1/.gitmodules" ] || return

  echo "  repo=\"$1\""
  echo "  git -C \$repo submodule init"
  git -C $1 submodule foreach -q 'echo $name $sm_path' | while read -r sm_name sm_path; do
    name=$(git -C $1/$sm_path config --get remote.origin.url | sed 's|.*/\([^/.]*\)\(.git\)*$|\1|g')
    echo "  git -C \$repo config submodule.$sm_name.url \"file://\$srcdir/$name\""
  done
  echo "  git -C \$repo -c protocol.file.allow=always submodule update"
  echo ""

  git -C $1 submodule foreach -q 'echo $sm_path' | while read -r sm_path; do
    configure_repo $1/$sm_path
  done
}

git submodule update --init --recursive

# -- sources --
echo "sources=("
# Parent repo
echo "  \"git+$(git config get remote.origin.url)#commit=$(git rev-parse HEAD)\""
# submodules
#
while read -r status; do
  status=(${status[@]})

  [[ $DEBUG -eq 1 ]] && >&2 echo "👋status: ${status[*]}"
  commit=${status[*]:0:1}
  path=${status[*]:1:1}

  url="$(git -C "$path" remote get-url origin)"
  echo "  \"$(basename "$path")::git+$url#commit=$commit\""
done <<<"$(git submodule status --recursive)"

echo ")"
echo ""

# -- checksums --
echo "checksums=("
# parent repo
echo '  "SKIP"'
# submodules
git submodule foreach --recursive -q 'echo "  \"SKIP\""'
echo ")"
echo ""

# -- prepare --
echo "prepare() {"
echo ""
configure_repo .
echo "}"
