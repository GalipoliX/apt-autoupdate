# apt-autoupdate
Script to automaticly update APT based Linux Servers


This Script will automaticly update your APT based Linux Servers.
Its based on the Script found at https://help.ubuntu.com/community/AutoWeeklyUpdateHowTo

It depends on the packages aptitude (not included in Ubuntu anymore by default) and needrestart to check if a reboot is needed.
To send mails, postfix must be configured properly.

After running it can send an automatic email to inform you about the result.
It also writes status files to /tmp/ directory which can be monitored with tools like nagios/icinga
