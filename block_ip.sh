#!/bin/sh
#######################################################################
# Script Name: block_ip
# Version: 2.5
# Description: Directadmin script for blocking of ips and reports to
# AbuseIPDB with csf firewall.
# Last Modify Date: 06062021
# Author:Brent Dacus
# Email:brent[at]thedacus[dot]net
#######################################################################
#                       Variables                                     #
#######################################################################
bf=/etc/blocked_ips
ef=/etc/whitelist_ips
caf=/etc/csf/csf.allow
cdf=/etc/csf/csf.deny
abuseipdb_key=0cddfe70a4a30f99e43dc693f3a5d29e0be9db6e270d5a209fee18880084d509811ffffcafcd8b77
#######################################################################
#                       Main                                          #
#######################################################################
### To add IP on cmd line.
if [ "${1}" ]; then
  ip="${1}"
fi
### Do we have an IP to block?
if [ -z "${ip}" ]; then
  printf "We have no IP to block! Exiting.\n"
  exit 1
fi
### Do we have a block file?
if [ ! -e "${bf}" ]; then
  printf "Cannot find %s file.\n" "${bf}"
  exit 2
fi
### Do we have an whitelist file?
if [ ! -e "${ef}" ]; then
  printf "Cannot find %s file\n" "${ef}"
  exit 2
fi
### Make sure IP is not in DA whitelist file.
count=$(grep -E -c "${ip}(=|$)" ${ef})
if [ "$count" -gt 0 ]; then
  printf "The %s is in the whitelist (%s).\nNot blocking.\n" "${ip}" "${ef}"
  exit 3
fi
### Make sure it's not already in blocked file.
count=$(grep -E -c "${ip}(=|$)" ${bf})
if [ "$count" -gt 0 ]; then
  printf "The %s already exists in (%s).\nNot blocking.\n" "${ip}" "${bf}"
  exit 3
fi
# Is the IP whitelisted permamently by CSF?
count=$(grep -E -c "${ip}(=|$)" "${caf}")
if [ "${count}" -gt 0 ]; then
  printf "The %s already exists in (%s).\nNot blocking.\n" "${ip}" "${caf}"
  exit 4
fi
# Is the IP whitelisted permamently by CSF?
count=$(grep -E -c "${ip}(=|$)" "${cdf}")
if [ "${count}" -gt 0 ]; then
  printf "The %s already exists in (%s).\nNot blocking.\n" "${ip}" "${cdf}"
  exit 4
fi
### Add it into the blocked file.
printf "Blocking %s to Firewall now.\n" "${ip}"
echo "$ip=dateblocked=$(date +%s)" >>"${bf}"
### Add it to the CSF deny file.
csf -d "${ip}" "Blocked and sent to AbuseIPDB."
### Add it into the abuseIPDB.
curl https://api.abuseipdb.com/api/v2/report \
  --data-urlencode "ip=${ip}" \
  -d categories=15,18 \
  --data-urlencode "comment=Bruteforce and Hacking attempts." \
  -H "Key: $abuseipdb_key" \
  -H "Accept: application/json" >>/dev/null 2>&1

exit 0