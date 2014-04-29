# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
inherit games autotools

DESCRIPTION="Free Awale - The game of all Africa"
HOMEPAGE="http://www.nongnu.org/awale/"
SRC_URI="http://download.savannah.gnu.org/releases/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="dev-lang/tcl
	dev-lang/tk"
DEPEND="${RDEPEND}"

src_prepare() {
	# fix awale path in xawale.tcl
	sed -i "s:set JOUER.*$:set JOUER ${GAMES_BINDIR}/${PN}:" \
		src/xawale.tcl || die "sed xawale.tcl failed"
	# fix relative path to absolute
	sed -i "s:\`dirname \$\$0\`/../share:bash ${GAMES_DATADIR}:" \
		src/Makefile.am || die "sed failed"
	eautoreconf
}

src_configure() {
	egamesconf \
		--prefix="${ROOT}"/usr \
		--bindir="${GAMES_BINDIR}"
}

src_install() {
	emake DESTDIR="${D}" install
	dodoc AUTHORS ChangeLog NEWS README THANKS
	prepgamesdirs
}
