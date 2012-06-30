# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/seabios/seabios-1.7.0.ebuild,v 1.1 2012/06/28 15:09:36 cardoe Exp $

EAPI=4

PYTHON_DEPEND="2"

inherit python

#BACKPORTS=1

if [[ ${PV} = *9999* || ! -z "${EGIT_COMMIT}" ]]; then
	EGIT_REPO_URI="git://git.seabios.org/seabios.git"
	inherit git-2
	KEYWORDS=""
	SRC_URI=""
else
	KEYWORDS="~amd64"
	SRC_URI="http://www.linuxtogo.org/~kevin/SeaBIOS/${PN}-${PV}.tar.gz
	${BACKPORTS:+http://dev.gentoo.org/~cardoe/distfiles/${PN}-${PV}-bp-${BACKPORTS}.tar.bz2}"
fi

echo "${SRC_URI}"

DESCRIPTION="Open Source implementation of a 16-bit x86 BIOS"
HOMEPAGE="http://www.seabios.org"

LICENSE="LGPL-3 GPL-3"
SLOT="0"
IUSE="debug-serial-port thread-optionroms"

DEPEND=""
RDEPEND="${DEPEND}
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
		# -j1 is a hack to prevent this warning with more then 1 job:
		# jobserver unavailable: using -j1.  Add `+' to parent make rule.
		emake -j1 defconfig || die "Creating default config for ${PN} failed"
		if use debug-serial-port; then
			sed 's/^# CONFIG_DEBUG_SERIAL is not set$/CONFIG_DEBUG_SERIAL=y\nCONFIG_DEBUG_SERIAL_PORT=0x3f8/' \
				-i .config
		fi
		if use thread-optionroms; then
			sed 's/^# CONFIG_THREAD_OPTIONROMS is not set$/CONFIG_THREAD_OPTIONROMS=y/' \
				-i .config
		fi
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
