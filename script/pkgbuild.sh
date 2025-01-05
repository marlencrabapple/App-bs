#!/usr/bin/env bash

shopt -s nullglob

[[ -n "$PB_DEBUG" ]] && set -x;
[[ -n "$PB_PKGSYNC" ]] && pacman -Syy;

arch_pkgbuildrepo_uri="https://gitlab.archlinux.org/archlinux/packaging/packages"

default_repo="${PB_PKGDEST_REPO:-universe}"
default_carch="${PB_CARCH:-${CARCH:-x86_64}}"
default_target="${PB_TARGET:-default}"
default_triple="${PB_TRIPLE:-"$default_repo-$default_carch-$default_target"}"

targets=("${AURDIT_TARGETS[@]}" "${BS_TARGETLIST[@]}");

[[ ${#targets[*]} -eq 0 ]] && targets=("$HOME/.local/bs/targets/$default_triple")

pacman_conf_reporemote() {
  local searchrepo="$1"
  local pacman_conf="${PACMAN_CONF:-"/etc/pacman.conf"}"
  
  for section in $(pacini --section-list "$pacman_conf"); do
    [[ -z "${section//options/}" ]] && continue

    # TODO: print section in uppercase
    remote="$(printenv "BS_${section^}_REMOTE")"
    
    [[ -z "${section//$searchrepo/}" ]] && echo "$remote" && return 0
      #&& echo "${remote:-$(pacini --section=universe "$pacman_conf" remote)}" \
      #&& return 0
  done
  
  return $?
}

pacinfo_import() {
  pkgstr="$1"

  pacinfo="$(pacinfo "$pkgstr" <&-)"
  err=$?
     
  if [[ $err -eq 0 ]]; then
    local pkgstr=""
    local pkgrepo=""

    $(perl -e 'use v5.40; my (%matches) = $ARGV[0] =~ /(Base|Repository):\s+([a-z0-9\-]+)/g; say join "\n", map { "export pkg" . lc substr($_, 0, 4) . "=$matches{$_}" } keys %matches' "$pacinfo")
    
    local err=$?

    [[ -z "$pkgbase" ]] && [[ -z "$pkgrepo" ]] && return $err

    export pkgstr="$pkgbase"
    export pkgrepo

    echo "$pkgrepo/$pkgparse"
  fi
}

update_pkgbuild_repo() {
  branches=($(git branch -a))
  
  echo "Attempting to update PKGBUILD repo..."
  for branch in "${branches[*]:0:1}" main master; do
    git config --global --add safe.directory "$(pwd)"
    git switch -c pkgbuild-$(date +%s)
    git add -A
    git commit -m "Misc changes"
    # git switch "$curr_branch"
    git pull origin "$branch" --rebase
    err=$?
    [[ err -eq 0 ]] && break
  done
}

clone_aur_pkg() {
  local remoteuri
  remoteuri="$(pacman_conf_reporemote "$pkgrepo")"
  local pacinierr=$?
  local err=0

  if [[ -n "$remoteuri" ]] && [[ $pacinierr -eq 0 ]]; then
    echo "Cloning '$pkg' from '$pkgrepo' PKGBUILD meta repo..."

    # I think I can do this in a git subtree or whatever the thing that
    # isn't submodules is called...
    git clone "$remoteuri/$pkgstr.git" "$pkgstr"
  else
    echo "Attempting to clone '$pkg' from Arch Gitlab..."
  
    git clone \
      "$arch_pkgbuildrepo_uri/${pkgstr}.git" \
      "$pkgstr"

    err=$?
  fi
  
  if [[ $err -eq 0 ]]; then 
    echo "$pkgstr" && return 0
    return $err
  fi
}

clone_custom_repo_remote() {
  local remoteuri="$(pacman_conf_reporemote "$pkgrepo")"
  local pacinierr=$?

  if [[ -n "$remoteuri" ]] && [[ $pacinierr -eq 0 ]]; then
    echo "Cloning '$pkg' from '$pkgrepo' PKGBUILD meta repo..."
    
    # Currently imagining $remoteuri as a git tree with $pkgstr as a subtree
    # rather than deal with submodules or the seemingly undocumented branch per
    # package format the Github AUR mirror currently uses
    git clone "$remoteuri/$pkgstr.git" "$pkgstr"
  fi
  
  [[ $? -eq 0 ]] && pkg="$pkgstr" && exit 0

  return $?
}

clone_arch_remote() {
  local pkg="$1"
  local pkgstr="$2"

  echo "Attempting to clone '$pkg' from Arch Gitlab..."

  git clone \
    "$arch_pkgbuildrepo_uri/${pkgstr}.git" \
    "$pkgstr"
  
  local err=$?
  return $err
}

buildpkg() {
  local target="$5"
  local pkg="$1"
  local pkgstr="$2"
  local makepkg_conf="${3:-${targets[*]:0:1}/etc/makepkg.conf}"
  local pacman_conf="${4:-${targets[*]:0:1}/etc/pacman.conf}"
  local err=0

  set -x
  
  env SRCDEST="$SRCDEST/pkgbuild-$(epoch)" aur build -v -f -S \
    --cargs="C,u,n${PB_CHROOT_CLEAN:+,c}" \
    --margs="L,A,s,f,i${PB_MAKEPKG_CLEANALL:+,C,c}" --syncdeps --pkgver \
    --makepkg-conf="$makepkg_conf" --pacman-conf="$pacman_conf" \
    ${PB_TMPCHROOT:+--temp} ${PB_REBUILDALL:+-f} \
    -d universe --root "$AURDIT_ROOT/repo/${target:-"$CARCH"}" -c -D $CHROOT

  err=$?

  [[ $PB_DEBUG -ne 0 ]] || set +x
  return $err
}

enter_pkgbuilddir() {
  local pkg="$1"
  eval cd "$pkg" || return $?
  return 0
}

exit_pkgbuilddir() {
  cd .. || return $?
  return 0
}

buildpkg_all_targets() {
  local pkg="$1"
  local pkgstr="$2"
  local targets+=("$@")

  for target in "${targets[@]}"; do
    makepkg_conf="$target/makepkg.conf"
    pacman_conf="$target/pacman.conf"
    target_name="$(basename "$target")"

    buildpkg "$pkg" "$pkgstr" "$makepkg_conf" "$pacman_conf" "$target_out"
    local err=$?
  done
}

findpkg() {
  local pkgbase="$1"
  local pkgrepo="$2"

  pkgsearch=($(pacman -Sqs "^$pkgstr\$"))
  
  if [[ -z "${pkgsearch[*]:0:1}" ]] || [[ $? -ne 0 ]]; then
      pacinfo_import "$pkgstr"
  else
      pkgstr="${pkgsearch[*]:0:1}"
  fi

  if [[ ! -d "$pkgstr" ]]; then
     if [[ -n "$pkgstr" ]] && [[ -n "${pkgrepo//*aur*/}" ]]; then
        clone_custom_repo_remote "$pkgrepo" "$pkg" "$pkgstr"
        err=$?

        if [[ $err -ne 0 ]] || [[ ! -d "$pkgstr" ]]; then
          clone_arch_remote "$pkg" "$pkgstr"
          err=$?
        fi
      elif [[ -z "${pkgrepo//aur/}" ]]; then
        clone_aur_pkg "$pkgstr"
      err=$?
    fi
  fi

  return ${?:-0}
}

buildpkgs() {
  for pkg in "$@"; do
    err=0
    echo "Working on '$pkg'..."
  
    pkgrepo="${pkg%%/*}"
    pkgstr="${pkg##"$repo/"}"

    enter_pkgbuilddir "$pkg"
    [[ $? -ne 0 ]] && echo "Could not change directories to '$pkg'" && continue

    update_pkgbuild_repo

    echo "Updating package source checksums..."
    [[ -n "$PB_UPDPKGSUMS" ]] && updpkgsums
  
    echo "Attempting to build '$pkg'..."

    [[ ${#targetcarchs} -ne 0 ]] \
	&& buildpkg_all_targets "$pkg" "$pkgstr" "${targetcarchs[@]}"

    err=$?
  
    [[ $err -eq 0 ]] && echo "Successfully built '$pkg'!!"
    exit_pkgbuilddir
  done
}

buildpkgs "$@"

