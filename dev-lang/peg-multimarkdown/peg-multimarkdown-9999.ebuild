# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=0

# project is hosted on github.com, so git-2 is needed (git is deprecated)
inherit git-2

DESCRIPTION="MMD is a superset of the Markdown syntax (more syntax features & output formats)"
HOMEPAGE="http://http://fletcherpenney.net/multimarkdown"
EGIT_REPO_URI="git://github.com/fletcher/peg-multimarkdown.git"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

# USE flags
IUSE="shortcuts latex xslt test"

# basic depenedencies
DEPEND=""
RDEPEND="${DEPEND}"

# conditional dependencies
DEPEND="${DEPEND}
	test? ( dev-lang/perl app-text/htmltidy )"
RDEPEND="${RDEPEND}
	latex? ( dev-lang/perl virtual/latex-base )
	xslt? ( dev-lang/perl dev-libs/libxslt )"
if use test || use latex || use xslt ; then
	# we also need the sub-modules, this triggers it in git-2.eclass
	EGIT_HAS_SUBMODULES="Y"
fi

# custom variables
DESTINATION_DIR="usr/bin"
SHORTCUTS_LIST="mmd mmd2tex mmd2opml mmd2odf"
# mmd2all  mmd2pdf are excluded

src_test()
{
	einfo "Now running tests for package ${PN}"
	einfo "It is considered \"normal\" for some tests to fails, but at least one should pass ..."
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
	insinto ${DESTINATION_DIR}
	einfo "Installing multimarkdown to ${ROOT}${DESTINATION_DIR}/multimarkdown ..."
	dobin multimarkdown || die "Install failed"

	# USE flag based installation
	# install shortcuts
	if use shortcuts ; then
		exeinto ${DESTINATION_DIR}
		for file in ${SHORTCUTS_LIST}; do
			einfo "Installing ${file} to ${ROOT}${DESTINATION_DIR}/${file} ..."
			doexe scripts/${file} || ewarn "Installation of script ${file} failed!"
		done
	fi
	
	# install latex support
	if use latex ; then
		local latex_folder="/usr/share/texmf/tex/latex"
		# find latex folder or fail
		[ -d ${latex_folder} ] || die "LaTex support for ${PN} cannot be installed. Missing LaTex folder in /usr/share/texmf/tex/latex/"
		echo todo		
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
	if [ ! -x "${ROOT}${DESTINATION_DIR}/multimarkdown" ]; then
		ewarn "Installation of ${PN} failed"
		ewarn "Missing executable in ${ROOT}${DESTINATION_DIR}/multimarkdown"
		die "Previus installation of ${PN} failed"
	else
		einfo "multimarkdown binary installed in ${ROOT}${DESTINATION_DIR}/multimarkdown, displaying version"
		einfo "*** version start"
		einfo `${ROOT}${DESTINATION_DIR}/multimarkdown -v`
		einfo "*** version end"
	fi
	# check for the extra scripts
	einfo "${PN} comes with some extra scripts. They are not necessary for the programm itself, but serve as shortcuts, see http://fletcherpenney.net/multimarkdown/use/"
	einfo "You will now be asked if you want to keep these scripts or not:"
	for file in mmd mmd2tex mmd2opml mmd2odf; do
		if [ ! -x "${ROOT}${DESTINATION_DIR}/${file}" ]; then
			elog "${file} not found in ${ROOT}${DESTINATION_DIR}/${file}, it was previously removed."
		else
			# this seems to be bash4 syntax
			elog "${file} found in ${ROOT}${DESTINATION_DIR}/${file}."
			read -e -p "Do you want to keep the script at ${ROOT}${DESTINATION_DIR}/${file} [Y/n]?" -i "Y" keep_script
			if [ "${keep_script}" == "n" ]; then
				rm ${ROOT}${DESTINATION_DIR}/${file}
				elog "Removed script at ${ROOT}${DESTINATION_DIR}/${file}"
			fi
		fi
	done
	elog "Ending configuration of ${PN}"
}

pkg_info()
{
	${ROOT}${DESTINATION_DIR}/multimarkdown -v
}
