#!/bin/bash
# TODO: clang apt source
# TODO: docker apt source

_main() {
	install_packages
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
	clang-tidy-6.0
	clang-format-6.0
	pigz
	p7zip-full
	p7zip-rar
	rename
	patchelf
	shellcheck- # we want a later-than-apt version
	clang-6.0
	lld-6.0
	direnv
	)
	sudo aptitude install -y "${packages[@]}"
}

# TODO: extract shellcheck probably from Docker Hub?

_main "$@"
