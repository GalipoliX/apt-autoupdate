#!/bin/bash
#################################################################################
# Script:       check-autoupdate.sh
# Author:       Michael Geschwinder (Maerkischer-Kreis)
# Description:  Plugin for Nagios to check the autoupdate Script result
#              
# History:
# 20230520      Created check
#
#################################################################################
# Usage:        ./check-autoupdate.sh
#################################################################################


##########################################################
# Nagios exit codes and PATH
##########################################################
STATE_OK=0              # define the exit code if status is OK
STATE_WARNING=1         # define the exit code if status is Warning
STATE_CRITICAL=2        # define the exit code if status is Critical
STATE_UNKNOWN=3         # define the exit code if status is Unknown


##########################################################
# Debug Ausgabe aktivieren
##########################################################
DEBUG=0

##########################################################
# Debug output function
##########################################################
function debug_out {
        if [ $DEBUG -eq "1" ]
        then
                datestring=$(date +%d%m%Y-%H:%M:%S)
                echo -e $datestring DEBUG: $1
        fi
}

###########################################################
# Check if programm exist $1
###########################################################
function check_prog {
        if ! `which $1 1>/dev/null`
        then
                echo "UNKNOWN: $1 does not exist, please check if command exists and PATH is correct"
                exit ${STATE_UNKNOWN}
        else
                debug_out "OK: $1 does exist"
        fi
}


if [ -f /opt/autoupgrade-ok ]
then
	cat  /opt/autoupgrade-ok
	exit $STATE_OK
elif [ -f /opt/autoupgrade-failed ]
then
	echo "Last autoupgrade failed at $(cat /opt/autoupgrade-failed)!"
	exit $STATE_CRITICAL
else
	echo "Cant find autoupgrade info! Has the Script run?"
	exit $STATE_UNKNOWN
fi

