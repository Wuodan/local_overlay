# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=0
inherit git-2

DESCRIPTION="Default templates to create certain tupes of LaTex documents with MultiMarkdown"
HOMEPAGE="http://http://fletcherpenney.net/multimarkdown"
EGIT_REPO_URI="git://github.com/fletcher/peg-multimarkdown-latex-support.git"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

# USE flags
IUSE=""

# basic depenedencies
DEPEND=""
RDEPEND="${DEPEND} dev-lang/peg-multimarkdown"

# custom variables
LATEX_FOLDER="/usr/share/texmf/tex/latex"
DESTINATION_DIR="${LATEX_FOLDER}/mmd"

src_install()
{
	# install latex support
	# find latex folder or fail
	[ -d ${LATEX_FOLDER} ] || die "Package ${PN} cannot be installed. Missing LaTex folder in ${LATEX_FOLDER}"
	insinto ${DESTINATION_DIR}
	einfo "Installing default templates for LaTeX support to ${ROOT}${DESTINATION_DIR}/ ..."
	doins * || die "Installation of ${PN} failed!"
	einfo "Done installing latex templates by ${PN}"
}

pkg_info()
{
	einfo "Package ${PN} will install the following files to ${DESTINATION_FOLDER} :"
	einfo `ls`
}
