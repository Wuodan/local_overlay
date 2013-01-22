# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

DESCRIPTION="Utils for Kernel Support for miscellaneous Binary Formats"
HOMEPAGE="https://www.kernel.org/doc/Documentation/binfmt_misc.txt"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
# IUSE="dos em86 java wine"
IUSE="dos java wine"

DEPEND=""
RDEPEND="${DEPEND}
	dos? (||
		games-emulation/dosbox
		app-emulation/dosemu )
	)
	wine? ( app-emulation/wine )"

S="${WORKDIR}"
src_prepare(){
	cp ""${FILESDIR}/*-${PV}* .
}

pkg_setup(){
	# check for kernel (module) "binfmt_misc"
	# TODO
	return 0
}

src_compile(){
	if [ use java ]; then
		# TODO: correct this
		gcc -O2 -o javaclassname javaclassname.c
	fi
}

src_test(){
	if [ use java ]; then
		javac HelloWorld.java || die "Failed on: javac HelloWorld.java"
		chmod 755 HelloWorld.class die "Failed on: chmod 755 HelloWorld.class"
		./HelloWorld.class || die "Failed to execute HelloWorld.class"
		[ "$(./HelloWorld.class)" = 'Hello World!' ] || die "Hello World Test failed!"
	fi
}

src_install(){
	mount -t binfmt_misc none /proc/sys/fs/binfmt_misc \
		|| die "Mounting /proc/sys/fs/binfmt_misc failed!"
	if [ use dos ]; then
		# TODO: dosexec does not exist in gentoo
		# find out how to do this with dosbox/dosemu
		echo ':DEXE:M::\x0eDEX::/usr/bin/dosexec:' \
			> /proc/sys/fs/binfmt_misc/register \
			|| die "Failed to register dosexec"
	fi
#	if [ use em86 ]; then
#		echo ':i386:M::\x7fELF\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x03:\xff\xff\xff\xff\xff\xfe\xfe\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfb\xff\xff:/bin/em86:' \
#			> /proc/sys/fs/binfmt_misc/register \
#			|| die "Failed to register i386"
#		echo ':i486:M::\x7fELF\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x06:\xff\xff\xff\xff\xff\xfe\xfe\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfb\xff\xff:/bin/em86:' \
#			> /proc/sys/fs/binfmt_misc/register \
#			|| die "Failed to register i486"
#	fi
	if [ use java ]; then
		exeinto /usr/bin
		doexe javaclassname
		doexe jarwrapper
		doexe javawrapper
	fi
	if [ use wine ]; then
		echo ':DOSWin:M::MZ::/usr/bin/wine:'
			> /proc/sys/fs/binfmt_misc/register \
			|| die "Failed to register dosexec"
	fi
}
