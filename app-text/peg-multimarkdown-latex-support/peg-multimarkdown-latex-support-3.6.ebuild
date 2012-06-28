# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=2
inherit latex-package git-2

DESCRIPTION="Default templates to create certain types of LaTex documents with MultiMarkdown"
HOMEPAGE="http://http://fletcherpenney.net/multimarkdown"
SRC_URI=""

EGIT_REPO_URI="git://github.com/fletcher/${PN}.git"
EGIT_COMMIT="d615fce94c58bc9e9236dcfe353d5d26c3b8e616"

LICENSE="|| ( GPL-2 MIT )"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="virtual/latex-base"
PDEPEND="${DEPEND}"
RDEPEND="
	dev-texlive/texlive-latexextra
	dev-tex/glossaries
	dev-tex/xcolor
"

src_install()
{
	# install latex support
	insinto ${TEXMF}/tex/latex/${PN}
	doins * || die "Installation of $PN failed"
}
