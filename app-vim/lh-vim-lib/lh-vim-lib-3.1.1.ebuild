# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
VIM_PLUGIN_VIM_VERSION="7.3"

inherit vim-plugin

DESCRIPTION="vim plugin: a VimL library for script writers"
HOMEPAGE="http://code.google.com/p/lh-vim/wiki/lhVimLib"
SRC_URI="http://lh-vim-downloads.googlecode.com/files/lh-vim-lib-3.1.1.vmb.bz2"
LICENSE="GPL-3"
KEYWORDS="~amd64"

# VIM_PLUGIN_HELPFILES="lh-vim-lib-addon-info.txt"
VIM_PLUGIN_HELPFILES=""
VIM_PLUGIN_HELPTEXT=""
VIM_PLUGIN_HELPURI=""
VIM_PLUGIN_MESSAGES=""

S="${WORKDIR}"

src_unpack() {
	vim -c 'so %' -c 'q' lh-vim-lib-3.1.1.vmb || die "vimball import failed"
}
