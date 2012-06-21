# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=2
inherit latex-package git-2

DESCRIPTION="Default templates to create certain types of LaTex documents with MultiMarkdown"
HOMEPAGE="http://http://fletcherpenney.net/multimarkdown"
SRC_URI=""

EGIT_REPO_URI="git://github.com/fletcher/${PN}.git"

LICENSE="|| ( GPL-2 MIT )"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

# These are the dependencies to create the peg-multimarkdown docu.
# More might be needed, please report is something is missing
DEPEND="
	virtual/latex-base
	dev-texlive/texlive-latexextra
	dev-tex/glossaries
	dev-tex/xcolor
"
# post-depend: if this is installed first, then peg-mmd can run some tests
# some files are also needed later to create docu
PDEPEND="${DEPEND} ${CATEGORY}/peg-multimarkdown[latex]"
RDEPEND="${PDEPEND}"

src_install()
{
	# install latex support
	insinto ${TEXMF}/tex/latex/${PN}
	doins * || die "Installation of $PN failed"
}
