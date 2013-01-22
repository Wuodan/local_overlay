# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Original Author: root
# Purpose: 
#

# compose IUSE and REQUIRED_USE from the categories
REQUIRED_USE+=" || ("
for useexp in ${IUSE_EXPAND}; do
	USE_TEMP="\$IUSE_$useexp"
	for iuse in `eval echo "\$USE_TEMP"`; do
		if [ "${iuse:0:1}" = '+' ]; then
			IUSE+=" ${iuse:0:1}compat_drivers_${useexp}_${iuse:1}"
			REQUIRED_USE+=" compat_drivers_${useexp}_${iuse:1}"
		else
			IUSE+=" compat_drivers_${useexp}_${iuse}"
			REQUIRED_USE+=" compat_drivers_${useexp}_${iuse}"
		fi
	done
done
REQUIRED_USE+=" )"

CPWL_MAKEFILES="
	MAKEFILE
	COMPAT_CONFIG_CW
	DRIVERS_MAKEFILE
	ATH_MAKEFILE
	ATH9K_MAKEFILE
	BRCM80211_MAKEFILE
	RT2X00_MAKEFILE
	TI_MAKEFILE
	NET_WIRELESS_MAKEFILE
	EEPROM_MAKEFILE
	DRIVERS_NET_ATHEROS
	DRIVERS_NET_BROADCOM
	DRIVERS_NET_USB_MAKEFILE
	SSB_MAKEFILE
	BCMA_MAKEFILE"

MAKEFILE="Makefile"
COMPAT_CONFIG_CW="config.mk"
DRIVERS_MAKEFILE="drivers/net/wireless/Makefile"
ATH_MAKEFILE="drivers/net/wireless/ath/Makefile"
ATH9K_MAKEFILE="drivers/net/wireless/ath/ath9k/Makefile"
BRCM80211_MAKEFILE="drivers/net/wireless/brcm80211/Makefile"
RT2X00_MAKEFILE="drivers/net/wireless/rt2x00/Makefile"
TI_MAKEFILE="drivers/net/wireless/ti/Makefile"
NET_WIRELESS_MAKEFILE="net/wireless/Makefile"
EEPROM_MAKEFILE="drivers/misc/eeprom/Makefile"
DRIVERS_NET_ATHEROS="drivers/net/ethernet/atheros/Makefile"
DRIVERS_NET_BROADCOM="drivers/net/ethernet/broadcom/Makefile"
DRIVERS_NET_USB_MAKEFILE="drivers/net/usb/Makefile"
SSB_MAKEFILE="drivers/ssb/Makefile"
BCMA_MAKEFILE="drivers/bcma/Makefile"

function select_drivers_from_makefile
{
	local makefile="$1"
	shift
	local configs=""
	for i in $@; do
		[ "${configs}" != '' ] && configs+='|'
		configs+="${i}"
	done
	sed -r "/${configs}/!d"  ${makefile} > ${makefile}.tmp || die
	mv ${makefile}.tmp ${makefile} || die
}

function disable {
	eval "CPWL_DISABLE_${CPWL_MODULE}+=\"${*}\"" || die
}

function disable_makefile {
	echo > $1 || die
}

function disable_staging
{
	# perl -i -ne 'print if ! /CONFIG_COMPAT_STAGING/ ' "${MAKEFILE}"
	sed -i '/CONFIG_COMPAT_STAGING/d' "${MAKEFILE}" || die
}

function disable_update-initramfs
{
	# perl -i -ne 'print if ! /update-initramfs/' "${MAKEFILE}"
	sed -i '/update-initramfs/d' "${MAKEFILE}" || die
}

function disable_lib80211
{
	# perl -i -ne 'print if ! /LIB80211/ ' $NET_WIRELESS_MAKEFILE
	sed -i '/LIB80211/d' "${NET_WIRELESS_MAKEFILE}" || die

function disable_b44 {
	# perl -i -ne 'print if ! /CONFIG_B44/ ' $DRIVERS_NET_BROADCOM
	sed -i '/CONFIG_B44/d' "${DRIVERS_NET_BROADCOM}" || die
}

function disable_ssb
{
	disable_makefile ${SSB_MAKEFILE}
	# perl -i -ne 'print if ! /drivers\/ssb\//' "${MAKEFILE}"
	sed -i '/drivers\/ssb\//d' "${MAKEFILE}" || die
}

function disable_bcma
{
	disable_makefile ${BCMA_MAKEFILE}
	# perl -i -ne 'print if ! /drivers\/bcma\//' "${MAKEFILE}"
	sed -i '/drivers\/bcma\//d' "${MAKEFILE}" || die
}

function disable_rfkill
{
	# perl -i -ne 'print if ! /CONFIG_COMPAT_RFKILL/' "${MAKEFILE}"
	sed -i '/CONFIG_COMPAT_RFKILL/d' "${MAKEFILE}" || die
}

function disable_eeprom
{
	disable_makefile ${EEPROM_MAKEFILE} || die
	# perl -i -ne 'print if ! /drivers\/misc\/eeprom\//' "${MAKEFILE}"
	sed -i '/drivers\/misc\/eeprom\//d' "${MAKEFILE}" || die
}

function disable_usbnet
{
	disable_makefile ${DRIVERS_NET_USB_MAKEFILE} || die
	# perl -i -ne 'print if ! /drivers\/net\/usb\//' "${MAKEFILE}"
	sed -i '/drivers\/net\/usb\//d' "${MAKEFILE}" || die
}

# this function is twice in driver-select script!?!
function disable_usbnet {
	# perl -i -ne 'print if ! /CONFIG_COMPAT_NET_USB_MODULES/' "${MAKEFILE}"
	sed -i '/CONFIG_COMPAT_NET_USB_MODULES/d' "${MAKEFILE}" || die
} 

function disable_ethernet {
	# perl -i -ne 'print if ! /CONFIG_COMPAT_NETWORK_MODULES/' "${MAKEFILE}"
	sed -i '/CONFIG_COMPAT_NETWORK_MODULES/d' "${MAKEFILE}" || die
} 

function disable_var_03 {
	# perl -i -ne 'print if ! /CONFIG_COMPAT_VAR_MODULES/' "${MAKEFILE}"
	sed -i '/CONFIG_COMPAT_VAR_MODULES/d' "${MAKEFILE}" || die
} 

function disable_bt {
	# perl -i -ne 'print if ! /CONFIG_COMPAT_BLUETOOTH/' "${MAKEFILE}"
	sed -i '/CONFIG_COMPAT_BLUETOOTH/d' "${MAKEFILE}" || die
} 

function disable_80211 {
	# perl -i -ne 'print if ! /CONFIG_COMPAT_WIRELESS/' "${MAKEFILE}"
	sed -i '/CONFIG_COMPAT_WIRELESS/d' "${MAKEFILE}" || die
}

# new function, not in driver-select
function disable_ath9k_rate_control {
	# perl -i -ne 'print if ! /CONFIG_COMPAT_ATH9K_RATE_CONTROL/ ' $COMPAT_CONFIG_CW
	sed -i '/CONFIG_COMPAT_ATH9K_RATE_CONTROL/d' "${COMPAT_CONFIG_CW}" || die
}

function select_drivers {
	eval "CPWL_DRIVERS_MAKEFILE+=\"${*}\"" || die
}

function select_ath_driver {
	eval "CPWL_ATH_MAKEFILE+=\"${*}\"" || die
}

function select_brcm80211_driver {
	eval "CPWL_BRCM80211_MAKEFILE+=\"${*}\"" || die
}

function select_ti_drivers {
	select_drivers CONFIG_WL_TI
	eval "CPWL_TI_MAKEFILE+=\"${*}\"" || die
}

function set_flag {
	# clear/set global vars
	CPWL_MODULE=$1
	case $1 in
		ath5k)
			disable staging usbnet ethernet bt update-initramfs var_03 || die
			select_drivers		CONFIG_ATH_COMMON || die
			select_ath_driver	CONFIG_ATH5K || die
			# disable lib80211 ssb bcma usbnet eeprom update-initramfs
			;;
		ath9k)
			disable staging usbnet ethernet bt update-initramfs var_03 || die
			select_drivers		CONFIG_ATH_COMMON || die
			select_ath_driver CONFIG_ATH9K_HW || die
			;;
		ath9k_ap)
			disable staging usbnet ethernet bt update-initramfs var_03 || die
			select_drivers		CONFIG_ATH_COMMON || die
			select_ath_driver CONFIG_ATH9K_HW || die
			disable ath9k_rate_control || die
			;;
		carl9170)
			disable staging usbnet ethernet bt update-initramfs var_03 || die
			select_drivers		CONFIG_ATH_COMMON || die
			select_ath_driver	CONFIG_CARL9170 || die
			;;
		ath9k_htc)
			disable staging usbnet ethernet bt update-initramfs var_03 || die
			select_drivers		CONFIG_ATH_COMMON || die
			select_ath_driver CONFIG_ATH9K_HW || die
			;;
		ath6kl)
			disable staging usbnet ethernet bt update-initramfs var_03 || die
			select_drivers		CONFIG_ATH_COMMON || die
			select_ath_driver	CONFIG_ATH6KL || die
			;;
		brcmsmac)
			disable staging usbnet ethernet bt update-initramfs var_03 || die
			select_drivers		CONFIG_BRCMSMAC || die
			select_brcm80211_driver	CONFIG_BRCMSMAC CONFIG_BRCMUTIL || die
			;;
		brcmfmac)
			disable staging usbnet ethernet bt update-initramfs var_03 || die
			select_drivers		CONFIG_BRCMFMAC || die
			select_brcm80211_driver	CONFIG_BRCMSMAC CONFIG_BRCMUTIL || die
			;;
		zd1211rw)
			select_drivers		CONFIG_COMPAT_ZD1211RW || die
			disable staging lib80211 ssb bcma usbnet eeprom update-initramfs || die
			;;
		b43)
			disable staging usbnet ethernet bt update-initramfs || die
			disable eeprom lib80211 || die
			select_drivers		CONFIG_B43 || die
			;;
		rt2x00)
			select_drivers		CONFIG_RT2X00 || die
			disable staging usbnet ethernet bt update-initramfs || die
			disable lib80211 ssb bcma usbnet update-initramfs || die
			;;
		wl1251)
			select_ti_drivers	CONFIG_WL1251 || die
			disable staging lib80211 ssb bcma usbnet eeprom update-initramfs || die
			;;
		wl12xx)
			select_ti_drivers	CONFIG_WL12XX || die
			disable staging lib80211 ssb bcma usbnet eeprom update-initramfs || die
			;;
		wl18xx)
			select_ti_drivers	CONFIG_WL18XX || die
			disable staging lib80211 ssb bcma usbnet eeprom update-initramfs || die
			;;
	# Ethernet and Bluetooth drivers
		atl1)
			disable staging usbnet var_03 bt rfkill 80211 b44 || die
			echo -e "obj-\$(CONFIG_ATL1) += atlx/" > $DRIVERS_NET_ATHEROS || die
			;;
		atl2)
			disable staging usbnet var_03 bt rfkill 80211 b44 || die
			echo -e "obj-\$(CONFIG_ATL2) += atlx/" > $DRIVERS_NET_ATHEROS || die
			;;
		atl1e)
			disable staging usbnet var_03 bt rfkill 80211 b44 || die
			echo -e "obj-\$(CONFIG_ATL1E) += atl1e/" > $DRIVERS_NET_ATHEROS || die
			;;
		atl1c)
			disable staging usbnet var_03 bt rfkill 80211 b44 || die
			echo -e "obj-\$(CONFIG_ATL1C) += atl1c/" > $DRIVERS_NET_ATHEROS || die
			;;
		atlxx)
			select_drivers		CONFIG_ATL1 CONFIG_ATL2 CONFIG_ATL1E CONFIG_ALX || die
			disable staging usbnet var_03 bt rfkill 80211 b44 update-initramfs || die
			;;
		bt)
			select_drivers 		CONFIG_BT || die
			disable ssb bcma usbnet eeprom update-initramfs ethernet staging 80211 || die
			;;
		i915)
			# rfkill may be needed if you enable b44 as you may have b43
			disable ethernet staging usbnet var_03 bt rfkill 80211 || die
			;;
		drm)
			# rfkill may be needed if you enable b44 as you may have b43
			disable ethernet staging usbnet var_03 bt rfkill 80211 || die
			;;
		*)
			die "Unsupported driver"
			exit
			;;
	esac
}
