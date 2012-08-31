# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

PYTHON_DEPEND="2"
PYTHON_USE_WITH="sqlite"
inherit python subversion toolchain-funcs

DESCRIPTION="A modern, feature-rich, cross-platform firmware development env. for the UEFI and PI specifications"
HOMEPAGE="http://sourceforge.net/apps/mediawiki/tianocore"
SRC_URI=""
REPO_REV="@11337"
# REPO_REV="@13452"
# REPO_REV="@13692"
ESVN_REPO_URI="http://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2"
REPO_PKG="
		MdePkg
		MdeModulePkg
"
use kvm && REPO_PKG+="
		OvmfPkg
		OptionRomPkg
		UefiCpuPkg
		IntelFrameworkModulePkg
		PcAtChipsetPkg
		FatBinPkg
		EdkShellBinPkg
		IntelFrameworkPkg
	"
( use kvm || use shell ) && REPO_PKG+="
		ShellPkg
	"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"
IUSE="hello-world kvm shell"

DEPEND="
	app-arch/unzip
	>=dev-vcs/subversion-1.5
	sys-devel/binutils
	sys-libs/glibc
	kvm? (
		>=app-emulation/qemu-kvm-0.9.1
		sys-power/iasl
	)"
RDEPEND="kvm? ( >=app-emulation/qemu-kvm-0.9.1 )"

S="$(dirname ${S})"

# TODO:
# fix this:
# In function ‘void* memset(void*, int, size_t)’,
#     inlined from ‘SVfrVarStorageNode::SVfrVarStorageNode(EFI_GUID*, CHAR8*, EFI_VARSTORE_ID, EFI_STRING_ID, UINT32, BOOLEAN)’ at VfrUtilityLib.cpp:1309:41:
# /usr/include/bits/string3.h:85:70: warning: call to void* __builtin___memset_chk(void*, int, long unsigned int, long unsigned int) will always overflow destination buffer
# In function ‘void* memset(void*, int, size_t)’,
#     inlined from ‘SVfrVarStorageNode::SVfrVarStorageNode(EFI_GUID*, CHAR8*, EFI_VARSTORE_ID, SVfrDataType*, BOOLEAN)’ at VfrUtilityLib.cpp:1336:41:
# /usr/include/bits/string3.h:85:70: warning: call to void* __builtin___memset_chk(void*, int, long unsigned int, long unsigned int) will always overflow destination buffer

pkg_setup() {
	if use !hello-world && use !kvm && use !shell; then
		die "Select at least one module to be built!"
	fi
	python_set_active_version 2
}

src_unpack(){
	einfo "### Be patient! ###"
	einfo "Downloading individual folders is slow, but really decreases total download size."
	einfo "### Be patient! ###"

	mkdir Conf || die "Failed to 'mkdir Conf'"
	ESVN_OPTIONS="--depth files" subversion_fetch "${ESVN_REPO_URI}${REPO_REV}"
	# avoid downloading useless Bin (47MB) folder
	ESVN_OPTIONS="--depth immediates" subversion_fetch "${ESVN_REPO_URI}/BaseTools${REPO_REV}" BaseTools
	local dir
	for dir in `find BaseTools -mindepth 1 -maxdepth 1 -type d | grep -v 'Bin$'`; do
		subversion_fetch "${ESVN_REPO_URI}/${dir}${REPO_REV}" "${dir}"
	done

	for dir in ${REPO_PKG}; do
		subversion_fetch "${ESVN_REPO_URI}/${dir}${REPO_REV}" "${dir}"
	done
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
		build --arch "${ARCH}" --platform MdeModulePkg/MdeModulePkg.dsc --tagname "${tagname}" \
			--module MdeModulePkg/Application/HelloWorld/HelloWorld.inf \
			--buildtarget RELEASE -n 9 || die "Failed to build HelloWorld"
		# create startup.nsh for kvm testing
		echo "fs0:\HelloWorld.efi" > Build/MdeModule/RELEASE_GCC45/X64/startup.nsh || die "Failed to
		create startup.nsh"
	fi

	if use kvm; then
		build --arch "${ARCH}" --platform OvmfPkg/OvmfPkgX64.dsc --tagname "${tagname}" \
			--buildtarget RELEASE -n 9 || die "Failed to build UEFI-shell"
	fi

	if use shell; then
		build --arch "${ARCH}" --platform ShellPkg/ShellPkg.dsc --tagname "${tagname}" \
			--module ShellPkg/Application/Shell/Shell.inf \
			--buildtarget RELEASE -n 9 || die "Failed to build UEFI-shell"
	fi

	# reset $ARCH
	ARCH="${oldARCH}"
}

src_install(){
	if use hello-world; then
		insinto "/usr/share/${PN}/hello-world"
		doins Build/MdeModule/RELEASE_GCC45/X64/HelloWorld.efi
		doins Build/MdeModule/RELEASE_GCC45/X64/startup.nsh
	fi

	if use shell; then
		insinto "/usr/share/${PN}/shell"
		newins Build/Shell/RELEASE_GCC45/X64/Shell.efi Shellx64.efi
	fi

	if use kvm; then
		insinto "/usr/share/${PN}/kvm"
		newins Build/OvmfX64/RELEASE_GCC45/FV/OVMF.fd uefibios.bin
		newins Build/OvmfX64/RELEASE_GCC45/FV/CirrusLogic5446.rom vgabios-cirrus.bin
		# insinto /usr/share/qemu
		dosym "../${PN}/kvm/uefibios.bin" /usr/share/qemu/uefibios.bin || die "WTF"
	fi
}

pkg_postinst() {
	use kvm && einfo "To use uefi with qemu-kvm, start it with '-bios uefibios.bin'"
	if use hello-world; then
		einfo "A sample HelloWorld.efi was installed in /usr/share/${PN}/hello-world."
		if use kvm; then
			einfo "To test the uefi support in kvm, simply run:"
			einfo "	qemu-kvm -hda fat:/usr/share/edk2/hello-world -bios uefibios.bin"
			einfo "and await the message 'UEFI Hello World!' before the shell prompt appears."
		fi
	fi
}