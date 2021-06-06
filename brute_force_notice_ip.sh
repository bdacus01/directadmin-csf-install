#!/bin/sh
#######################################################################
# Script Name: brute_force_notice
# Version: 2.5
# Description: Directadmin BF email notice for auto blocking of ips
# Last Modify Date: 01062021
# Author:Brent Dacus
# Email:brent[at]thedacus[dot]net
#######################################################################
#                       Variables                                     #
#######################################################################
nofiy_by_email=1
#give your server a name for easy idenfication
server=$(hostname -s)
domain=$(hostname -d)
#where you want the email to be sent to
email=tech@delainhosting.com
# Your API key for AbuseIPDB
abuseipdb_key=0cddfe70a4a30f99e43dc693f3a5d29e0be9db6e270d5a209fee18880084d509811ffffcafcd8b77
#######################################################################
#                  Main Call to AbuseIPDB API                         #
#######################################################################
abuserpt=$(curl -G https://api.abuseipdb.com/api/v2/check \
  --data-urlencode "ipAddress=${value}" \
  -d maxAgeInDays=90 \
  -H "Key: $abuseipdb_key" \
  -H "Accept: application/json" | jq '.data' | tr -d '[]''\,''{}''\"')

#######################################################################
#                       Main Email body                               #
#######################################################################
if [ "${nofiy_by_email}" -gt 0 ]; then
  echo "The ip $value has been blocked for making $count failed login attempts at $domain.
$data
See AbuseIPDB report below:
$abuserpt" | mail -s "$server:  blocked $value for $count failed attempts" $email
fi

script=/usr/local/directadmin/scripts/custom/block_ip.sh
ip=$value $script

exit $?
