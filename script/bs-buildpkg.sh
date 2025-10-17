#!/usr/bin/env ksh
[[ "${DEBUG:-0}" -ne 0 ]] && set -x

pkgs=("$@")
user="$(whoami)"
targetcarch="${TARGET_CARCH:-${CARCH:-$(uname -m)}}"
chroot="${CHROOT:-/var/lib/bs/chroot/$targetcarch}"

repo="${BS_REPO:-universe}"
repodb="$BS_REPOROOT/$repo/os/$BS_TARGET/$repo.db.tar.zst"
gpgpubid="${BS_GPGID:-${BS_GPGFPR:-${BS_GPG_PUBID:-${GPGKEYID}}}}"

hostfqdn=$(
	perl -Mv5.40 -MNet::Domain \
		-e 'say Net::Domain::hostfqdn || Net::Domain::domainname;'
)

pkginstr="${*}"
echo -e "▶ Building the following packages:\n$pkginstr\n"

if [[ -z "$WKCHROOT" ]] || [[ ! -d "$WKCHROOT" ]]; then
	WKCHROOT="$user@$hostfqdn-$1+${#@}-$(date +%s)"
fi

say() {
	for msg in "$@"; do
		echo "▶ $msg"
	done
}

warn() {
	perl -Mv5.40 -Mutf8 -e 'say STDERR "❌️ $_" for (<>)' "$@"
}

err() {
	status="$?"
	msg=("$@")
	warn "${msg[@]}" && exit $status
}

success() {
	perl -Mv5.40 -Mutf8 -e 'say "◯ $_" for (<>)' "$@"
}

moveclone() {
	for pkg in "$@"; do
		[[ -d "/bs/cgit/pennylinux/pkgbuild/work/$pkg" ]] ||
			(
				echo "▶ Copying package from import directory '$IMPORTDIR'."
				cp -vaf "/bs-old/pkgbuild.1/$pkg" \
					"/bs/cgit/pennylinux/pkgbuild/work" &&
					return 0
			)

		[[ -d "/bs/cgit/pennylinux/pkgbuild/work/$pkg" ]] ||
			(echo "▶ Cloning official repo:" &&
				pkgctl repo clone --protocol https "$pkg")
	done
}

rebasebuild() {
	pkgs=("$@")

	for pkg in "${pkgs[@]}"; do
		cd "$pkg" || continue

		. .SRCINFO
		commit="${source//*commit=/}/}"

		[[ -n "${MERGETOOL}" ]] && git config merge.tool "$MERGETOOL"

		echo "▶ Updating .SRCINFO and committing changes since last pull..."
		makepkg --printsrcinfo >.SRCINFO
		git add PKGBUILD .SRCINFO
		git commit -S -m '...'

		echo "▶ Rebasing. You will be prompted if there are any conflicts."
		git pull --rebase
		rebaseexit="$?"

		while [[ "$rebaseexit" -ne 0 ]]; do
			git mergetool
			git rebase --continue
			rebaseexit="$?"
		done

		echo "▶ Opening current PKGBUILD for viewing and final edits. Please review it closely!\m"
		nvim PKGBUILD

		. .SRCINFO
		commit_postrebase="${source//*commit=/}/}"

		if [[ -z "$(perl -Mv5.40 -e \
			'say (s/.*commit=([a-z0-9]{41})/$1/r)[0]')" ]]; then
			echo "▶ New commit detected in source array URL!"
			echo "▶ Updating checksums..."
			updpkgsums
		fi

		echo "▶ Building '$pkg' in '$chroot/$WKCHROOT'"
		makechrootpkg -Cun -r"$chroot" ${WKCHROOT:+-l"$WKCHROOT"} - -Lisf

		echo "▶ Signing and adding '$pkg' to '$BS_REPO'"
		(
			setopt CSH_NULL_GLOB
			bs-repoadd \
				"${PKGDEST:-$BS_ROOT/pkgdest}"/*-{any,"$targetcarch"}.pkg.tar.zst
		)

		echo "▶ Removing copied artifacts and pacman cache (to avoid duplicate packages from the official repos)"
		paccache -rk0
		rm -r "${PKGDEST:-$BS_ROOT/pkgdest}"/*

		cd ..
	done
}

moveclone "${pkgs[@]}"
rebasebuild "${pkgs[@]}"
