# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit firefox-plugin

FFP_XPI_FILE="${P}-fx-linux"
DESCRIPTION="A test environment for Firefox OS as Firefox extension."
HOMEPAGE="https://people.mozilla.com/~myk/r2d2b2g/"
SRC_URI="https://ftp.mozilla.org/pub/mozilla.org/labs/r2d2b2g/r2d2b2g-1.1pre2-linux.xpi -> ${FFP_XPI_FILE}.xpi"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""
