#!/bin/bash

set -e -u -o pipefail
shopt -s inherit_errexit

_main() {
	install_clang
	install_docker
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
	tar xvf "${src}" -C ~/src/gnu
	(
		cd "${autoconf_src_dir}"
		./configure --prefix "${autoconf_prefix}"
		make install
	)
}

install_packages() {
	local -a packages=(
		aptitude
		vim-gnome # or vim-gtk2 maybe?
		fish
		cmake
		ninja-build
		g++
		flex
		bison
		libzstd-dev
		libbz2-dev
		python-dev
		python-pip
		gdb
		rr
		m4
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
		docker-ce
	)
	sudo apt-get install -y "${packages[@]}"

	install_snaps shfmt shellcheck
}

install_snaps() {
	for p in "$@"; do
		sudo snap install --no-wait "${p}"
	done
}

install_clang() {
	add_apt_keyring https://apt.llvm.org/llvm-snapshot.gpg.key llvm.gpg 15CF4D18AF4F7421
	sudo cp llvm-toolchain.list /etc/apt/sources.list.d/llvm-toolchain.list
	sudo apt-get update
}

install_docker() {
	add_apt_keyring https://download.docker.com/linux/ubuntu/gpg docker.gpg "8D81803C0EBFCD88"
	sudo cp docker.list /etc/apt/sources.list.d/docker.list
	sudo apt-get update
}

add_apt_keyring() {
	local key_url keyring key_id
	key_url=$1
	keyring=$2
	key_id=$3

	if gpg --no-default-keyring --keyring /usr/share/keyrings/"${keyring}" --list-keys "${key_id}"; then
		true
	else
		curl -fsSL "${key_url}" | gpg --dearmor | sudo tee /usr/share/keyrings/"${keyring}" >/dev/null
	fi
}

_main "$@"
