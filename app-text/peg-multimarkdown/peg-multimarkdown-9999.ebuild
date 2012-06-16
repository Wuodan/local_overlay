# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=2

inherit git-2 eutils

DESCRIPTION="MMD is a superset of the Markdown syntax (more syntax features & output formats)"
HOMEPAGE="http://http://fletcherpenney.net/multimarkdown"
SRC_URI=""

EGIT_REPO_URI="git://github.com/fletcher/${PN}.git"
EPATCH_SOURCE="${FILESDIR}"

LICENSE="|| ( GPL-2 MIT )"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="shortcuts perl-conversions latex xslt test"

DEPEND=""
RDEPEND=""

DEPEND="${DEPEND}
	test? ( dev-lang/perl app-text/htmltidy )"
RDEPEND="${RDEPEND}
	perl-conversions? ( dev-lang/perl )
	xslt? ( dev-libs/libxslt )
	latex? ( ${CATEGORY}/${PN}-latex-support )"
# peg-multimarkdown-latex-support is is not included as git sub-module, it requires a separate git clone thus a separate pkg
if use test || use xslt || use perl-conversions ; then
	EGIT_HAS_SUBMODULES="Y"
fi

# custom variables
DEST_DIR_EXE="/usr/bin"
DEST_DIR_XSLT_TEMPL="/usr/share/${PN}/XSLT/"
# known file collision with sys-fs/mtools on file /usr/bin/mmd
# this is not fatal, the script is only a simple shortcut, so we just skip the
# file ... mmd2all  mmd2pdf are also excluded (todo re-test them)
SHORTCUTS_LIST="mmd2tex mmd2opml mmd2odf"
PERLSCRIPTS_LIST="mmd2RTF.pl mmd2XHTML.pl mmd2LaTeX.pl mmd2OPML.pl mmd2ODF.pl table_cleanup.pl mmd_merge.pl"
XSLTSCRIPTS_LIST="mmd-xslt mmd2tex-xslt opml2html opml2mmd opml2tex"
# prep_tufte.sh is not included, it would require perl and seems old

src_prepare()
{
	if use xslt; then
		einfo "XSLT support requires patching of some scripts (they must know where the XSLT templates are)"
		epatch "${PN}-gentoo-xslt.patch" || die "Patching of XSLT scripts for ${PN} failed!"
	fi
	# rename a file to avoid an error when testing
	if use test && [ -f "MarkdownTest/MultiMarkdownTests/BibTex.text" ]; then
		einfo "Renaming file BibTex.text to BibTeX.text ..."
		mv "MarkdownTest/MultiMarkdownTests/BibTex.text" "MarkdownTest/MultiMarkdownTests/BibTeX.text"
	fi
}

src_test()
{
	einfo "Now running tests for package ${PN}"
	einfo "It is considered \"normal\" for some tests to fail, but at least one should pass ..."
	# the Makefile does not have a check-target, but let's leave it in here
	for test_phase in check test mmd-test compat-test latex-test ; do
		# only run the latex test with latex use flag
		if [ "$test_phase" != "latex-test" ] || use latex ; then
			if emake -j1 $test_phase -n &> /dev/null; then
				einfo ">>> Test phase 2 [${test_phase}]: ${CATEGORY}/${PF}"
				if ! emake -j1 $test_phase; then
					has test $FEATURES && die "Make ${test_phase} failed. See above for details."
					has test $FEATURES || eerror "Make ${test_phase} failed. See above for details."
				fi
			fi
		fi
	done
	einfo "Done running tests for package ${PN}"
}

src_install()
{
	# install main binary
	insinto ${DEST_DIR_EXE}
	einfo "Installing multimarkdown binary to ${DEST_DIR_EXE}/multimarkdown ..."
	dobin multimarkdown || die "Install failed"

	# USE flag based installation
	# install shortcuts
	if use shortcuts ; then
		einfo "Installing shortcuts for ${PN}"
		exeinto ${DEST_DIR_EXE}
		for file in ${SHORTCUTS_LIST}; do
			# einfo "Installing ${file} to ${DEST_DIR_EXE}/${file} ..."
			doexe scripts/${file} || ewarn "Installation of script ${file} failed!"
		done
	fi

	# install perl-conversion scripts
	if use perl-conversions ; then
		einfo "Installing perl-conversion scripts for ${PN}"
		exeinto ${DEST_DIR_EXE}
		for file in ${PERLSCRIPTS_LIST}; do
			local file_path=`find Support/ -name "${file}"`
			# einfo "Installing ${file} to ${DEST_DIR_EXE}/${file} ..."
			doexe "${file_path}" || die "Installation of script ${file} failed!"
		done
	fi

	# install latex support
	# nothing to do, it's all in the plugin pkg

	# install xslt support
	if use xslt ; then
		einfo "Installing XSLT templates for ${PN} to ${DEST_DIR_XSLT_TEMPL}"
		insinto ${DEST_DIR_XSLT_TEMPL}
		doins Support/XSLT/* || die "Installation of XSLT templates failed!"
		einfo "Installing XSLT scripts for ${PN}"
		exeinto ${DEST_DIR_EXE}
		for file in ${XSLTSCRIPTS_LIST}; do
			local file_path=`find Support/ -name "${file}"`
			# einfo "Installing ${file} to ${DEST_DIR_EXE}/${file} ..."
			doexe ${file_path} || die "Installation of script ${file} failed!"
		done
	fi
}

pkg_postinst()
{
	elog ""
	elog "*** ${PN} was successfully installed. ***"
	elog "Type \"${PN} -h\" or \"${PN} file.txt\" to start using it."
	if use shortcuts; then
		elog "The following additional shortcuts were also installed:"
		elog "${SHORTCUTS_LIST}."
		elog "The shortcut \"mmd\" was not installed due to known file"
		elog "collision with sys-fs/mtools on file /usr/bin/mmd"
	fi
	if use perl-conversions; then
		elog "The following additional conversion shortcuts were also installed:"
		elog "${PERLSCRIPTS_LIST}"
	fi
	if use xslt; then
		elog "The following additional XSLT conversion shortcuts were also installed:"
		elog "${XSLTSCRIPTS_LIST}."
	fi
	elog ""
}

pkg_info()
{
	einfo "{ROOT}${DEST_DIR_EXE}/multimarkdown -v"
}
