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
REPO_REV="11337"
REPO_URI="http://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2"
REPO_PKG="
	BaseTools
	OvmfPkg
	OptionRomPkg
	UefiCpuPkg
	MdeModulePkg
	IntelFrameworkModulePkg
	PcAtChipsetPkg
	FatBinPkg
	EdkShellBinPkg
	MdePkg
	ShellPkg
	IntelFrameworkPkg
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
	subversion_fetch "${REPO_URI}@${REPO_REV}"
	ESVN_OPTIONS=''
	local url
	if use kvm; then
		for pkg in ${REPO_PKG}; do
			# subversion_fetch "${ESVN_REPO_URI}" OvmfPkg
			subversion_fetch "${REPO_URI}/${pkg}@${REPO_REV}" "${pkg}"
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
	ARCH='X64'
	
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
		build --arch "${ARCH}" --platform MdeModulePkg/MdeModulePkg.dsc --tagname "${tagname}" --module MdeModulePkg/Application/HelloWorld/HelloWorld.inf \
			--buildtarget RELEASE -n 9 || die "Failed to build HelloWorld"
	fi

	if use kvm; then
		build --arch "${ARCH}" --platform OvmfPkg/OvmfPkgX64.dsc --tagname "${tagname}" \
			--buildtarget RELEASE -n 9 || die "Failed to build UEFI-shell"
	fi

	if use shell; then
		build --arch "${ARCH}" --platform ShellPkg/ShellPkg.dsc --tagname "${tagname}" \
			--buildtarget RELEASE -n 9 || die "Failed to build UEFI-shell"
	fi


	# reset $ARCH
	ARCH="${oldARCH}"
}

src_install(){
	if use hello-world; then
		# dodir "/usr/share/${PN}/hello-world"
		insinto "/usr/share/${PN}/hello-world"
		doins MdeModule/RELEASE_GCC45/X64/HelloWorld.efi
	fi

	if use kvm; then
		# dodir "/usr/share/${PN}/kvm"
		insinto "/usr/share/${PN}/kvm"
		doins Build/OvmfX64/RELEASE_GCC45/FV/OVMF.fd
		doins Build/OvmfX64/RELEASE_GCC45/FV/CirrusLogic5446.rom
	fi

	if use shell; then
		# dodir "/usr/share/${PN}/shell"
		insinto "/usr/share/${PN}/shell"
		doins Shell/RELEASE_GCC45/X64/Shell.efi
	fi
}
