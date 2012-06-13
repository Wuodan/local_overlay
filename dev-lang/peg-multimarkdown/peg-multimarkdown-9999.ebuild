# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# EAPI 2 needed to run src_prepare
EAPI=2

# project is hosted on github.com, so git-2 is needed (git is deprecated)
inherit git-2 eutils

DESCRIPTION="MMD is a superset of the Markdown syntax (more syntax features & output formats)"
HOMEPAGE="http://http://fletcherpenney.net/multimarkdown"
EGIT_REPO_URI="git://github.com/fletcher/peg-multimarkdown.git"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

# USE flags
IUSE="shortcuts perl-conversions latex xslt test"

# basic depenedencies
DEPEND=""
RDEPEND="${DEPEND}"
PDEPEND="${RDEPEND}"

# conditional dependencies
DEPEND="${DEPEND}
	test? ( dev-lang/perl app-text/htmltidy )"
RDEPEND="${RDEPEND}
	perl-conversions? ( dev-lang/perl )
	xslt? ( dev-libs/libxslt )"
# post depend for plugins
# no idea why peg-multimarkdown-latex-support is is not included as git sub-module, but it requires a separate git clone thus a separate pkg
PDEPEND="${PDEPEND}
	latex? ( dev-lang/peg-multimarkdown-latex-support )"
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
	einfo "XSLT support requires patching of some scripts (they must know where the XSLT templates are)"
	use xslt && epatch "${FILESDIR}/${PN}-gentoo-xslt.patch" || die "Patching of XSLT scripts for ${PN} failed!"
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
			einfo "Installing ${file} to ${DEST_DIR_EXE}/${file} ..."
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
			echo $file_path
			einfo "Installing ${file} to ${DEST_DIR_EXE}/${file} ..."
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
			echo $file
			local file_path=`find Support/ -name "${file}"`
			einfo "Installing ${file} to ${DEST_DIR_EXE}/${file} ..."
			doexe ${file_path} || die "Installation of script ${file} failed!"
		done
		einfo "Done installing perl-conversion scripts for ${PN}"
	fi
}

pkg_postinst()
{
	ewarn "This ebuild is in alpha state!"
	ewarn "Use it at your own risk ..."
	elog "May the moon shine upon you ..."
}

pkg_config()
{
	# these messages seem not to go to normal log, einfo does the same, does it?
	elog "Starting configuration of ${PN}"
	# check if binary executable was installed
	if [ ! -x "${ROOT}${DEST_DIR_EXE}/multimarkdown" ]; then
		ewarn "Installation of ${PN} failed"
		ewarn "Missing executable in ${ROOT}${DEST_DIR_EXE}/multimarkdown"
		die "Previus installation of ${PN} failed"
	else
		einfo "multimarkdown binary installed in ${ROOT}${DEST_DIR_EXE}/multimarkdown, displaying version"
		einfo "*** version start"
		einfo `${ROOT}${DEST_DIR_EXE}/multimarkdown -v`
		einfo "*** version end"
	fi
	# check for the extra scripts
	einfo "${PN} comes with some extra scripts. They are not necessary for the programm itself, but serve as shortcuts, see http://fletcherpenney.net/multimarkdown/use/"
	einfo "You will now be asked if you want to keep these scripts or not:"
	for file in mmd mmd2tex mmd2opml mmd2odf; do
		if [ ! -x "${ROOT}${DEST_DIR_EXE}/${file}" ]; then
			elog "${file} not found in ${ROOT}${DEST_DIR_EXE}/${file}, it was previously removed."
		else
			# this seems to be bash4 syntax
			elog "${file} found in ${ROOT}${DEST_DIR_EXE}/${file}."
			read -e -p "Do you want to keep the script at ${ROOT}${DEST_DIR_EXE}/${file} [Y/n]?" -i "Y" keep_script
			if [ "${keep_script}" == "n" ]; then
				rm ${ROOT}${DEST_DIR_EXE}/${file}
				elog "Removed script at ${ROOT}${DEST_DIR_EXE}/${file}"
			fi
		fi
	done
	elog "Ending configuration of ${PN}"
}

pkg_info()
{
	${ROOT}${DEST_DIR_EXE}/multimarkdown -v
}
