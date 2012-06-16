# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# EAPI 2 needed to run src_prepare
EAPI=2

# project is hosted on github.com, so git-2 is needed (git is deprecated)
inherit git-2 eutils

DESCRIPTION="MMD is a superset of the Markdown syntax (more syntax features & output formats)"
HOMEPAGE="http://http://fletcherpenney.net/multimarkdown"
EGIT_REPO_URI="git://github.com/fletcher/${PN}.git"
SRC_URI=""

LICENSE="GPL-2 MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"

# USE flags
IUSE="shortcuts perl-conversions latex xslt test"

# basic depenedencies
DEPEND=""
RDEPEND=""

# conditional dependencies
DEPEND="${DEPEND}
	test? ( dev-lang/perl app-text/htmltidy )"
RDEPEND="${RDEPEND}
	perl-conversions? ( dev-lang/perl )
	xslt? ( dev-libs/libxslt )
	latex? ( dev-lang/peg-multimarkdown-latex-support )"
# peg-multimarkdown-latex-support is is not included as git sub-module, it requires a separate git clone thus a separate pkg
if use test || use xslt || use perl-conversions ; then
	# we also need the sub-modules, this triggers them in git-2.eclass
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
		epatch "${FILESDIR}/${PN}-gentoo-xslt.patch" || die "Patching of XSLT scripts for ${PN} failed!"
	fi
	# rename a file to avoid an error when testing
	if use test && [ -f "MarkdownTest/MultiMarkdownTests/BibTex.text" ]; then
		mv "MarkdownTest/MultiMarkdownTests/BibTex.text" "MarkdownTest/MultiMarkdownTests/BibTeX.text" || \
			ewarn "Renaming of file BibTex.text to BibTeX.text failed"
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
					hasq test $FEATURES && die "Make ${test_phase} failed. See above for details."
					hasq test $FEATURES || eerror "Make ${test_phase} failed. See above for details."
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
		einfo "Done installing shortcuts for ${PN}"
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
		einfo "Done installing perl-conversion scripts for ${PN}"
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
		einfo "Done installing perl-conversion scripts for ${PN}"
	fi
}

pkg_postinst()
{
	einfo "${PN} was successfully installed."
	einfo ""
	einfo "Type \"${PN} -h\" or \"${PN} file.txt\" to start using it."
	use shortcuts && einfo "The following additional shortcuts were also installed: ${SHORTCUTS_LIST}."
	use shortcuts && einfo "The shortcut \"mmd\" was not installed due to known file collision with sys-fs/mtools on file /usr/bin/mmd"
	use perl-conversions && einfo "The following additional conversion shortcuts were also installed: ${PERLSCRIPTS_LIST}."
	use xslt && einfo "The following additional XSLT conversion shortcuts were also installed: ${XSLTSCRIPTS_LIST}."
	einfo ""
}

pkg_info()
{
	${ROOT}${DEST_DIR_EXE}/multimarkdown -v
}
