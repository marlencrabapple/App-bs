#!/usr/bin/env bash

shopt -s nullglob

[[ -n "$PB_DEBUG" ]] && set -x;
[[ -n "$PB_PKGSYNC" ]] && pacman -Syy;

arch_pkgbuildrepo_uri="https://gitlab.archlinux.org/archlinux/packaging/packages"

aur_repo_uri="https://aur.archlinux.org/"

default_repo="${PB_PKGDEST_REPO:-universe}"
default_carch="${PB_CARCH:-${CARCH:-x86_64}}"
default_target="${PB_TARGET:-default}"
default_triple="${PB_TRIPLE:-"$default_repo-$default_carch-$default_target"}"

targets=("$HOME"/.local/share/bs/etc/default/target/*
         "${BS_TARGETDIR}/"*);

if [[ "$BS_DEBUG" ]]; then
  echo "\$targets: ${targets[@]}";
  echo "\$BS_TARGETDIR\[*\]: ${BS_TARGETDIR[*]}"
fi

[[ ${#targets[*]} -eq 0 ]] \
  && targets=("$HOME/.local/share/bs/target/$default_triple")

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

pacinfo_import() {
  pkgstr="$1"

  pacinfo="$(pacinfo "$pkgstr" <&-)"
  err=$?
     
  if [[ "$err" -eq 0 ]]; then
    local pkgbase=""
    local pkgrepo=""

    $(perl -e 'use v5.40; my (%matches) = $ARGV[0] =~ /(Base|Repository):\s+([a-z0-9\-]+)/g; say join "\n", map { "export pkg" . lc substr($_, 0, 4) . "=$matches{$_}" } keys %matches' "$pacinfo")
    
    local err=$?

    [[ -z "$pkgbase" ]] && [[ -z "$pkgrepo" ]] && return $err
    [[ "$err" -eq 0 ]] || return $err
    
    export pkgbase="$pkgbase"
    export pkgrepo="$pkgrepo"

    echo "$pkgrepo/$pkgbase" && return 0
  fi

  echo "Package not found in local database!"
  echo "Attempting to build using CLI and cached/remote PKGMETA repos..."
  echo "";

  export pkgbase="$pkgstr"

  echo "$pkgstr" && return 0
}

update_pkgbuild_repo() {
  #branches=($(git branch -a))
  git config --global --add safe.directory "$(pwd)"

  git reset --hard;
  git clean -f; 

  echo "Attempting to update PKGBUILD repo..."
  for branch in main master; do
    git pull origin "$branch" --rebase
    err=$?
    [[ "$err" -eq 0 ]] && break
  done
}

clone_aur_pkg() {
  local remoteuri
  local err=0

  echo "Attempting to clone '$pkg' from AUR.."

  git clone --bare \
    "$aur_repo_uri/${pkgstr}.git" \
    "$pkgstr"

  err=$?

  if [[ "$err" -eq 0 ]]; then 
    echo "$pkgstr" && return 0
  fi
  
  return $err
}

clone_custom_repo_remote() {
  local remoteuri="$(pacman_conf_reporemote "$pkgrepo")"
  local pacinierr=$?

  if [[ -n "$remoteuri" ]] && [[ $pacinierr -eq 0 ]]; then
    echo "Cloning '$pkg' from '$pkgrepo' PKGBUILD meta repo..."
    
    # Currently imagining $remoteuri as a git tree with $pkgstr as a subtree
    # rather than deal with submodules or the seemingly undocumented branch per
    # package format the Github AUR mirror currently uses
    git clone --bare "$remoteuri/$pkgstr.git" "$pkgstr"
  fi
  
  [[ $? -eq 0 ]] && pkg="$pkgstr" && return 0

  return $?
}

clone_arch_remote() {
  local pkgbase="$1"
  local pkgstr="$2"

  echo "Attempting to clone '$pkgbase' from Arch Gitlab..."

  git clone --bare \
    "$arch_pkgbuildrepo_uri/${pkgbase}.git" \
    "${pkgbase:-$pkgstr}"
  
  local err=$?
  
  [[ $err -ne 0 ]] && pkgctl repo clone --protocol=https \
    "${pkgbase:-$pkgstr}"

  err=$?
  
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
    --cargs="C,u,n${PB_CHROOTCLEAN:+,c}" \
    --margs="L,A,s,i${PB_MAKEPKG_CLEANALL:+,C,c}" --syncdeps --pkgver \
    --makepkg-conf="$makepkg_conf" --pacman-conf="$pacman_conf" \
    ${PB_TMPCHROOT:+--temp} ${PB_REBUILDALL:+-f} \
    -d universe --root "$AURDIT_ROOT/repo/${target:-"$CARCH"}" -c -D $CHROOT

  err=$?

  [[ $err -ne 0 ]] \
    && echo "$target $pkg $pkgstr $makepkg_conf $pacman_conf $err" \
    >> "pkgbuild.sh-error-$started.txt"

  sudo rm -r "/var/cache/pacman/pkg/"*

  [[ $err -ne 0 ]] \
    && echo "$target $pkg $pkgstr $makepkg_conf $pacman_conf $err" \
    >> "pkgbuild.sh-error-$started.txt"

  [[ $PB_DEBUG -ne 0 ]] || set +x
  return $err
}

enter_pkgbuilddir() {
  local pkg="$1"
  eval cd "$pkg" || return $?
  workdir=$(mktemp -d -p .)
  cd "$workdir"
  git clone "../../$(basename "$pkg")" .
  #cd "$(basename "$pkg")"
  return 0
}

exit_pkgbuilddir() {
  cd ../../ || return $?
  return 0
}

buildpkg_all_targets() {
  local pkg="$1"
  local pkgstr="$2";
  shift; shift;
  local targets+=("$@")

  for target in "${targets[@]}"; do
    makepkg_conf="$target/makepkg.conf"
    pacman_conf="$target/pacman.conf"
    
    if [[ ! -e $makepkg_conf ]] || [[ ! -e $pacman_conf ]]; then
      return 1
    fi

    target_name="$(basename "$target")"

    buildpkg "$pkg" "$pkgstr" "$makepkg_conf" "$pacman_conf" "$target_name"
    local err=$?
  done
}

addpkgmeta() {
  local pkgrepo="$1"
  local pkg="$2"
  local pkgstr="$3"
  local err=0

  local pkg="${pkg:-$pkgstr}"
  [[ -z "$pkg" ]] && return 1

  if [[ -n "$pkgrepo" ]]; then
    if [[ -n "${pkgrepo//*aur*/}" ]]; then
      clone_custom_repo_remote "$pkgrepo" "$pkg" "$pkgstr"
      [[ $? -eq 0 ]] && return 0;
    elif [[ -z "${pkgrepo//aur/}" ]]; then
      clone_aur_pkg "$pkgstr"
      [[ $? -eq 0 ]] && return 0;
      err=$?
    fi
  fi

  if [[ ! -d "$pkg" ]]; then
    clone_arch_remote "$pkg" "$pkgstr"
    [[ $? -eq 0 ]] && return 0

    clone_aur_pkg "$pkgstr"
    [[ $? -eq 0 ]] && return 0
  fi

  return $err
}

findpkg() {
  local pkgstr="$1"
  local pkgrepo="$2"
  
  pkg="$pkgstr"
  pkgsearch=($(pacsift --name "$pkg" --base "$pkg"))

  pkgfields=($(parse_repopkgstr "${pkgsearch[*]:0:1}"))
  pkgrepo=${pkgfields[*]:0:1}
  pkgstr=${pkgfields[*]:1:1}

  [[ -z "$pkgstr" ]] && ($(pacman -Syyqs "^$pkg\$"))

  #[[ -z "$pkgstr" ]] && pkgstr="$pkgrepo"

  pacinfo="$(pacinfo_import "$pkgstr")"

  pkgfields=($(parse_repopkgstr "$pacinfo"))
  pkgrepo=${pkgfields[*]:0:1}
  pkgstr=${pkgfields[*]:1:1}

  [[ -z "$pkgstr" ]] && pkgstr="$pkgrepo"

  if [[ ! -d "$pkg" ]]; then
    addpkgmeta "$pkgrepo" "$pkgstr" "$pkgstr"
  fi

  echo "$pkg"
  return ${?:-0}
}

parse_repopkgstr() {
  local pkg=$1
  #local repo=$2  

  local pkgrepo="${pkg%%/*}";
  local pkgstr="${pkg##"$pkgrepo/"}"

  if [[ -z "${pkg//$pkgrepo/}" ]]; then
    pkgrepo=""
  fi;

  echo "$pkgrepo"
  echo "${pkgstr:-$pkg}"
}

buildpkgs() {
  if [[ -n "$BS_SYNC" ]]; then
    echo "Updating package and file databases..."  
    sudo pacman -Syyu;
    sudo pacman -Fyy;
  fi

  for pkg in "$@"; do
    err=0
    echo "Working on '$pkg'..."

    pkgfields=($(parse_repopkgstr "$pkg"))
    pkgrepo=${pkgfields[*]:0:1}
    pkgstr=${pkgfields[*]:1:1}

    [[ -z "$pkgstr" ]] && pkgstr="$pkgrepo"

    pkgbase=$(findpkg "$pkgstr" "$pkgrepo")

    enter_pkgbuilddir "$pkgbase"

    [[ $? -ne 0 ]] && echo "Could not change directories to '$pkgbase'" \
       && continue

    update_pkgbuild_repo

    echo "Updating package source checksums..."
    [[ -n "$PB_UPDPKGSUMS" ]] && updpkgsums
  
    echo "Attempting to build '$pkgbase'..."

    [[ ${#targets[*]} -ne 0 ]] \
       && buildpkg_all_targets "$pkgbase" "$pkgstr" "${targets[@]}"

    err=$?
  
    [[ "$err" -eq 0 ]] && echo "Successfully built '$pkgbase'!!"
    
    exit_pkgbuilddir
  done
}

buildpkgs "$@"
