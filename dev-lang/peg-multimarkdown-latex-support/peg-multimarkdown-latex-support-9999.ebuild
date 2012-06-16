# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=0
inherit git-2

DESCRIPTION="Default templates to create certain types of LaTex documents with MultiMarkdown"
HOMEPAGE="http://http://fletcherpenney.net/multimarkdown"
EGIT_REPO_URI="git://github.com/fletcher/${PN}.git"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"

# USE flags
IUSE=""

# basic depenedencies
DEPEND="virtual/latex-base"

# post-depend: if this is installed first, then peg-mmd can run some tests
PDEPEND="${DEPEND} dev-lang/peg-multimarkdown"

# custom variables
LATEX_DIR="${ROOT}/usr/share/texmf/tex/latex"
DESTINATION_DIR="/usr/share/texmf/tex/latex/mmd"

pkg_setup()
{
	# find latex folder or fail
	[ -d "${LATEX_DIR}" ] || die "Package ${PN} cannot be installed. Missing LaTex folder in ${LATEX_DIR}"
}
src_install()
{
	# install latex support
	insinto ${DESTINATION_DIR}
	einfo "Installing default templates for LaTeX support to ${DESTINATION_DIR}/ ..."
	doins ./* || die "Installation of ${PN} failed!"
	einfo "Done installing latex templates by ${PN}"
}

pkg_info()
{
	einfo "Package ${PN} installed the following files to ${DESTINATION_DIR} :"
	einfo `ls ${DESTINATION_DIR}`
}
