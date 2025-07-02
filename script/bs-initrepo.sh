#!/usr/bin/env bash
[[ ${BS_DEBUG:=${DEBUG:-0}} -gt 0 ]] && set -x

BS_REPOROOT="/bs/repo/penny-linux/universe"

[[ ${#BS_REPONAME[*]:-0} -eq 0 ]] && BS_REPONAME=(
  universe # -testing, -staging and potentially other variations are 
           # automatically appended to the end of the names given in
           # this variable
)

BS_REPOVAR_DEFAULT=(
  staging # Not sure yet if this is a hard requirement compared to the testing
          # variant which won't be used for building unless set otherwise by the
          # user
  testing
)

[[ ${#BS_REPOVARIANT[*]:-0} -eq 0 ]] && BS_REPOVARIANT=(
  ${BS_REPOVAR_DEFAULT[@]}
)

# /bs/repo/penny-linux/universe/os/x86_64_v3-znver3
# $BS_REPOROOT/$BS_REPONAME[0..${#@}]/$BS_TARGET_SUBPATH/$BS_TARGET[${#@}]

pacman_conf_reporemote() {
  local searchrepo="$1"
  [[ -z "$searchrepo" ]] \
     && echo "Called without/with an empty string" \
     && return 1;

  for target in "${targets[@]}"; do
    local pacman_conf="${target:-"/etc"}/pacman.conf"
    
    for section in $(pacini --section-list "$pacman_conf"); do
      [[ -z "${section//options/}" ]] && continue

      remote="$(printenv "BS_${section^^}_REMOTE")"
      
      [[ -z "${section//$searchrepo/}" ]] && echo "$remote" && return 0
    done
  done
  
  return $?
}

repobase="$BS_ROOT/repo/penny-linux/universe"

for target in /$BS_ROOT/target/*; do
  for repo in $target/{-{staging,testing},}; do
    targetrepo="$target/$repobase/$repo/os"
    mkdir -p "$targetrepo"
    repo-add -s -k"$BS_GPG_PUBID" "$target_repo/$repo.db.tar.zst"
  done
done

