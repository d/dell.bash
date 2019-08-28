#!/bin/bash
# TODO: clang apt source
# TODO: docker apt source

set -e -u -o pipefail
shopt -s inherit_errexit

_main() {
	install_packages

	install_released_version_of_autoconf
}

install_released_version_of_autoconf() {
	local autoconf_prefix
	readonly autoconf_prefix=~/.opt/autoconf
	if [[ -x "${autoconf_prefix}/bin/autoreconf" ]]; then
		return 0
	fi

	local version src_url sig_url src sig key
	readonly version=2.69
	readonly src_url=http://ftp.gnu.org/gnu/autoconf/autoconf-${version}.tar.xz
	readonly sig_url=${src_url}.sig
	readonly src=~/Downloads/"$(basename $src_url)"
	readonly sig=${src}.sig

	# Eric Blake's signing key
	readonly key=A7A16B4A2527436A
	if gpg --list-public-key "${key}"; then
		true
	else
		gpg --keyserver keys.gnupg.net --recv-keys "${key}"
	fi
	curl --output "${src}" $src_url
	curl --output "${sig}" $sig_url
	gpg --verify "${sig}"

	local autoconf_src_dir
	readonly autoconf_src_dir=~/src/gnu/autoconf-${version}

	mkdir -vp ~/src/gnu
	tar xvf "${src}" -C "${autoconf_src_dir}"
	(
		cd "${autoconf_src_dir}"
		./configure --prefix "${autoconf_prefix}"
		make install
	)
}

install_packages() {
	local -a packages=(
		vim-gnome # or vim-gtk2 maybe?
		fish
		cmake
		ninja-build
		g++
		ccache
		libxerces-c-dev- # doesn't work well with orca
		git
		parallel
		clang-tidy-8
		clang-format-8
		pigz
		p7zip-full
		p7zip-rar
		rename
		patchelf
		shellcheck- # we want a later-than-apt version
		clang-8
		lld-8
		direnv
		tmux
	)
	sudo aptitude install -y "${packages[@]}"

	sudo snap install shellcheck shfmt
}

_main "$@"
