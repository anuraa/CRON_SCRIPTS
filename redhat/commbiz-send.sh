#!/bin/bash

# Script to transfer files to CommBiz
# Requested by: JQ (Stephen Tame, Karen O'Duil) and CBA as a replacement for ODX
# Developed by: Hamish Osborne and Junaid Qamar (FORLOOP)
# Last modified: 2011-07-11

# Purpose: Workaround as MFT doesn't handle ssh key authentication as required by CBA 
# Installation: Expected to run in crontab, 
# 			if deployed on both servers:
#                       schedule cron on alternate intervals, e.g. minutes,
#                       to avoid clashes and provide pseudo-high availablity
#		Required:
#		 	1. securetransfer.commbank.com.au in known_hosts
#				test this by connecting manually via the command line
#			2. SFTP_BATCH_FILE
# Context: Used in conjunction with commbiz-retrieve.sh for complete CBA round trip

# Note: Some of these values also hardcoded in the sftp batch file
SFTP_BATCH_FILE="/usr/local/redhat/bin/commbiz-send-commands.txt" 
# CommBiz and CBA are synonymous 
CBA_LOGIN_ID="000100038086"
CBA_ADDRESS="securetransfer.commbank.com.au"
CBA_OUTBOX_PATH="/CommBiz/outbox"
# Local details
TO_CBA_PATH="/mnt/corpdfs/esb09/PROD/DATA/CommBiz/ToCBA/"
LOG_PATH="/mnt/corpdfs/esb09/PROD/DATA/CommBiz/Logs"
ARCHIVE_PATH="/mnt/corpdfs/esb09/PROD/DATA/CommBiz/Archive/ToCBA"
PRIVATE_KEY="/home/redhat/.ssh/id_rsa_jq_test"
FULL_TIMESTAMP=$(date +%F-%H-%M)
TIMESTAMP_FOR_EMAIL=$(date +%F)
LOG_FILENAME="commbiz-send.log.$FULL_TIMESTAMP"
MAIL_TO="amsterdam.jon@4loop.com.au, itsupport@base2services.com"

# Create log file for this run - a log file for every run
echo "CommBiz Send Script - Started" >> $LOG_PATH/$LOG_FILENAME

# First check if there is anything to be sent
NUMBER_TO_SEND=`ls $TO_CBA_PATH | wc -l`
echo "$NUMBER_TO_SEND file(s) to send" >> $LOG_PATH/$LOG_FILENAME
# and only connect if there is anything to send
if [ $NUMBER_TO_SEND -ne 0 ]; then
  sftp -b $SFTP_BATCH_FILE -oIdentityFile=$PRIVATE_KEY $CBA_LOGIN_ID@$CBA_ADDRESS >> $LOG_PATH/$LOG_FILENAME
  SFTP_RETURN_CODE=$?
  if [ $SFTP_RETURN_CODE -eq 0 ]; then
    # move to archive only if transfer successful
    for f in $TO_CBA_PATH*
    do
      mv -v $f $ARCHIVE_PATH/${f##*/}.$FULL_TIMESTAMP >> $LOG_PATH/$LOG_FILENAME
    done
    ARCHIVING_RETURN_CODE=$?
    if [ $ARCHIVING_RETURN_CODE -ne 0 ]; then
      echo "Archiving failed." >> $LOG_PATH/$LOG_FILENAME
      mutt -s "CommBiz (send) at $TIMESTAMP_FOR_EMAIL - Failed" $MAIL_TO < $LOG_PATH/$LOG_FILENAME
    else
      echo "Archiving Passed." >> $LOG_PATH/$LOG_FILENAME
      # Send an email as a report after every run
      mutt -s "CommBiz (send) at $TIMESTAMP_FOR_EMAIL - Passed" $MAIL_TO < $LOG_PATH/$LOG_FILENAME
    fi
  else
    echo "The error returned was: $SFTP_RETURN_CODE" >> $LOG_PATH/$LOG_FILENAME
    # Send an email as a report after every run
    mutt -s "CommBiz (send) at $TIMESTAMP_FOR_EMAIL - Failed" $MAIL_TO < $LOG_PATH/$LOG_FILENAME
  fi
else
  # Send an email as a report after every run
  mutt -s "CommBiz (send) at $TIMESTAMP_FOR_EMAIL - No files to send" $MAIL_TO < $LOG_PATH/$LOG_FILENAME
fi

