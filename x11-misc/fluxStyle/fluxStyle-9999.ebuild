# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4
PYTHON_COMPAT="python2_7"
inherit git-2 python-distutils-ng # python

DESCRIPTION="Style manager for the fluxbox window manager"
HOMEPAGE="https://github.com/michaelrice/fluxStyle"
SRC_URI=""
EGIT_REPO_URI="git://github.com/michaelrice/${PN}.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="dev-lang/python"
# RDEPEND="${DEPEND}"
RDEPEND="
	>=dev-python/pygtk-2.6
	>=gnome-base/libglade-2.4.2"

# pkg_setup() {
	# python_set_active_version 2
	# python_pkg_setup
# }

# src_prepare() {
	# python_convert_shebangs 2 ${PN}
	# chmod +x setup.py || die "chmod failed"
# }

src_compile() {
	# python-distutils-ng_src_compile
	return
}

# src_install() {
	# _python-distutils-ng_run_for_impl 2 setup.py install
	# python-distutils-ng_src_install
	# # emake DESTDIR="${D}" install

	# dodoc ChangeLog LICENSE README
# }

# pkg_postinst() {
	# python_mod_optimize $PN
# }

# pkg_postrm() {
	# python_mod_cleanup $PN
# }
