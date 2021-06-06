#!/bin/sh
#######################################################################
# Script Name: show_blocked_ips
# Version: 2.5
# Description: Script to show blocked IP address by Directadmin BFM
# Last Modify Date: 06062021
# Author:Directadmin
# Email:brent[at]thedacus[dot]net
#######################################################################
#                       Variables                                     #
#######################################################################
bf=/etc/blocked_ips
#######################################################################
#                       Main                                          #
#######################################################################
printf "havedata=1\n"
cat $bf

exit 0