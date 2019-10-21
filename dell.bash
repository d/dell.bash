#!/bin/bash

set -e -u -o pipefail
shopt -s inherit_errexit

_main() {
	add_ppa
	install_clang
	install_docker
	install_cmake
	install_packages
	rm_cmake_one_off_keyring
	add_user_to_docker_group
	install_git_duet

	install_released_version_of_autoconf
	git_global_config
}

git_global_config() {
	git config --global commit.verbose true
	git config --global protocol.version 2
	git config --global submodule.fetchJobs 0
}

add_ppa() {
	sudo add-apt-repository --yes --no-update ppa:git-core/ppa
	sudo apt-add-repository --yes --no-update ppa:fish-shell/release-3
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
	wget --output-document "${src}" $src_url
	wget --output-document "${sig}" $sig_url
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
		vim-gtk3
		fish
		# build tools
		ccache
		cmake
		kitware-archive-keyring
		g++
		g++-8
		ninja-build

		# postgres / greenplum dependencies
		bison
		flex
		libapr1-dev
		libbz2-dev
		libcurl4-openssl-dev
		libevent-dev
		libreadline-dev
		libzstd-dev
		openssh-server
		python-dev
		python-pip
		zlib1g-dev
		# dev tools
		bear
		direnv
		docker-ce
		gdb
		git
		jq
		libxerces-c-dev- # doesn't work well with orca
		m4
		parallel
		rr
		shellcheck- # we want a later-than-apt version
		tmux

		# LLVM
		clang-9
		clang-format-9
		clang-tidy-9
		lld-9

		# utilities
		p7zip-full
		p7zip-rar
		patchelf
		pigz
		rename
		squid-deb-proxy-client
	)
	sudo apt-get update -q
	sudo apt-get install -y "${packages[@]}"

	install_snaps shfmt shellcheck
}

install_snaps() {
	for p in "$@"; do
		sudo snap install --no-wait "${p}"
	done
}

install_apt_list_file() {
	local sourcelist
	sourcelist=$1

	sudo cp "${sourcelist}" /etc/apt/sources.list.d/"${sourcelist}"
	sudo apt-get --option Dir::Etc::SourceParts=- --option Dir::Etc::SourceList=sources.list.d/"${sourcelist}" update
}

install_clang() {
	add_apt_keyring https://apt.llvm.org/llvm-snapshot.gpg.key llvm.gpg 15CF4D18AF4F7421
	install_apt_list_file llvm-toolchain.list
}

install_docker() {
	add_apt_keyring https://download.docker.com/linux/ubuntu/gpg docker.gpg "8D81803C0EBFCD88"
	install_apt_list_file docker.list
}

add_apt_keyring() {
	local key_url keyring key_id
	key_url=$1
	keyring=$2
	key_id=$3

	if gpg --no-default-keyring --keyring /usr/share/keyrings/"${keyring}" --list-keys "${key_id}"; then
		true
	else
		wget --output-document - "${key_url}" | gpg --dearmor | sudo tee /usr/share/keyrings/"${keyring}" >/dev/null
	fi
}

add_user_to_docker_group() {
	sudo adduser "${USER}" docker
}

install_cmake() {
	if [ installed = "$(dpkg-query --show --showformat '${db:Status-status}' kitware-archive-keyring)" ]; then
		true
	else
		wget --output-document - https://apt.kitware.com/keys/kitware-archive-latest.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/kitware-archive-latest.gpg >/dev/null
	fi

	sudo tee /etc/apt/sources.list.d/cmake.list >/dev/null <<<'deb https://apt.kitware.com/ubuntu/ bionic main'
	sudo apt-get --option Dir::Etc::SourceParts=- --option Dir::Etc::SourceList=sources.list.d/cmake.list update
}

rm_cmake_one_off_keyring() {
	sudo rm -vf /etc/apt/trusted.gpg.d/kitware-archive-latest.gpg
}

latest_jq_download_url() {
	wget --output-document - https://api.github.com/repos/git-duet/git-duet/releases/latest |
		jq --raw-output '.assets | map(select(.name == "linux_amd64.tar.gz")) | .[].browser_download_url'
}

install_git_duet() {
	local jq_url

	type -p git-duet && return 0
	jq_url=$(latest_jq_download_url)

	wget --output-document - "${jq_url}" | sudo tar xzv -C /usr/local/bin
}

_main "$@"
