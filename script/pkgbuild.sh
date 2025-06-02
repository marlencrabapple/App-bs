#!/usr/bin/env bash
  #
scriptdir="${0//\/$(basename "$0")}"
. "$scriptdir/bs-common.sh"c

[[ "${DEBUG:=0}" -eq 1 ]] && set -x

arch_packaging_repo_base="https://gitlab.archlinux.org/archlinux/packaging/packages"

pkgbuild_dir="${BS_ROOT:=/bs}/pkgbuild"
repo_container="${BS_ROOT:=/bs}/repo"
pkgdest="${BS_ROOT:=/bs}/pkgdest"
logdir="${BS_ROOT:=/bs}/log"

fetch_aur_pkg() {(
  pkgbase="$1"
  export PLENV_VERSION=system

  out="$(aur fetch -r "$pkgbase")"
  echo "$out"

  return "${out[*]:-1:1}"
)}

get_update_pkgbuild() {
  repo="$1"
  pkgbase="$2"

  if [[ ! -d "$pkgbase" ]]; then
    git clone "$arch_packaging_repo_base/$pkgbase.git"
    err="${?:-0}"

    [[ "${err:-0}" -eq 0 ]] && return 0

    warn "Failed to fetch '$pkgbase' from Arch Official Repository mirror"

    err=$(fetch_aur_pkg "$pkgbase")

    if [[ "$err" -ne 0 ]]; then
      warn "Failed to fetch '$pkgbase' from AUR"

      for repo in "${BS_REPOS[@]}"; do
        git clone "$BS_USERREPO_BASE_URI/$repo/$pkgbase.git"
        err="${?:-0}"

        if [[ "${err:-0}" -ne 0 ]]; then
          warn "Failed to clone '$pkgbase' from user added repo '$repo"
        fi
      done
    fi
  fi
}

expac_query_dbs() {
  pkgstr="$1"
  shift
  userdb=("$@")
  pkgchoices=()

  for db in Q S "${userdb[@]}"; do
    pkgchoices+=("$(expac "-${db}s" '%r\/%e' $pkgstr)")
  done
}

package_choice() {
  pkgchoices=("$@")

  choice=(
    "${pkgchoices[*]:0:1//\/*/}"
    "${pkgchoices[*]:0:1//*\//}"
  )

  [[ ${DEBUG:-0} -ne 0 ]] && warn "pkgchoices: ${pkgchoices[*]}"
  [[ ${DEBUG:-0} -ne 0 ]] && warn "choice: ${choice[*]}"

  echo "${choice[@]}"
  return ${?:-0}


  #local i=0
  #for pkgrepo in "${pkgchoices[@]}"; do
  #  printf "\(%d.\) %s\n" "$((++i))" "$pkgrepo"
  #done

  #echo ${pkgchoices[*]:0:1}
}

handle_pkgspec() {
  local pkgspec="$1"

  # FIX ME: First result is probably what we want unless the user declares
  # otherwise in the current local git config or a bs-repo-conf.toml file in
  # the repo root
  pkgchoices=($(expac_query_dbs "$pkgspec"))
  pkgrepo=("${pkgchoices[*]:0:1}")
  pkgbase=("${pkgchoices[*]:0:2}")

  # Fairly sure pactree includes the provided pkgspec compliant string in the
  # results...
  pkgtree=("$(pactree -lus "$pkgbase")")

  for pkgstr in "${pkgtree[@]}"; do
    pkgchoices=("$(expac_query_dbs "$pkgspec")")

    pkgrepo=("${pkgchoices[*]:0:1}")
    pkgbase=("${pkgchoices[*]:0:2}")

    #cd "$pkg" || continue # Superflous directory check
    get_update_pkgbuild "$pkgrepo" "$pkgbase"

    branches=($(git branch --all))
    curr_branch="${branches[*]:0:1}"
    new_branch="$curr_branch-$(date +%s)"

    git switch -c "$new_branch"
    git add -A
    git commit -S -m "Unsynced changes pre-rebase and rebuild"
    git push "$new_branch"

    for branch in "${branches[@]}"; do
      [[ -z "${branch//main|master/}" ]] || continue

      git switch "$curr_branch"
      git pull "$branch" --rebase
      err="${?:-0}"

      while [[ "${err:-0}" -ne 0 ]]; do
        git mergetool
        err="${?:-0}"
        git rebase --continue
        err="${?:-0}"
      done

      git push "$curr_branch"
    done
    cd "$pkgbuild_dir" || warn "Failed to change directory"
  done
}

for pkgspec in "$@"; do
  handle_pkgspec "$pkgspec"
done
