# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/seabios/seabios-1.6.3.ebuild,v 1.5 2012/01/28 15:18:13 phajdan.jr Exp $

EAPI=4

PYTHON_DEPEND="2"

#BACKPORTS=1

if [[ ${PV} = *9999* || ! -z "${EGIT_COMMIT}" ]]; then
	EGIT_REPO_URI="git://git.seabios.org/seabios.git"
	GIT_ECLASS="git-2"
	SRC_URI=""
else
	SRC_URI="http://www.linuxtogo.org/~kevin/SeaBIOS/${PN}-${PV}.tar.gz
	${BACKPORTS:+http://dev.gentoo.org/~cardoe/distfiles/${PN}-${PV}-bp-${BACKPORTS}.tar.bz2}"
fi

inherit ${GIT_ECLASS} python

if [[ ${PV} != *9999* ]]; then
	KEYWORDS="~amd64"
fi

DESCRIPTION="Open Source implementation of a 16-bit x86 BIOS"
HOMEPAGE="http://www.seabios.org"

LICENSE="LGPL-3 GPL-3"
SLOT="0"
IUSE="debug-serial-port thread-optionroms"

RDEPEND="
	!app-emulation/qemu
	!<=app-emulation/qemu-kvm-0.15.0"

pkg_setup() {
	python_set_active_version 2
}

src_prepare() {
	if [[ -z "${EGIT_COMMIT}" ]]; then
		sed -e "s/VERSION=.*/VERSION=${PV}/" \
			-i "${S}/Makefile"
	else
		sed -e "s/VERSION=.*/VERSION=${PV}_pre${EGIT_COMMIT}/" \
			-i "${S}/Makefile"
	fi
}

src_configure() {
	if use debug-serial-port || use thread-optionroms; then
		emake defconfig || die "Creating default config for ${PN} failed"
		use debug-serial-port && \
			sed 's/^# CONFIG_DEBUG_SERIAL is not set$/CONFIG_DEBUG_SERIAL=y\nCONFIG_DEBUG_SERIAL_PORT=0x3f8/' \
				-i .config
		use thread-optionroms && \
			sed 's/^# CONFIG_THREAD_OPTIONROMS is not set$/CONFIG_THREAD_OPTIONROMS=y/' \
				-i .config
	fi
}

src_compile() {
	emake out/bios.bin
#	emake out/vgabios.bin
}

src_install() {
	insinto /usr/share/seabios
	doins out/bios.bin
#	doins out/vgabios.bin
}
