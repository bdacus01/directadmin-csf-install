#!/bin/sh
#######################################################################
# Script Name: update.sh
# Version: 2.5
# Description: Directadmin script for blocking of ips and reports to 
# AbuseIPDB with csf firewall.
# Last Modify Date: 06062021
# Author(s): Alex Grebenschikov and Brent Dacus
# Email:brent[at]thedacus[dot]net
#######################################################################
#                       Variables                                     #
#######################################################################
csf="/usr/sbin/csf"
dir="/usr/local/directadmin/scripts/custom/"
#######################################################################
#                       Main                                          #
#######################################################################
do_update() {
    printf "Updating in %s %s\n" "${dir}" "${1}"
    if [ -f "${1}" ]; then
        cp -f "${1}" "${1}.bak"
        chmod 600 "${1}.bak"
    fi
    wget --no-check-certificate -q -O "${1}" "${2}"
    chmod 700 "${1}"
    chown diradmin:diradmin "${1}"
}

die() {
    echo "$1" printf ""
    exit "$2"
}

[ -x "${csf}" ] || csf_install

[ -x "/usr/local/directadmin/directadmin" ] || die "Directadmin not found!\nYou should install it first!\n" 1
cd "${dir}" || die "Could not change directory to %s.\n" ${dir} 1

do_install "block_ip.sh" "http://files.delaintech.com/csf/block_ip.sh"
do_install "unblock_ip.sh" "http://files.delaintech.com/csf/unblock_ip.sh"
do_install "show_blocked_ips.sh" "http://files.delaintech.com/csf/show_blocked_ips.sh"
do_install "brute_force_notice_ip.sh" "http://files.delaintech.com/csf/brute_force_notice_ip.sh"

[ -f "/etc/blocked_ips" ] || touch /etc/blocked_ips
[ -f "/etc/whitelist_ips" ] || touch /etc/whitelist_ips

printf "Scripts Updated!\n***\nUpgrade complete!\n***\n"
exit 0