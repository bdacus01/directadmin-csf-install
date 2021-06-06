#!/bin/sh
#######################################################################
# Script Name: show_blocked_ips
# Version: 1.3
# Description: Script to show blocked IP address by Directadmin BFM
# Last Modify Date: 01062021
# Author:Directadmin
# Email:brent[at]thedacus[dot]net
#######################################################################
#                       Variables                                     #
#######################################################################
bf=/etc/blocked_ips
#######################################################################
#                       Main                                          #
#######################################################################
echo "havedata=1"
cat $bf

exit 0
