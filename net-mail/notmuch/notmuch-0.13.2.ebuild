# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

PYTHON_DEPEND="python? 2:2.6 3:3.2"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="2.[45] 3.1"

inherit elisp-common pax-utils distutils autotools

DESCRIPTION="Thread-based e-mail indexer, supporting quick search and tagging"
HOMEPAGE="http://notmuchmail.org/"
SRC_URI="${HOMEPAGE%/}/releases/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 x86"
REQUIRED_USE="test? ( crypt emacs python )"
IUSE="bash-completion crypt debug deliver doc emacs nmbug mutt python test vim
	zsh-completion"

CDEPEND="
	>=dev-libs/glib-2.22
	>=dev-libs/gmime-2.6.7
	dev-libs/xapian
	sys-libs/talloc
	debug? ( dev-util/valgrind )
	emacs? ( >=virtual/emacs-23 )
	x86? ( >=dev-libs/xapian-1.2.7-r2 )
	vim? ( || ( >=app-editors/vim-7.0 >=app-editors/gvim-7.0 ) )
	"
DEPEND="${CDEPEND}
	virtual/pkgconfig
	doc? ( python? ( dev-python/sphinx ) )
	test? ( app-misc/dtach sys-devel/gdb )
	"
RDEPEND="${CDEPEND}
	crypt? ( app-crypt/gnupg )
	nmbug? ( dev-vcs/git virtual/perl-File-Temp virtual/perl-PodParser )
	mutt? ( dev-perl/Mail-Box dev-perl/MailTools dev-perl/String-ShellQuote
		dev-perl/Term-ReadLine-Gnu virtual/perl-File-Path
		virtual/perl-Getopt-Long virtual/perl-PodParser
		)
	zsh-completion? ( app-shells/zsh )
	"

SITEFILE="50${PN}-gentoo.el"
MY_LD_LIBRARY_PATH="${WORKDIR}/${P}/lib"

bindings() {
	if use $1; then
		pushd bindings/$1 || die
		shift
		$@
		popd || die
	fi
}

pkg_setup() {
	# is this the correct place to set DOCS var?
	use doc && DOCS=( AUTHORS NEWS README )
	if use emacs; then
		elisp-need-emacs 23 || die "Emacs version too low"
	fi
	use python && python_pkg_setup
}

src_prepare() {
	default
	bindings python distutils_src_prepare

	# prepvent doc from being installed by distutils_src_install
	use doc || rm README || die "rm failed"

	if use deliver; then
		pushd contrib/notmuch-deliver || die
		mv README.mkd README-deliver.mkd || die "mv failed"
		if use doc; then
			sed -i 's/README.mkd/README-deliver.mkd/' Makefile.am || \
				die "sed failed"
		else
			# prevent doc from being built & installed
			sed -i '/README.mkd/d' Makefile.am || die "sed failed"
		fi
		AT_M4DIR="m4"
		eautoreconf
		popd || die
	fi
}

src_configure() {
	local myeconfargs=(
		--bashcompletiondir="${ROOT}/usr/share/bash-completion"
		--emacslispdir="${ROOT}/${SITELISP}/${PN}"
		--emacsetcdir="${ROOT}/${SITEETC}/${PN}"
		--with-gmime-version=2.6
		--zshcompletiondir="${ROOT}/usr/share/zsh/site-functions"
		$(use_with bash-completion)
		$(use_with emacs)
		$(use_with zsh-completion)
	)
	econf "${myeconfargs[@]}"

	if use deliver; then
		pushd contrib/notmuch-deliver || die
		econf --docdir="/usr/share/doc/${PF}/"
		popd || die
	fi
}

src_compile() {
	default
	bindings python distutils_src_compile

	if use mutt; then
		pushd contrib/notmuch-mutt || die
		mv README README-mutt || die
		emake notmuch-mutt.1
		popd || die
	fi

	if use deliver; then
		pushd contrib/notmuch-deliver || die
		emake
		popd || die
	fi

	if use doc; then
		pydocs() {
			mv README README-python || die
			pushd docs || die
			emake html
			mv html ../python || die
			popd || die
		}
		LD_LIBRARY_PATH="${MY_LD_LIBRARY_PATH}" bindings python pydocs
	fi
}

src_test() {
	pax-mark -m notmuch
	LD_LIBRARY_PATH="${MY_LD_LIBRARY_PATH}" default
	pax-mark -ze notmuch
}

src_install() {
	default

	if use emacs; then
		elisp-site-file-install "${FILESDIR}/${SITEFILE}" || die
	fi

	if use nmbug; then
		dobin contrib/nmbug
	fi

	if use mutt; then
		[[ -e /etc/mutt/notmuch-mutt.rc ]] && NOTMUCH_MUTT_RC_EXISTS=1
		pushd contrib/notmuch-mutt || die
		dobin notmuch-mutt
		doman notmuch-mutt.1
		insinto /etc/mutt
		doins notmuch-mutt.rc
		use doc && dodoc README-mutt
		popd || die
	fi

	if use deliver; then
		pushd contrib/notmuch-deliver || die
		emake DESTDIR="${D}" install
		popd || die
	fi

	if use vim; then
		insinto /usr/share/vim/vimfiles
		doins -r vim/plugin vim/syntax
	fi

	# what does this do?
	DOCS="" bindings python distutils_src_install

	if use doc; then
		bindings python dohtml -r python
	fi
}

pkg_postinst() {
	use emacs && elisp-site-regen
	use python && distutils_pkg_postinst

	if use mutt && [[ ! ${NOTMUCH_MUTT_RC_EXISTS} ]]; then
		elog "To enable notmuch support in mutt, add the following line into"
		elog "your mutt config file, please:"
		elog ""
		elog "  source /etc/mutt/notmuch-mutt.rc"
	fi
}

pkg_postrm() {
	use emacs && elisp-site-regen
	use python && distutils_pkg_postrm
}
