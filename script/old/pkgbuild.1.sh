#!/usr/bin/env bash

pkgqueue=("$@")
#[[ ${WORKING_CHDIR:-$(date +%s)} ]]
 
for pkg in "${pkgqueue[@]}"; do
   [[ ! -d "$pkg" ]] \
     && [[ "${IMPORT_PKGBUILD:-0}" -eq 1 ]] \
     && [[ -n "$IMPORT_DIR" ]] && [[ -d "$IMPORT_DIR" ]] \
     && cp -vaf "$IMPORT_DIR/"*"$pkg"* $BS_ROOT/cgit/packaging/packages/work;
    
   [[ ! -d "$pkg" ]] && pkgctl repo clone --protocol=https "$pkg"
    
   cd "$pkg" || continue
  
   git config --global merge.tool meld
   makepkg --printsrcinfo > .SRCINFO
  
   git add PKGBUILD .SRCINFO
   git commit -S -m '...'
   git pull --rebase
   
   while [[ "$(git rebase --continue)" -ne 0 ]]; do
   #while [[ "$?" -ne 0 ]]; do 
     git mergetool
     #git rebase --continue
   done
  
   nvim PKGBUILD
  
   makechrootpkg -Cun -r"$BS_CHROOTDIR/$" -lvdpaustuff - -Lisf

   ( setopt CSH_NULL_GLOB; BS_CLOBBER=1 \  
     bs-repoadd $BS_ROOT/pkgdest/*-{any,x86_64_v3}.pkg.tar.zst )

   paccache -rk0
   rm -r $BS_ROOT/pkgdest/*
   cd ..
done
