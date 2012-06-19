# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=2

inherit git-2 eutils

DESCRIPTION="MMD is a superset of the Markdown syntax (more syntax features & output formats)"
HOMEPAGE="http://http://fletcherpenney.net/multimarkdown"
SRC_URI=""

EGIT_REPO_URI="git://github.com/fletcher/${PN}.git"

LICENSE="|| ( GPL-2 MIT )"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="shortcuts doc perl-conversions latex xslt test"

DEPEND=""
RDEPEND=""

DEPEND="${DEPEND}
	doc? (
		dev-lang/perl
		latex? (
			dev-tex/latexmk
		)
	)
	test? (
		dev-lang/perl
		app-text/htmltidy
	)"
RDEPEND="${RDEPEND}
	perl-conversions? ( dev-lang/perl )
	xslt? ( dev-libs/libxslt )
	latex? ( ${CATEGORY}/${PN}-latex-support )
"
# peg-multimarkdown-latex-support is is not included as git sub-module
# it requires a separate git clone thus a separate pkg
if use test || use xslt || use perl-conversions || use doc; then
	EGIT_HAS_SUBMODULES="Y"
fi

# custom variables
DEST_DIR_EXE="/usr/bin"
DEST_DIR_XSLT_TEMPL="/usr/share/${PN}/XSLT/"

# known file collision with sys-fs/mtools on file /usr/bin/mmd
# this is not fatal, the script is only a simple shortcut, so we just skip the
# file ... mmd2all  mmd2pdf are also excluded (todo re-test them)
SHORTCUTS_LIST="mmd2tex mmd2opml mmd2odf"

# mmd2RTF.pl : not included. RTF support is not official
# and would use "Apples textutil package" ...
PERLSCRIPTS_LIST="mmd2XHTML.pl mmd2LaTeX.pl mmd2OPML.pl mmd2ODF.pl table_cleanup.pl mmd_merge.pl"

# prep_tufte.sh is not included, it would require perl and seems old
XSLTSCRIPTS_LIST="mmd-xslt mmd2tex-xslt opml2html opml2mmd opml2tex"

src_prepare()
{	# ./Makefile patches ./peg-0.1.4/Makefile
	# this does not work if the Makefile was already patched
	# so this step from Makefile is done here
	# (easier then patching .patch file)
	cp -r peg-0.1.4 peg; \
	epatch -p1 peg-memory-fix.patch; \
	epatch -p1 peg-exe-ext.patch || die "Patching of ${PN} failed!"
	# now patch cflags
	epatch "${FILESDIR}/${P}-cflags.patch"

	if use xslt; then
		einfo "XSLT support requires patching of some scripts (path to XSLT templates)"
		epatch "${FILESDIR}/${P}-xslt.patch" || die "Patching of XSLT scripts for ${PN} failed!"
	fi

	if use doc; then
		epatch "${FILESDIR}/${P}-doc.patch" || die "Patching of Makefile for ${PN} failed!"
	fi
	# rename a file to avoid an error when testing
	if use test && [ -f "MarkdownTest/MultiMarkdownTests/BibTex.text" ]; then
		einfo "Renaming file BibTex.text to BibTeX.text ..."
		mv "MarkdownTest/MultiMarkdownTests/BibTex.text" "MarkdownTest/MultiMarkdownTests/BibTeX.text"
	fi
}

src_compile() {
	if [ -f Makefile ] || [ -f GNUmakefile ] || [ -f makefile ]; then
		emake || die "emake failed"
		# compile documentation
		if use doc; then
			einfo "Compiling documentation ..."
			emake docs || die "emake docs failed!"
			if use latex; then
				emake docs-latex || die "emake docs-latex failed!"
			fi
			einfo "Done compiling documentation."
		fi
	fi
}

src_test()
{
	einfo "Now running tests for package ${PN}"
	einfo "It is considered \"normal\" for some tests to fail, but at least one should pass ..."
	for test_phase in test mmd-test compat-test latex-test ; do
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
			doexe scripts/${file} || die "Installation of script ${file} failed!"
		done
	fi

	#install documentation
	if use doc; then
		einfo "Installing documentation for ${PN}"
		dohtml manual/*.html || die "Installation of documentation failed!"
		if use latex; then
			dodoc manual/*.pdf || die "Installation of LaTeX documentation failed!"
		fi
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
			einfo "Installing ${file} to ${DEST_DIR_EXE}/${file} ..."
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
	einfo "`${ROOT}${DEST_DIR_EXE}/multimarkdown -v`"
}
