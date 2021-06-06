#!/bin/sh
#######################################################################
# Script Name: install.sh
# Version: 2.5
# Description: directadmin script for blocking of ips and reports to 
# AbuseIPDB with csf firewall.
# Last Modify Date: 06062021
# Author(s): Alex Grebenschikov and Brent Dacus
# Email:brent[at]thedacus[dot]net
#######################################################################
csf="/usr/sbin/csf"
dir="/usr/local/directadmin/scripts/custom/"
da_conf="/usr/local/directadmin/conf/directadmin.conf"
csf_conf="/etc/csf/csf.conf"
csf_pignore="/etc/csf/csf.pignore"

do_install() {
    echo "[OK] Installing ${1} into ${dir}"
    if [ -f "${1}" ]; then
        cp -f "${1}" "${1}.bak"
        chmod 600 "${1}.bak"
    fi
    wget --no-check-certificate -q -O "${1}" "${2}"
    chmod 700 "${1}"
    chown diradmin:diradmin "${1}"
}

csf_install() {
    echo "[NOTICE] csf/LFD was not found on your server! Going to install it..."

    [ -d "/usr/local/src/csf" ] && rm -rf /usr/local/src/csf
    cd /usr/local/src
    wget --no-check-certificate -q https://download.configserver.com/csf.tgz -O csf.tgz
    tar -xzf csf.tgz

    [ -d "/usr/local/src/csf" ] || die "[ERROR] csf/LFD failed to unpack! Terminating..." 2
    cd /usr/local/src/csf

    c=$(./csftest.pl | grep -c "RESULT: csf should function on this server")
    if [ "$c" != "1" ]; then
        echo ""
        echo "[WARNING] There are some possible issues with csf/LFD on your server:"
        echo "Check it now:"
        ./csftest.pl
        echo ""
        exit 2
    fi

    echo "[OK] csf/LFD check passed, going further with installation..."
    sh ./install.sh

    [ -x "${csf}" ] || die "[ERROR] csf/LFD failed to install! Terminating..." 2

    echo "[OK] Updating a list of trusted binaries in ${csf_pignore}"
    wget --no-check-certificate -q https://raw.githubusercontent.com/bdacus01/directadmin-bfm-csf/master/csf.pignore.custom -O csf.pignore.custom
    cat csf.pignore.custom >>"${csf_pignore}"
    rm -f csf.pignore.custom

    grep -E -v "^#|^$" "${csf_pignore}" | sort | uniq | tee "${csf_pignore}~bak"
    mv -f "${csf_pignore}~bak" "${csf_pignore}"

    echo "[NOTICE] csf/LFD was installed! Configuration file can be found under ${csf_conf}"
    echo ""
}

csf_reconfig() {
    cp -pf "${csf_conf}" "${csf_conf}~$(date +%s)"
    echo "[OK] Disabling emails from csf/LFD about temporary blocks of an IP brute-forcing server"
    perl -pi -e 's#^LF_EMAIL_ALERT = "1"#LF_EMAIL_ALERT = "0"#' "${csf_conf}"
    echo "[OK] Disabling emails from csf/LFD about temporary blocks of an IP attacking Apache"
    perl -pi -e 's#^LT_EMAIL_ALERT = "1"#LT_EMAIL_ALERT = "0"#' "${csf_conf}"
    echo "[OK] Disabling email from csf/LFD about permament blocks of an IP"
    perl -pi -e 's#^LF_PERMBLOCK_ALERT = "1"#LF_PERMBLOCK_ALERT = "0"#' "${csf_conf}"
    echo "[OK] Disabling csf/LFD from scanning logs, directadmin will do it instead"
    perl -pi -e 's/LF_TRIGGER = ".*"/LF_TRIGGER = "0"/' "${csf_conf}"
    perl -pi -e 's/LF_SSHD = ".*"/LF_SSHD = "0"/' "${csf_conf}"
    perl -pi -e 's/LF_FTPD = ".*"/LF_FTPD = "0"/' "${csf_conf}"
    perl -pi -e 's/LF_SMTPAUTH = ".*"/LF_SMTPAUTH = "0"/' "${csf_conf}"
    perl -pi -e 's/LF_EXIMSYNTAX = ".*"/LF_EXIMSYNTAX = "0"/' "${csf_conf}"
    perl -pi -e 's/LF_POP3D = ".*"/LF_POP3D = "0"/' "${csf_conf}"
    perl -pi -e 's/LF_IMAPD = ".*"/LF_IMAPD = "0"/' "${csf_conf}"
    perl -pi -e 's/LF_HTACCESS = ".*"/LF_HTACCESS = "0"/' "${csf_conf}"
    perl -pi -e 's/LF_MODSEC = ".*"/LF_MODSEC = "0"/' "${csf_conf}"
    perl -pi -e 's/LF_dirECTADMIN = ".*"/LF_dirECTADMIN = "0"/' "${csf_conf}"
    perl -pi -e 's/CC_SRC = "1"/CC_SRC = "2"/g' "${csf_conf}"
    perl -pi -e 's/CC_DENY = ""/CC_DENY = "RU,CN,TR,IR,IQ,ID,KP"/g' "${csf_conf}"

    echo "[OK] Opening passive ports for FTP incoming connections"
    grep -q -o "^TCP_IN.*,35000:35999" "${csf_conf}" || perl -pi -e 's/^TCP_IN = "(.*)"$/TCP_IN = "$1,35000:35999"/' "${csf_conf}"
    grep -q -o "^TCP6_IN.*,35000:35999" "${csf_conf}" || perl -pi -e 's/^TCP6_IN = "(.*)"$/TCP6_IN = "$1,35000:35999"/' "${csf_conf}"

    echo "[OK] Opening passive ports for outgoing connections"
    grep -q -o "^TCP_OUT.*,35000:65535" "${csf_conf}" || perl -pi -e 's/^TCP_OUT = "(.*)"$/TCP_OUT = "$1,35000:65535"/' "${csf_conf}"
    grep -q -o "^TCP6_OUT.*,35000:65535" "${csf_conf}" || perl -pi -e 's/^TCP6_OUT = "(.*)"$/TCP6_OUT = "$1,35000:65535"/' "${csf_conf}"

    echo "[OK] Enabling csf/LFD"
    perl -pi -e 's/^TESTING = "1"/TESTING = "0"/' "${csf_conf}"
    perl -pi -e 's/^RESTRICT_SYSLOG = "0"/RESTRICT_SYSLOG = "3"/' "${csf_conf}"

    echo ""
    SSHD_PORT=$(grep "^Port" /etc/ssh/sshd_config | tail -1 | awk '{print $2}')
    [ -n "${SSHD_PORT}" ] || SSHD_PORT=22
    echo "[IMPORTANT] Your SSH PORT is ${SSHD_PORT}, it should be listed below as allowed"

    echo ""
    echo "[OK] A list of opened ports in firewall"
    egrep "^(UD|TC)P(|6)_(IN|OUT)" "${csf_conf}" --color
    echo ""

    service lfd restart >/dev/null 2>&1
    service csf restart >/dev/null 2>&1
}

da_set_conf() {
    local option=$1
    local value=$2
    echo "[OK] Setting ${option} to ${value} in ${da_conf}"
    grep -q -m1 "^${option}=" "${da_conf}" && perl -pi -e "s#${option}=.*#${option}=${value}#" "${da_conf}" || echo "${option}=${value}" | tee -a "${da_conf}"
}

da_reconfig() {
    cp -pf "${da_conf}" "${da_conf}~$(date +%s)"
    da_set_conf bruteforce 1
    da_set_conf brutecount 3
    da_set_conf ip_brutecount 3
    da_set_conf brute_dos_count 3
    da_set_conf user_brutecount 3
    da_set_conf brute_force_log_scanner 1
    da_set_conf brute_force_scan_apache_logs 2
    da_set_conf brute_force_time_limit 3600
    da_set_conf brute_force_apache_log_list_update_interval 10
    da_set_conf hide_brute_force_notifications 1
    da_set_conf show_info_in_header 0
    da_set_conf exempt_local_block 1
    da_set_conf clear_brute_log_time 1
    da_set_conf clear_brute_log_entry_time 1
    da_set_conf unblock_brute_ip_time 0   #Never
    da_set_conf clear_blacklist_ip_time 0 #Never
    da_set_conf ip_blacklist /etc/blocked_ips
	da_set_conf ip_whitelist /etc/whitelist_ips
}

die() {
    echo "$1" echo ""
    exit "$2"
}

[ -x "${csf}" ] || csf_install

[ -x "/usr/local/directadmin/directadmin" ] || die "[ERROR] directadmin not found! You should install it first!" 1
cd "${dir}" || die "[ERROR] Could not change directory to ${dir}" 1

do_install "block_ip.sh" "http://files.delaintech.com/csf/block_ip.sh"
do_install "unblock_ip.sh" "http://files.delaintech.com/csf/unblock_ip.sh"
do_install "show_blocked_ips.sh" "http://files.delaintech.com/csf/show_blocked_ips.sh"
do_install "brute_force_notice_ip.sh" "http://files.delaintech.com/csf/brute_force_notice_ip.sh"

[ -f "/etc/blocked_ips" ] || touch /etc/blocked_ips
[ -f "/etc/whitelist_ips" ] || touch /etc/whitelist_ips

csf_reconfig
da_reconfig

echo "[OK] Scripts installed!"
echo ""
echo "[INFO] Installed settings in directadmin:"
/usr/local/directadmin/directadmin c | sort | grep -E --color "bruteforce|brute_force_log_scanner|brute_force_scan_apache_logs|brute_force_time_limit|ip_brutecount|unblock_brute_ip_time|user_brutecount|hide_brute_force_notifications|clear_brute_log_time="
echo ""
echo "You can change them in directadmin interface at admin level or in directadmin.conf"
echo ""
echo "Installation complete!"
echo ""
exit 0
