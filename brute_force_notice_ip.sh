#!/bin/sh
#######################################################################
#Script Name: brute_force_notice
#Version: 2.5
#Description: Directadmin BF email notice for auto blocking of ips
#Last Modify Date: 01062021
#Author:Brent Dacus
#Email:brent[at]thedacus[dot]net
#######################################################################
#                       Variables                                     #
#######################################################################
nofiy_by_email=1
#give your server a name for easy idenfication
server=$(hostname -s)
domain=$(hostname -d)
#where you want the email to be sent to
email=tech@delainhosting.com
abuseipdb_key=c13866e213ef23a0fbf2c57cd6474d63477dda0767a2a088249de1151f269157c48ab70a4dc0c531
#######################################################################
#                       Main                                          #
#######################################################################
abuserpt=$(curl -G https://api.abuseipdb.com/api/v2/check \
  --data-urlencode "ipAddress=${value}" \
  -d maxAgeInDays=90 \
  -H "Key: $abuseipdb_key" \
  -H "Accept: application/json" | jq '.data' | tr -d '[]''\,''{}''\"')

#######################################################################
#                       Main                                          #
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
