#!/bin/bash
#################################################################################
# Script:       apt-autoupdate.sh
# Author:       Michael Geschwinder (Maerkischer-Kreis)
# Description:  Plugin for automaticly updating your apt based servers
#               
# History:
# 20230520      Created script
#
#################################################################################
# Usage:        ./apt-autoupdate.sh
# 		The Script is ment to be run with cronjob as root
#################################################################################
PATH=$PATH:/usr/sbin:/bin # Set path


# Set the variables for mails.
admin_mail="admin@domain.de"
sender_mail="autoupdate@domain.de"

# Should Server reboot if requiered and update successfull
autoreboot="true"
# Set Upgrade Mode: full or safe
mode="full"

# Create a temporary path in /tmp to write a temporary log
tmpfile=$(mktemp)
# Set the hostname to variable
hostname=$(hostname)
# Enable Debug output to console
DEBUG=1

##########################################################
# Debug output function
##########################################################
function write_out {
	datestring=$(date +%d%m%Y-%H:%M:%S)

	if [ $DEBUG -eq "1" ]
	then
		echo -e $datestring DEBUG: $1
	fi
	if [ "$1" == "" ]
	then
		echo "" >> ${tmpfile}
	else
		echo -e "$datestring: $1" >> ${tmpfile}
	fi
}

###########################################################
# Check if programm exist $1
###########################################################
function check_prog {
	if ! `which $1 1>/dev/null`
	then
		write_out "UNKNOWN: $1 does not exist, please check if command exists and PATH is correct"
		exit 1
	else
		write_out "OK: $1 does exist"
	fi
}


echo -e "##################################################################\n" >> ${tmpfile}


################################################################################
# check if requiered programs are installed
################################################################################
for cmd in needrestart aptitude;do check_prog ${cmd};done;




write_out "Starting automatic Upgrade in mode $mode"
write_out "Automatic reboot is set to $autoreboot \n"

echo -e "##################################################################\n" >> ${tmpfile}

# Run the commands to update the system
write_out "Running aptitupde update \n"
aptitude update >> ${tmpfile} 2>&1
write_out ""
if [ "$mode" == "full" ]
then
	write_out "Running aptitude full-upgrade \n"
	aptitude -y full-upgrade >> ${tmpfile} 2>&1
elif [ "$mode" == "safe" ]
then
	write_out "Running aptitude safe-upgrade \n"
	aptitude -y safe-upgrade >> ${tmpfile} 2>&1
fi

write_out ""
write_out "Running aptitude clean \n"
aptitude clean >> ${tmpfile} 2>&1

#echo "E: Testerror" >> ${tmpfile}

echo -e "##################################################################\n" >> ${tmpfile}


# Checking for errors and writing status files
if grep -q 'E: \|W: ' ${tmpfile} ; 
then
	write_out "Something went wrong!" >> ${tmpfile}

	write_out "Creating status file for monitoring"
	echo $(date) > /opt/autoupgrade-failed
	if [ -f /opt/autoupgrade-ok ]; then rm /opt/autoupgrade-ok; fi;

	write_out "Skipping all further steps and sending mail!"
	mail -s "Automatic upgrade of server $hostname FAILED $(date)" -a "From: Autoupdate - $hostname <$sender_mail>" ${admin_mail} < ${tmpfile}

else
	write_out "Everything seems fine!"

	write_out "Creating status file for monitoring"
	info=$(cat $tmpfile | grep "packages upgraded")
	echo "$info - $(date)" > /opt/autoupgrade-ok
	write_out "Result: $info"
	if [ -f /opt/autoupgrade-failed ]; then rm /opt/autoupgrade-failed; fi;
	


# Doing the reboot part	
	write_out "Checking if reboot is enabled and required"
	if [ "$autoreboot" == "false" ]
	then
		write_out "Auto reboot is disabled! No further actions!"
	elif [ "$autoreboot" == "true" ]
	then
		write_out "Auto reboot is enabled! Checking if needed ...."
		needrestart_out=$(needrestart -p 2>/dev/null)
		needrestart_out=$(echo $needrestart_out | cut -d "-" -f2- | cut -d "|" -f1)
		needrestart -p 1>/dev/null 2>/dev/null
		rebootreq=$(echo $?)
		write_out "Reboot: $rebootreq - $needrestart_out"

		if [ "$rebootreq" == "0" ]
		then
			write_out "No restart is required!"
		else
			write_out "Restart required! Good night!"
			write_out "I was alive for $(uptime -p) "
			write_out "See you on the other side!"
			mail -s "Automatic upgrade of server $hostname succesfully $(date)" -a "From: Autoupdate - $hostname <$sender_mail>" ${admin_mail} < ${tmpfile}
			rm -f ${tmpfile}
			# Sleeping 15 seconds for mail to be send 
			sleep 15
			reboot
		fi
	
	fi

	mail -s "Automatic upgrade of server $hostname succesfully $(date)" -a "From: Autoupdate - $hostname <$sender_mail>" ${admin_mail} < ${tmpfile}
fi

# Remove the temporary log file in temporary path.
rm -f ${tmpfile}
