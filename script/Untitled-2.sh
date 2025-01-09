#!/usr/bin/env bash

[[ -n "$PB_DEBUG" ]] && set -x;
[[ -n "$PB_PKGSYNC" ]] && pacman -Syy;

arch_pkgbuildrepo_uri="https://gitlab.archlinux.org/archlinux/packaging/packages"

# Name is a misnomer I guess
epoch() {
  echo "$(date +%s)"
}

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

pacinfo_parse() {
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
    [[ $? -eq 0 ]] && break
  done
}

clone_aur_pkg() {
  remoteuri="$(pacman_conf_reporemote "$pkgrepo")"
  pacinierr=$?

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
  fi
  
  [[ $? -eq 0 ]] && pkg="$pkgstr" && exit 0

  exit $?
}

clone_custom_repo_remote() {
  remoteuri="$(pacman_conf_reporemote "$pkgrepo")"
  pacinierr=$?

  if [[ -n "$remoteuri" ]] && [[ $pacinierr -eq 0 ]]; then
    echo "Cloning '$pkg' from '$pkgrepo' PKGBUILD meta repo..."

    # I think I can do this in a git subtree or whatever the thing that
    # isn't submodules is called...
    git clone "$remoteuri/$pkgstr.git" "$pkgstr"
  else

  fi
  
  [[ $? -eq 0 ]] && pkg="$pkgstr" && exit 0

  exit $?
}

clone_arch_remote() {
      echo "Attempting to clone '$pkg' from Arch Gitlab..."
  
    git clone \
      "$arch_pkgbuildrepo_uri/${pkgstr}.git" \
      "$pkgstr"
}

for pkg in "$@"; do
  err=0
  (echo "Working on '$pkg'..."
  
   pkgrepo="${pkg%%/*}"
   pkgstr="${pkg##"$repo/"}"

   pkgsearch=($(pacman -Sqs "^$pkgstr\$"))
  
   if [[ -z "${pkgsearch[*]:0:1}" ]] || [[ $? -ne 0 ]]; then
     pacinfo_import "$pkgstr"
   else
     pkgstr="${pkgsearch[*]:0:1}"
   fi

   if [[ ! -d "$pkgstr" ]]; then
     if [[ -n "$pkgstr" ]] && [[ -n "${pkgrepo//*aur*/}" ]]; then
       
     elif [[ -z "${pkgrepo//aur/}" ]]; then
       echo "Attempting to clone '$pkg' from the AUR..."
       aur fetch --existing --rebase -r "$pkg"
       err=$?
       [[ $err -ne 0 ]] && >&2 && continue
    fi
  fi
  
  cd "$pkg";

  if [[ $? -ne 0 ]]; then
    echo "Could not change directories to '$pkg'" && continue
  fi

  update_pkgbuild_repo

  echo "Updating package source checksums..."
  updpkgsums
  
  echo "Attempting to build '$pkg'..."
  
  ( export SRCDEST="$SRCDEST/pkgbuild-$(epoch)";
    set -x

    aur build -v -f -S --cargs="C,u,n${PB_CHROOT_CLEAN:+,c}" \
     --margs="L,A,s,f,i${PB_MAKEPKG_CLEANALL:+,C,c}" --syncdeps --pkgver \
     --makepkg-conf=/etc/makepkg.conf --pacman-conf=/etc/pacman.conf \
     ${PB_TMPCHROOT:+--temp} ${PB_REBUILDALL:+-f} \
     -d universe --root "$AURDIT_ROOT/repo" -c -D $CHROOT
    
    set +x )

   [[ $? -eq 0 ]] && echo "Successfully built '$pkg'!!"
  
   cd .. )
done
