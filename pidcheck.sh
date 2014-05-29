#!/bin/bash

#
# Script which checks for a program's operation
# Starts the program if not running
# Stops the program if "KEEPOFF=true"
# Reports if the program needed to be started / stopped
# Processes with PID files only
# This script is ment to be run via cron
#
# Created by Milos Kaurin using the deluged script
# 2014/06/28 ; Last edit: 2014/05/29
#

# Don't touch this unless you know what you are doing
PATH=/bin:/usr/bin:/usr/local/bin

#
# Control variables
#

# Required. If we want to keep the program off, set to true
KEEPOFF=false

# Required. Do we want to send an e-mail?
SEND_MAIL=true

# Required. Program executable with parameters. USE DOUBLE QUOTES PLEASE!
RUNTHIS="/path/to/program/exec.file"
# or
# RUNTHIS="/path/to/program/exec.file -l $LOGFILE"
# depends on your executable

# Required
PIDFILE="/path/to/program/pid.file"

# Optional. Used if your program requires a logfile parameter, 
# or if you want to pipe to a logfile
LOGFILE="/path/to/program/log.file"

# Optional. Use only if your system can send out mails via the 'mail' command
# Test your system in shell: 
# echo "Test message body" | mail -s "Test message subject" "your-mail@bla.com"
MAILTO="yourmail@someaddr.com"

# Option. Mail subject
SUBJECT="Processname on $HOSTNAME"


#
# Functions
#

# Mail function
function emailthis {
    if $SEND_MAIL
        then
        echo "$@" | mail -s "$SUBJECT" "$MAILTO"
    fi
}

#
# Main loop(s)
#

# Check to see if the pid file exists
if [ ! -f "$PIDFILE" ]
    then
    # If it does not, then the program is off
    PROGRAM_ON=false
else
    # If it does exist, we check if the process is running
    PROGRAM_PID=$(cat "$PIDFILE")
    if  kill -0 "$PROGRAM_PID" > /dev/null 2>&1
        then
        PROGRAM_ON=true
    else
        emailthis "Pid file exists, but the program was not running."
        PROGRAM_ON=false
    fi
fi

# Don't start the program if $KEEPOFF was True, otherwise start.
# Also, shut down the program if it was on.
if $KEEPOFF
    then
    if $PROGRAM_ON
        then
        kill "$PROGRAM_PID"
        emailthis "The program is now off, because of the control variable"
        exit 0
    else
        exit 0
    fi
fi

# If we got here, and our checks for PROGRAM_ON are false, we turn it on
# Otherwise, we just exit
if ! $PROGRAM_ON
    then
    if ! $RUNTHIS
        then
        # If we fail to start the program, we get an email notifying us
        emailthis "The program failed to start! Manual intervention required!"
    fi
fi

exit 0
