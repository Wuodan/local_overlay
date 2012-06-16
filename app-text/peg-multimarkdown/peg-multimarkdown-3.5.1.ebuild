# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

inherit eutils toolchain-funcs vcs-snapshot

DESCRIPTION="An implementation of MultiMarkdown in C, using a PEG grammar"
HOMEPAGE="https://github.com/fletcher/peg-multimarkdown"
SRC_URI="https://github.com/fletcher/${PN}/tarball/${PV} -> ${P}.tar.gz"

LICENSE="|| ( GPL-2 MIT )"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

src_prepare() {
	epatch \
		"${FILESDIR}/cflags.patch" \
		"${FILESDIR}/peg-cflags.patch"
}

src_compile() {
	emake CC="$(tc-getCC)"
}

src_install() {
	exeinto usr/bin
	doexe multimarkdown
}
