# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

PYTHON_DEPEND="2"
PYTHON_USE_WITH="sqlite"
inherit python subversion toolchain-funcs flag-o-matic

DESCRIPTION="A modern, feature-rich, cross-platform firmware development env. for the UEFI and PI specifications"
HOMEPAGE="http://sourceforge.net/apps/mediawiki/tianocore"
SRC_URI=""
REPO_REV="@11337"
# REPO_REV="@13452"
# REPO_REV="@13692"
ESVN_REPO_URI="http://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2"


LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"
IUSE="hello-world kvm shell"
REQUIRED_USE="|| ( hello-world kvm shell )"

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
	python_set_active_version 2
}

src_unpack(){
	local repo_pkg="
			MdePkg
			MdeModulePkg
	"
	use kvm && repo_pkg+="
			OvmfPkg
			OptionRomPkg
			UefiCpuPkg
			IntelFrameworkModulePkg
			PcAtChipsetPkg
			FatBinPkg
			EdkShellBinPkg
			IntelFrameworkPkg
		"
	( use kvm || use shell ) && repo_pkg+="
			ShellPkg
		"
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

src_prepare(){
	# errors occur with -O -O1 -O2 but not with -O3
	filter-flags -O*
	# patch compiler flags
	sed -i -r -e "s/^(CC = ).*$/\1`tc-getCC`/" \
		-e "s/^(CXX = ).*$/\1`tc-getCXX`/" \
		-e "s/^(AS = ).*$/\1`tc-getAS`/" \
		-e "s/^(AR = ).*$/\1`tc-getAR`/" \
		-e "s/^(LD = ).*$/\1`tc-getLD`/" \
		-e "s/^(CFLAGS = ).*$/\1`echo "${CFLAGS}"`/" \
		-e "s/^(LFLAGS = ).*$/\1`echo "${LFLAGS}"`/" \
		BaseTools/Source/C/Makefiles/header.makefile || die "Failed to patch compiler flags"
	for file in dlg/makefile antlr/makefile support/genmk/makefile; do
		sed -i -r -e "s/^(CC *= *).*$/\1`tc-getCC`/" \
			-e "s/^(CXX *= *).*$/\1`echo "${CFLAGS}"`/" \
			"BaseTools/Source/C/VfrCompile/Pccts/${file}" || die "Failed to patch compiler flags in ${file}"
	done
	sed -i -r -e "s/^(DEFINE GCC44_ALL_CC_FLAGS *=.*) -Werror /\1 `echo "${CFLAGS}"` /" \
		-e "s/gcc$/`tc-getCC`/" \
		-e "s/as$/`tc-getAS`/" \
		-e "s/ar$/`tc-getAR`/" \
		-e "s/ld$/`tc-getLD`/" \
		BaseTools/Conf/tools_def.template || die "Failed to patch compiler flags"
}

src_compile(){
	# $ARCH is used, preserve old value
	# Gentoo uses 'amd64', the package needs 'X64'
	local oldARCH="${ARCH}"
	ARCH='X64'

	# build the BaseTools
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
			--buildtarget RELEASE || die "Failed to build HelloWorld"
		# create startup.nsh for kvm testing
		echo "fs0:\HelloWorld.efi" > Build/MdeModule/RELEASE_GCC45/X64/startup.nsh || die "Failed to
		create startup.nsh"
	fi

	if use kvm; then
		build --arch "${ARCH}" --platform OvmfPkg/OvmfPkgX64.dsc --tagname "${tagname}" \
			--buildtarget RELEASE || die "Failed to build UEFI-shell"
	fi

	if use shell; then
		build --arch "${ARCH}" --platform ShellPkg/ShellPkg.dsc --tagname "${tagname}" \
			--module ShellPkg/Application/Shell/Shell.inf \
			--buildtarget RELEASE || die "Failed to build UEFI-shell"
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
		dosym "../${PN}/kvm/uefibios.bin" /usr/share/qemu/uefibios.bin
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
