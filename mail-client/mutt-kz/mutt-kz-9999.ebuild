# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

inherit eutils git-2 autotools

MUTT_PV="1.5.21"
MUTT_PVR="1.5.21-r10"
MUTT_P="mutt-${MUTT_PV}"
PATCHSET_REV="-r13"

DESCRIPTION="A forx of mutt, the small but very powerful text-based mail client"
HOMEPAGE="https://github.com/karelzak/mutt-kz/"
# SRC_URI="ftp://ftp.mutt.org/mutt/devel/${P}.tar.gz
SRC_URI="mirror://gentoo/${MUTT_P}-gentoo-patches${PATCHSET_REV}.tar.bz2
	http://dev.gentoo.org/~grobian/distfiles/${MUTT_P}-gentoo-patches${PATCHSET_REV}.tar.bz2"
EGIT_REPO_URI="git://github.com/karelzak/${PN}.git"

IUSE="berkdb crypt debug doc gdbm gnutls gpg idn imap notmuch mbox nls pop qdbm sasl selinux sidebar smime smtp ssl tokyocabinet"
SLOT="0"
LICENSE="GPL-2"
KEYWORDS="~amd64"
RDEPEND="
	app-misc/mime-types
	!mail-client/mutt
	>=sys-libs/ncurses-5.2
	gpg?     ( >=app-crypt/gpgme-0.9.0 )
	idn?     ( net-dns/libidn )
	imap?    (
		gnutls?  ( >=net-libs/gnutls-1.0.17 )
		!gnutls? ( ssl? ( >=dev-libs/openssl-0.9.6 ) )
		sasl?    ( >=dev-libs/cyrus-sasl-2 )
	)
	notmuch? ( net-mail/notmuch )
	pop?     (
		gnutls?  ( >=net-libs/gnutls-1.0.17 )
		!gnutls? ( ssl? ( >=dev-libs/openssl-0.9.6 ) )
		sasl?    ( >=dev-libs/cyrus-sasl-2 )
	)
	selinux? ( sec-policy/selinux-mutt )
	smime?   ( >=dev-libs/openssl-0.9.6 )
	smtp?     (
		gnutls?  ( >=net-libs/gnutls-1.0.17 )
		!gnutls? ( ssl? ( >=dev-libs/openssl-0.9.6 ) )
		sasl?    ( >=dev-libs/cyrus-sasl-2 )
	)
	tokyocabinet?  ( dev-db/tokyocabinet )
	!tokyocabinet? (
		qdbm?  ( dev-db/qdbm )
		!qdbm? (
			gdbm?  ( sys-libs/gdbm )
			!gdbm? ( berkdb? ( >=sys-libs/db-4 ) )
		)
	)"
DEPEND="${RDEPEND}
	net-mail/mailbase
	doc? (
		app-text/docbook-xsl-stylesheets
		dev-libs/libxml2
		dev-libs/libxslt
		|| ( www-client/lynx www-client/w3m www-client/elinks )
	)"

PATCHDIR="${WORKDIR}"/${MUTT_P}-gentoo-patches${PATCHSET_REV}
# most patches for regular mutt do not work, so let's just exclude them for now
EPATCH_EXCLUDE="02-compressed.patch 03-progress-bar.patch 04-xterm-titles.patch
06-nntp.patch 07-quote.patch 08-initials.patch 09-smarttime.patch
10-change_folder_next.patch 11-change_subject.patch 12-trash-folder.patch
13-pgp-verbose-mime.patch 14-pgp-display-signature.patch
sidebar.patch sidebar-utf8.patch sidebar-dotpathsep.patch"

src_prepare() {
	# Post-release hot-fixes grabbed from HG, this is what all following
	# patches are based on in my Mercurial patchqueue (mq).
	# If you ever take over or need to modify patches here, just check
	# out the gentoo branch(es) of Gentoo's Mutt Mercurial clone, and
	# the patchqueue as it'll save you a lot of work.
	# http://prefix.gentooexperimental.org:8000/mutt/
	# http://prefix.gentooexperimental.org:8000/mutt-patches/
	for rev in $(eval echo {0..${PR#r}}) ; do
		local revpatch="${PATCHDIR}"/mutt-gentoo-${MUTT_PV}-r${rev}.patch
		[[ -e ${revpatch} ]] && \
			epatch "${revpatch}"
	done

	# this patch is non-generic and only works because we use a sysconfdir
	# different from the one used by the mailbase ebuild
	use prefix && epatch "${PATCHDIR}"/prefix-mailcap.patch

	# must have fixes to compile or behave correctly, upstream
	# ignores, disagrees or simply doesn't respond/apply
	epatch "${PATCHDIR}"/bdb-prefix.patch # fix bdb detection
	epatch "${PATCHDIR}"/interix-btowc.patch
	epatch "${PATCHDIR}"/gpgme-1.2.0.patch
	epatch "${PATCHDIR}"/emptycharset-segfault.patch
	epatch "${PATCHDIR}"/gpgkeyverify-segfault.patch
	# same category, but functional bits
	epatch "${PATCHDIR}"/dont-reveal-bbc.patch

	# the big feature patches that upstream doesn't want to include, but
	# nearly every distro has due to their usefulness
	for p in "${PATCHDIR}"/[0-9][0-9]-*.patch ; do
		epatch "${p}"
	done

	# we conditionalise this one, simply because it has considerable
	# impact on the code
	if use sidebar ; then
		epatch "${PATCHDIR}"/sidebar.patch
		epatch "${PATCHDIR}"/sidebar-utf8.patch
		epatch "${PATCHDIR}"/sidebar-dotpathsep.patch
	fi

	# patch version string for bug reports
	sed -i -e 's/"Mutt %s (%s)"/"Mutt-KZ %s (%s, Gentoo '"${PVR}"')"/' \
		muttlib.c || die "failed patching in Gentoo version"

	# allow user patches
	epatch_user

	# many patches touch the buildsystem, we always need this
	AT_M4DIR="m4" eautoreconf

	# the configure script contains some "cleverness" whether or not to setgid
	# the dotlock program, resulting in bugs like #278332
	sed -i -e 's/@DOTLOCK_GROUP@//' \
		Makefile.in || die "sed failed"

	# don't just build documentation (lengthy process, with big dependencies)
	if use !doc ; then
		sed -i -e '/SUBDIRS =/s/doc//' Makefile.in || die
	fi
}

src_configure() {
	local myconf="
		$(use_enable crypt pgp) \
		$(use_enable debug) \
		$(use_enable gpg gpgme) \
		$(use_enable imap) \
		$(use_enable nls) \
		$(use_enable notmuch) \
		$(use_enable pop) \
		$(use_enable smime) \
		$(use_enable smtp) \
		$(use_with idn) \
		$(use_with !notmuch mixmaster) \
		--enable-external-dotlock \
		--enable-nfs-fix \
		--sysconfdir="${EPREFIX}"/etc/${PN} \
		--with-curses \
		--with-docdir="${EPREFIX}"/usr/share/doc/${PN}-${PVR} \
		--with-regex \
		--with-exec-shell=${EPREFIX}/bin/sh"

	case $CHOST in
		*-solaris*)
			# Solaris has no flock in the standard headers
			myconf="${myconf} --enable-fcntl --disable-flock"
		;;
		*)
			myconf="${myconf} --disable-fcntl --enable-flock"
		;;
	esac

	# mutt prioritizes gdbm over bdb, so we will too.
	# hcache feature requires at least one database is in USE.
	if use tokyocabinet; then
		myconf="${myconf} --enable-hcache \
			--with-tokyocabinet --without-qdbm --without-gdbm --without-bdb"
	elif use qdbm; then
		myconf="${myconf} --enable-hcache \
			--without-tokyocabinet --with-qdbm --without-gdbm --without-bdb"
	elif use gdbm ; then
		myconf="${myconf} --enable-hcache \
			--without-tokyocabinet --without-qdbm --with-gdbm --without-bdb"
	elif use berkdb; then
		myconf="${myconf} --enable-hcache \
			--without-tokyocabinet --without-qdbm --without-gdbm --with-bdb"
	else
		myconf="${myconf} --disable-hcache \
			--without-tokyocabinet --without-qdbm --without-gdbm --without-bdb"
	fi

	# there's no need for gnutls, ssl or sasl without socket support
	if use pop || use imap || use smtp ; then
		if use gnutls; then
			myconf="${myconf} --with-gnutls"
		elif use ssl; then
			myconf="${myconf} --with-ssl"
		fi
		# not sure if this should be mutually exclusive with the other two
		myconf="${myconf} $(use_with sasl)"
	else
		myconf="${myconf} --without-gnutls --without-ssl --without-sasl"
	fi

	if use mbox; then
		myconf="${myconf} --with-mailpath=${EPREFIX}/var/spool/mail"
	else
		myconf="${myconf} --with-homespool=Maildir"
	fi

	echo "### myconf ###"
	echo $myconf
	echo "### myconf ###"

	econf ${myconf} || die "configure failed"
}

src_install() {
	make DESTDIR="${D}" install || die "install failed"
	if use mbox; then
		insinto /etc/mutt
		newins "${FILESDIR}"/Muttrc.mbox Muttrc
	else
		insinto /etc/mutt
		doins "${FILESDIR}"/Muttrc
	fi

	# A newer file is provided by app-misc/mime-types. So we link it.
	rm "${ED}"/etc/${PN}/mime.types
	dosym /etc/mime.types /etc/${PN}/mime.types

	# A man-page is always handy, so fake one
	if use !doc; then
		make -C doc DESTDIR="${D}" muttrc.man || die
		# make the fake slightly better, bug #413405
		sed -e 's#@docdir@/manual.txt#http://www.mutt.org/doc/devel/manual.html#' \
			-e 's#in @docdir@,#at http://www.mutt.org/,#' \
			-e "s#@sysconfdir@#${EPREFIX}/etc/${PN}#" \
			-e "s#@bindir@#${EPREFIX}/usr/bin#" \
			doc/mutt.man > mutt.1
		cp doc/muttbug.man flea.1
		cp doc/muttrc.man muttrc.5
		doman mutt.1 flea.1 muttrc.5
	else
		# nuke manpages that should be provided by an MTA, bug #177605
		rm "${ED}"/usr/share/man/man5/{mbox,mmdf}.5 \
			|| ewarn "failed to remove files, please file a bug"
	fi

	if use !prefix ; then
		fowners root:mail /usr/bin/mutt_dotlock
		fperms g+s /usr/bin/mutt_dotlock
	fi

	dodoc BEWARE COPYRIGHT ChangeLog NEWS OPS* PATCHES README* TODO VERSION
}

pkg_postinst() {
	echo
	elog "If you are new to mutt you may want to take a look at"
	elog "the Gentoo QuickStart Guide to Mutt E-Mail:"
	elog "   http://www.gentoo.org/doc/en/guide-to-mutt.xml"
	echo
}

pkg_info()
{
	einfo "`mutt -v`"
}
