# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/www-servers/apache/apache-2.4.2.ebuild,v 1.1 2012/04/20 03:58:46 patrick Exp $

EAPI="2"

# latest gentoo apache files
GENTOO_PATCHSTAMP="20120401"
GENTOO_DEVELOPER="patrick"
GENTOO_PATCHNAME="gentoo-apache-2.4.1"

# IUSE/USE_EXPAND magic
IUSE_MPMS_FORK="itk peruser prefork"
IUSE_MPMS_THREAD="event worker"

# << obsolete modules:
# authn_default authz_default mem_cache 
# mem_cache is replaced by cache_disk
# >> added modules for reason:
# compat: compatibility with 2.2 access control (remove from critical when config is fixed)
# authz_host: new module for access control
# authn_core: functionality provided by authn_alias in previous versions
# authz_core: ? 
# cache_disk: replacement for mem_cache
# socache_shmcb: shared object cache provider. Seems to be popular (not SSL dependent).
# unixd: fixes startup error: Invalid command 'User'
IUSE_MODULES="access_compat actions alias asis auth_basic auth_digest authn_alias authn_anon
authn_core authn_dbd authn_dbm authn_file authz_core authz_dbm
authz_groupfile authz_host authz_owner authz_user autoindex cache cache_disk cern_meta
charset_lite cgi cgid dav dav_fs dav_lock dbd deflate dir dumpio
env expires ext_filter file_cache filter headers ident imagemap include info
log_config log_forensic logio mime mime_magic negotiation proxy
proxy_ajp proxy_balancer proxy_connect proxy_ftp proxy_http proxy_scgi rewrite
reqtimeout setenvif speling socache_shmcb status substitute unique_id userdir usertrack
unixd version vhost_alias"
# The following are also in the source as of this version, but are not available
# for user selection:
# bucketeer case_filter case_filter_in echo http isapi optional_fn_export
# optional_fn_import optional_hook_export optional_hook_import

# inter-module dependencies
# TODO: this may still be incomplete
MODULE_DEPENDS="
	dav_fs:dav
	dav_lock:dav
	deflate:filter
	cache_disk:cache
	ext_filter:filter
	file_cache:cache
	log_forensic:log_config
	logio:log_config
	cache_disk:cache
	mime_magic:mime
	proxy_ajp:proxy
	proxy_balancer:proxy
	proxy_connect:proxy
	proxy_ftp:proxy
	proxy_http:proxy
	proxy_scgi:proxy
	substitute:filter
"

# module<->define mappings
MODULE_DEFINES="
	auth_digest:AUTH_DIGEST
	authnz_ldap:AUTHNZ_LDAP
	cache:CACHE
	cache_disk:CACHE
	dav:DAV
	dav_fs:DAV
	dav_lock:DAV
	file_cache:CACHE
	info:INFO
	ldap:LDAP
	proxy:PROXY
	proxy_ajp:PROXY
	proxy_balancer:PROXY
	proxy_connect:PROXY
	proxy_ftp:PROXY
	proxy_http:PROXY
	ssl:SSL
	status:STATUS
	suexec:SUEXEC
	userdir:USERDIR
"

# critical modules for the default config
MODULE_CRITICAL="
	authn_core
	authz_core
	authz_host
	dir
	mime
	unixd
"

inherit eutils apache-2

DESCRIPTION="The Apache Web Server."
HOMEPAGE="http://httpd.apache.org/"

# some helper scripts are Apache-1.1, thus both are here
LICENSE="Apache-2.0 Apache-1.1"
SLOT="2"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~sparc-fbsd ~x86-fbsd"
IUSE=""

DEPEND="${DEPEND}
	>=dev-libs/openssl-0.9.8m
	apache2_modules_deflate? ( sys-libs/zlib )"

# dependency on >=dev-libs/apr-1.4.5 for bug #368651
RDEPEND="${RDEPEND}
	>=dev-libs/apr-1.4.5
	>=dev-libs/openssl-0.9.8m
	apache2_modules_mime? ( app-misc/mime-types )"

# init script fixup - should be rolled into next tarball #389965
src_prepare() {
	# the following patch can be removed once it is included in
	# GENTOO_PATCHNAME="gentoo-apache-2.4.1" ...
	if [ -f "${FILESDIR}/${GENTOO_PATCHNAME}-${GENTOO_DEVELOPER}-${GENTOO_PATCHSTAMP}-${PVR}.patch" ]; then
		epatch "${FILESDIR}/${GENTOO_PATCHNAME}-${GENTOO_DEVELOPER}-${GENTOO_PATCHSTAMP}-${PVR}.patch" \
			|| die "epatch failed"
	fi
	apache-2_src_prepare
	sed -i -e 's/! test -f/test -f/' "${GENTOO_PATCHDIR}"/init/apache2.initd || die "Failed to fix init script"
}

src_install() {
	apache-2_src_install
	for i in /usr/bin/{htdigest,logresolve,htpasswd,htdbm,ab,httxt2dbm}; do
		rm "${D}"/$i || die "Failed to prune apache-tools bits"
	done
	for i in /usr/share/man/man8/{rotatelogs.8,htcacheclean.8}; do
		rm "${D}"/$i || die "Failed to prune apache-tools bits"
	done
	for i in /usr/share/man/man1/{logresolve.1,htdbm.1,htdigest.1,htpasswd.1,dbmmanage.1,ab.1}; do
		rm "${D}"/$i || die "Failed to prune apache-tools bits"
	done
	for i in /usr/sbin/{checkgid,fcgistarter,htcacheclean,rotatelogs}; do
		rm "${D}/"$i || die "Failed to prune apache-tools bits"
	done

	# well, actually installing things makes them more installed, I guess?
	cp "${S}"/support/apxs "${D}"/usr/sbin/apxs || die "Failed to install apxs"
	chmod 0755 "${D}"/usr/sbin/apxs

	# for previous patch to 40_mod_ssl.conf
	if use ssl; then
		dodir /var/run/apache_ssl_mutex || die "Failed to mkdir ssl_mutex"
	fi
}
