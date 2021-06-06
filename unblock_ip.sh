#!/bin/sh
#######################################################################
# Script Name: unblock_ip
# Version: 2.5
# Description: Directadmin script for unblocking of ips. Works with
# csf and deletes report at AbuseIPDB.
# Last Modify Date: 06062021
# Author:Brent Dacus
# Email:brent[at]thedacus[dot]net
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
  [ "${debug}" = "1" ] && echo "$1"
}
#######################################################################
#                       Main                                          #
#######################################################################
### To add IP on cmd line.
if [ "${1}" ]; then
  ip="${1}"
fi
if [ -z "${ip}" ]; then
  printf "We have no ip to unblock!\nExiting.\n"
  exit 1
fi
### check blocked file for ip.
count=$(grep -E -c "${ip}(=|$)" "${bf}")
if [ "${count}" -gt "0" ]; then
  de "[debug] the ip ${ip} was found in ${bf}"
  ### Remove blocked ip from block file but leave all others.
  grep -E -v "${ip}(=|$)" "${bf}" >"${bf}.temp"
  mv "${bf}.temp" "${bf}"
  unblocked=1
fi
### Remove blocked ip from CSF but leave all others.
if [ "${count}" -gt "0" ]; then
  de "[debug] the ip ${ip} was found as blocked in csf"
  ### Remove it from the CSF deny file.
  csf -dr "${ip}"
  unblocked=1
fi
### Remove blocked ip from AbuseIPDB.
if [ "${unblocked}" -gt "0" ]; then
  printf "The ip %s was unblocked and removed from AbuseIPDB.\n" "${ip}"
  curl -X DELETE https://api.abuseipdb.com/api/v2/clear-address \
    --data-urlencode "ipAddress=${ip}" \
    -H "Key: $abuseipdb_key" \
    -H "Accept: application/json" >>/dev/null 2>&1
  exit 2
else
  printf "The ip %s is not blocked.\nExiting.\n" "${ip}"
  exit 3
fi

exit