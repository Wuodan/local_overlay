# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libXinerama/libXinerama-1.1.2.ebuild,v 1.8 2012/07/12 17:49:26 ranger Exp $

EAPI=4
inherit xorg-2

DESCRIPTION="X.Org Xinerama library"

KEYWORDS="~alpha amd64 arm hppa ~ia64 ~mips ppc ppc64 ~s390 ~sh ~sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE=""

RDEPEND="x11-libs/libX11
	x11-libs/libXext
	x11-proto/xextproto
	>=x11-proto/xineramaproto-1.2"
DEPEND="${RDEPEND}"

src_prepare()
{
	# disable Werror
	# sed -i 's/^found="no"$/found="yes"/' configure || die "sed failed"
	xorg-2_src_prepare
}

src_compile()
{
	# define variables to disable Werror
	xorg_testset_unknown_warning_option="no"
	xorg_testset_unused_command_line_argument="no"
	# todo check nonnull (is unconditional)
	# init-self (same)
	# main
	# missing braces
	# sequence-point
	# return-type
	found="yes"
	xorg-2_src_compile
}
