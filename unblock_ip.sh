#!/bin/sh
#######################################################################
#Script Name: unblock_ip
#Version: 2.4
#Description: Directadmin script for unblocking of ips. Works with
#FreeBSD pf firewall and deletes report at AbuseIPDB.
#Last Modify Date: 01062021
#Author:Brent Dacus
#Email:brent[at]thedacus[dot]net
#######################################################################
#                       Variables                                     #
#######################################################################
bf=/etc/blocked_ips
abuseipdb_key=c13866e213ef23a0fbf2c57cd6474d63477dda0767a2a088249de1151f269157c48ab70a4dc0c531
unblocked=0
#######################################################################
#                       Debug                                         #
#######################################################################
debug=0
de() {
  [ "${debug}" == "1" ] && echo "$1"
}
#######################################################################
#                       Main                                          #
#######################################################################
if [ "${1}" ]; then
  ip="${1}"
fi
if [ -z "${ip}" ]; then
  echo "We have no ip to unblock! Exiting..."
  exit 1
fi
### check blocked file for ip.
count=$(egrep -c "${ip}(=|$)" "${bf}")
if [ "${count}" -gt "0" ]; then
  de "[debug] the ip ${ip} was found in ${bf}"
  ### Remove blocked ip from file but leave all others.
  egrep -v "${ip}(=|$)" "${bf}" >"${bf}.temp"
  mv "${bf}.temp" "${bf}"
  unblocked=1
fi
### Remove blocked ip from pf table but leave all others.
if [ "${count}" -gt "0" ]; then
  de "[debug] the ip ${ip} was found as blocked in pf"
  /sbin/pfctl -t bruteforce -T delete "${ip}"
  unblocked=1
fi

if [ "${unblocked}" -gt "0" ]; then
  echo -n "the ip ${ip} was unblocked"
  ### Remove blocked ip from AbuseIPDB.
  curl -X DELETE https://api.abuseipdb.com/api/v2/clear-address \
    --data-urlencode "ipAddress=${ip}" \
    -H "Key: $abuseipdb_key" \
    -H "Accept: application/json" >>/dev/null 2>&1
  exit 0
else
  echo -n "the ip ${ip} is not blocked. exiting..."
  exit 3
fi

exit
