#!/bin/sh
#######################################################################
#Script Name: block_ip
#Version: 2.4
#Description: Directadmin script for blocking of ips and reports to #AbuseIPDB.
#Last Modify Date: 01062021
#Author:Brent Dacus
#Email:brent[at]thedacus[dot]net
#######################################################################
#                       Variables                                     #
#######################################################################
bf=/etc/blocked_ips
ef=/etc/whitelist_ips
caf=/etc/csf/csf.allow
cdf=/etc/csf/csf.deny
abuseipdb_key=c13866e213ef23a0fbf2c57cd6474d63477dda0767a2a088249de1151f269157c48ab70a4dc0c531
#######################################################################
#                       Main                                          #
#######################################################################
if [ "${1}" ]; then
  ip="${1}"
fi

if [ -z "${ip}" ]; then
  echo "We have no IP to block! Exiting..."
  exit 1
fi
### Do we have a block file?
if [ ! -e "${bf}" ]; then
  echo "Cannot find $bf file"
  exit 2
fi
### Do we have an exempt file?
if [ ! -e "${ef}" ]; then
  echo "Cannot find ${ef} file"
  exit 2
fi
### Make sure it's not in DA exempt file.
count=$(egrep -c "${ip}(=|$)" ${ef})
if [ "$count" -gt 0 ]; then
  echo "The $ip is in the exempt list (${ef}). Not blocking."
  exit 3
fi
### Make sure it's not already in blocked file.
count=$(egrep -c "${ip}(=|$)" ${bf})
if [ "$count" -gt 0 ]; then
  echo "The $ip already exists in (${bf}). Not blocking."
  exit 3
fi
# Is the IP whitelisted permamently by CSF?
count=$(egrep -c "${ip}(=|$)" "${caf}")
if [ "${count}" -gt 0 ]; then
    echo "The ${ip} already exists in (${caf}). Not blocking."
    exit 4
fi
# Is the IP whitelisted permamently by CSF?
count=$(egrep -c "${ip}(=|$)" "${cdf}")
if [ "${count}" -gt 0 ]; then
    echo "The ${ip} already exists in (${cdf}). Not blocking."
    exit 4
fi
### Add it into the blocked file.
echo "Blocking ${ip} to Firewall now."
echo "$ip=dateblocked=$(date +%s)" >>"${bf}"
### Add it into the bruteforce pf table.
csf -d "${ip}" "Blocked and sent to AbuseIPDB."
### Add it into the abuseIPDB.
curl https://api.abuseipdb.com/api/v2/report \
  --data-urlencode "ip=${ip}" \
  -d categories=15,18 \
  --data-urlencode "comment=Bruteforce and Hacking attempts." \
  -H "Key: $abuseipdb_key" \
  -H "Accept: application/json" >>/dev/null 2>&1

exit 0
