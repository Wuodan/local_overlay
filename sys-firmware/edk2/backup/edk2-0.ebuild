# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

PYTHON_DEPEND="2"
PYTHON_USE_WITH="sqlite"
inherit python subversion toolchain-funcs

DESCRIPTION="A modern, feature-rich, cross-platform firmware development environment for the UEFI and PI specifications"
HOMEPAGE="http://sourceforge.net/apps/mediawiki/tianocore"
# SRC_URI="http://dfn.dl.sourceforge.net/project/edk2/UDK2010%20Releases/UDK2010.SR1.UP1/UDK2010.SR1.UP1.Complete.MyWorkSpace.zip"
# SRC_URI="http://downloads.sourceforge.net/project/edk2/UDK2010%20Releases/UDK2010.SR1.UP1/UDK2010.SR1.UP1.Complete.MyWorkSpace.zip"
#	kvm? ( http://downloads.sourceforge.net/project/edk2/OVMF/OVMF-X64-r11337-alpha.zip )"
# SRC_URI="http://sourceforge.net/projects/edk2-buildtools/files/BuildTools_Source_Packages/BaseTools(Unix)_UDK2010.SR1.UP1.tar"
SRC_URI=""
REPO_URI="
	http://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2/BaseTools@11337
	http://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2/OvmfPkg@11337
	http://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2/OptionRomPkg@11337
	http://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2/UefiCpuPkg@11337
	http://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2/MdeModulePkg@11337
	http://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2/IntelFrameworkModulePkg@11337
	http://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2/PcAtChipsetPkg@11337
	http://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2/FatBinPkg@11337
	http://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2/EdkShellBinPkg@11337
	http://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2/MdePkg@11337
	http://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2/ShellPkg@11337
	http://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2/IntelFrameworkPkg@11337
"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"
IUSE="hello-world kvm shell"

RDEPEND=""
DEPEND="
	app-arch/unzip
	sys-libs/glibc
	kvm? ( sys-power/iasl )"

S="$(dirname ${S})"

pkg_setup() {
	if use !hello-world && use !kvm && use !shell; then
		die "Select at least one module to be built!"
	fi
	python_set_active_version 2
}

src_unpack(){
	mkdir Conf || die "Failed to 'mkdir Conf'"
	ESVN_OPTIONS="--depth files"
	subversion_fetch http://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2@11337
	ESVN_OPTIONS=''
	local url
	if use kvm; then
		for url in ${REPO_URI}; do
			# subversion_fetch "${ESVN_REPO_URI}" OvmfPkg
			local folder=`echo "${url}" | sed -r 's/^.*\/([^@]+)@.*$/\1/'`
			subversion_fetch "${url}" "${folder}"
		done
	fi
	# unpack "${A}"
	# local file
	# for file in ${A}; do
	# 	unpack "${file}"
	# done
	# pushd "${S}"
	# unpack ./BaseTools\(Unix\).tar
	# unpack ./UDK2010.SR1.UP1.MyWorkSpace.zip
	# mv MyWorkSpace/* . || die "Failed to 'mv MyWorkSpace/* .'"
	# popd
}

src_compile(){
	# $ARCH is used, preserve old value
	# Gentoo uses 'amd64', the package needs 'X64'
	local oldARCH="${ARCH}"
	ARCH=''
	
	# build the cross-compiler
	emake -C BaseTools

	export EDK_TOOLS_PATH="${S}"/BaseTools
	# this mainly appends to $PATH
	. edksetup.sh BaseTools

	# build using the generated cross-compiler
	# for a list of options, run 'build --help' or look at BaseTools/Source/Python/build/build.py MyOptionParser()
	# TODO: -n X should be number of CPU+1. See no effect of it so far
	local tagname="GCC$(gcc-major-version)$(gcc-minor-version)"
	if use hello-world; then
		build --arch X64 --platform MdeModulePkg/MdeModulePkg.dsc --tagname "${tagname}" --module MdeModulePkg/Application/HelloWorld/HelloWorld.inf \
			--buildtarget RELEASE -n 9 || die "Failed to build HelloWorld"
	fi

	if use kvm; then
		build --arch X64 --platform OvmfPkg/OvmfPkgX64.dsc --tagname "${tagname}" \
			--buildtarget RELEASE -n 9 || die "Failed to build UEFI-shell"
	fi

	if use shell; then
		build --arch X64 --platform ShellPkg/ShellPkg.dsc --tagname "${tagname}" \
			--buildtarget RELEASE -n 9 || die "Failed to build UEFI-shell"
	fi


	# reset $ARCH
	ARCH="${oldARCH}"
}