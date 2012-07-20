# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="3"
PYTHON_DEPEND="*"
PYTHON_USE_WITH="threads"

inherit apache-module eutils python mercurial

DESCRIPTION="An Apache2 module for running Python WSGI applications."
HOMEPAGE="http://code.google.com/p/modwsgi/"
EHG_REPO_URI="https://code.google.com/p/modwsgi"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND=""
RDEPEND=""

APACHE2_MOD_CONF="70_${PN}"
APACHE2_MOD_DEFINE="WSGI"

DOCFILES="README"

need_apache2
S="${WORKDIR}/${PN}"

src_configure() {
	cd "${S}/${PN}"
	econf --with-apxs=${APXS}
}

src_compile() {
	cd "${S}/${PN}"
	default
}

src_install()
{
	cd "${S}/${PN}"
	emake DESTDIR="${D}" install || die "Install failed"
}
