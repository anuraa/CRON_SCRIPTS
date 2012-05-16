#!/bin/bash

# Script to transfer files from CommBiz
# Requested by: JQ (Stephen Tame, Karen O'Duil) and CBA as a replacement for ODX 
# Developed by: Hamish Osborne and Junaid Qamar (FORLOOP)
# Last modified: 2011-07-11

# Purpose: Workaround as MFT doesn't handle ssh key authentication as required by CBA 
# Installation: Expected to run in crontab, 
# 			if deployed on both servers:
#                       schedule cron on alternate intervals, e.g. minutes,
#                       to avoid clashes and provide pseudo-high availablity
#		Required:
#			1. securetransfer.commbank.com.au in known_hosts
#				test this by connecting manually via the command line
#			2. SFTP_BATCH_FILE
# Context: Used in conjunction with commbiz-send.sh for complete CBA round trip

# Note: Some of these values also hardcoded in the sftp batch file
SFTP_CONNECT_BATCH_FILE="/usr/local/redhat/bin/commbiz-retrieve-connect.txt"
SFTP_RETRIEVE_BATCH_FILE="/usr/local/redhat/bin/commbiz-retrieve-commands.txt"
SFTP_DELETE_BATCH_FILE="/usr/local/redhat/bin/commbiz-retrieve-delete.txt"
# CommBiz and CBA are synonymous 
CBA_LOGIN_ID="000100038086"
CBA_ADDRESS="securetransfer.commbank.com.au"
CBA_INBOX_PATH="/CommBiz/inbox"
# Local details
FROM_CBA_PATH="/mnt/corpdfs/esb09/PROD/DATA/CommBiz/FromCBA"
TEMP_FROM_CBA="/mnt/corpdfs/esb09/PROD/DATA/CommBiz/Logs/Temp"
LOG_PATH="/mnt/corpdfs/esb09/PROD/DATA/CommBiz/Logs"
ARCHIVE_PATH="/mnt/corpdfs/esb09/PROD/DATA/CommBiz/Archive/FromCBA"
PRIVATE_KEY="/home/redhat/.ssh/id_rsa_jq_test"
FULL_TIMESTAMP=$(date +%F-%H-%M)
TIMESTAMP_FOR_EMAIL=$(date +%F)
LOG_FILENAME="commbiz-retrieve.log.$FULL_TIMESTAMP"
MAIL_TO="amsterdam.jon@4loop.com.au, itsupport@base2services.com"

# Create log file for this run - a log file for every run
echo "CommBiz Retrieval Script - Started" >> $LOG_PATH/$LOG_FILENAME

# Connection test, test if local and remote directories exist, test return code
sftp -b $SFTP_CONNECT_BATCH_FILE -oIdentityFile=$PRIVATE_KEY $CBA_LOGIN_ID@$CBA_ADDRESS >> $LOG_PATH/$LOG_FILENAME
# Check the status code of the connection/directory test 
SFTP_CONNECT_RETURN_CODE=$?
if [ $SFTP_CONNECT_RETURN_CODE -ne 0 ]; then 
  echo "Failed connection/setup test to CommBiz with error code: $SFTP_CONNECT_RETURN_CODE" >> $LOG_PATH/$LOG_FILENAME
  # Send an email as a report after every run
  mutt -s "CommBiz (retrieve) at $TIMESTAMP_FOR_EMAIL - Failed" $MAIL_TO < $LOG_PATH/$LOG_FILENAME
else
  echo "Passed connection/setup test to CommBiz." >> $LOG_PATH/$LOG_FILENAME

  # Connect again to retrieve all the files 
  sftp -b $SFTP_RETRIEVE_BATCH_FILE -oIdentityFile=$PRIVATE_KEY $CBA_LOGIN_ID@$CBA_ADDRESS >> $LOG_PATH/$LOG_FILENAME
  SFTP_RETRIEVE_RETURN_CODE=$?

  # From the logs count the number of files
  NUMBER_TO_RETRIEVE=`grep rw- $LOG_PATH/$LOG_FILENAME | wc -l`
  echo "$NUMBER_TO_RETRIEVE file(s) to retrieve" >> $LOG_PATH/$LOG_FILENAME

  # Later change (2011-08-09) Identify when no files to retrieve
  if [ $NUMBER_TO_RETRIEVE -eq 0 ]; then
    echo "No files to retrieve" >> $LOG_PATH/$LOG_FILENAME
    # Send an email as a report after every run
    mutt -s "CommBiz (retrieve) at $TIMESTAMP_FOR_EMAIL - No files to retrieve" $MAIL_TO < $LOG_PATH/$LOG_FILENAME
  else
    # Later change (2011-08-09) Additional indentation
    # Check the status of the retrieval
    if [ $SFTP_RETRIEVE_RETURN_CODE -ne 0 ]; then 
      echo "Failed to download files from CommBiz. The error code: $SFTP_RETRIEVE_RETURN_CODE" >> $LOG_PATH/$LOG_FILENAME
      # Send an email as a report after every run
      mutt -s "CommBiz (retrieve) at $TIMESTAMP_FOR_EMAIL - Failed" $MAIL_TO < $LOG_PATH/$LOG_FILENAME
    else
      # Compare the numbers of files local and remote
      # Number of files in the Temp directory
      NUMBER_IN_TEMP=`ls $TEMP_FROM_CBA | wc -l`
      # Generate a list of files to delete, i.e. list of files in Temp, i.e. only remote delete files that found locally
      echo "cd $CBA_INBOX_PATH" > $SFTP_DELETE_BATCH_FILE
      for f in $TEMP_FROM_CBA/*
      do
        echo "rm ${f##*/}" >> $SFTP_DELETE_BATCH_FILE
      done
      echo "bye" >> $SFTP_DELETE_BATCH_FILE

      # Report on number comparison, i.e. local files versus remote, always delete any remote files found locally though
      echo "Downloaded $NUMBER_IN_TEMP file(s) from CommBiz." >> $LOG_PATH/$LOG_FILENAME
      if [ $NUMBER_IN_TEMP -eq $NUMBER_TO_RETRIEVE ]; then
        echo "Check number of local files compared to remote - Passed" >> $LOG_PATH/$LOG_FILENAME
        sftp -b $SFTP_DELETE_BATCH_FILE -oIdentityFile=$PRIVATE_KEY $CBA_LOGIN_ID@$CBA_ADDRESS >> $LOG_PATH/$LOG_FILENAME
        SFTP_DELETE_RETURN_CODE=$?
        if [ $SFTP_DELETE_RETURN_CODE -ne 0 ]; then
          echo "Failed to delete files from CommBiz. The error code: $SFTP_DELETE_RETURN_CODE" >> $LOG_PATH/$LOG_FILENAME
          mutt -s "CommBiz (retrieve) at $TIMESTAMP_FOR_EMAIL - Failed" $MAIL_TO < $LOG_PATH/$LOG_FILENAME
        else
          echo "Successfully deleted files from CommBiz." >> $LOG_PATH/$LOG_FILENAME
          mutt -s "CommBiz (retrieve) at $TIMESTAMP_FOR_EMAIL - Passed" $MAIL_TO < $LOG_PATH/$LOG_FILENAME
        fi
      else
        echo "Check number of local files compared to remote - Failed" >> $LOG_PATH/$LOG_FILENAME
        sftp -b $SFTP_DELETE_BATCH_FILE -oIdentityFile=$PRIVATE_KEY $CBA_LOGIN_ID@$CBA_ADDRESS >> $LOG_PATH/$LOG_FILENAME
        SFTP_DELETE_RETURN_CODE=$?
        if [ $SFTP_DELETE_RETURN_CODE -ne 0 ]; then
          echo "Failed to delete files from CommBiz. The error code: $SFTP_DELETE_RETURN_CODE" >> $LOG_PATH/$LOG_FILENAME
          mutt -s "CommBiz (retrieve) at $TIMESTAMP_FOR_EMAIL - Failed" $MAIL_TO < $LOG_PATH/$LOG_FILENAME
        else
          echo "Successfully deleted files from CommBiz." >> $LOG_PATH/$LOG_FILENAME
          mutt -s "CommBiz (retrieve) at $TIMESTAMP_FOR_EMAIL - Failed" $MAIL_TO < $LOG_PATH/$LOG_FILENAME
        fi  # End $SFTP_DELETE_RETURN_CODE (deleting files from CommBiz)
      fi  # End $NUMBER_IN_TEMP (difference between local and remote)
    fi  # End $SFTP_RETRIEVE_RETURN_CODE (downloading files)
  fi  # End $NUMBER_TO_RETRIEVE (check if retrieval is needed)
fi  # End $SFTP_CONNECT_RETURN_CODE (local and remote connection/setup check)

# Sorting files into categories based on filename
# Copy to archive and move to destination
# M1 files
find $TEMP_FROM_CBA -iname '*BAI2-*' -type f -exec /bin/cp '{}' $ARCHIVE_PATH/M1  \; >> $LOG_PATH/$LOG_FILENAME
find $TEMP_FROM_CBA -iname '*BAI2-*' -type f -exec /bin/mv '{}' $FROM_CBA_PATH/M1  \; >> $LOG_PATH/$LOG_FILENAME

# M2 files
find $TEMP_FROM_CBA -iname '*DELIST-M23*' -type f -exec /bin/cp '{}' $ARCHIVE_PATH/M2  \; >> $LOG_PATH/$LOG_FILENAME
find $TEMP_FROM_CBA -iname '*DELIST-M23*' -type f -exec /bin/mv '{}' $FROM_CBA_PATH/M2  \; >> $LOG_PATH/$LOG_FILENAME

# M3 files
find $TEMP_FROM_CBA -iname '*NZDESTAT*' -type f -exec /bin/cp '{}' $ARCHIVE_PATH/M3  \; >> $LOG_PATH/$LOG_FILENAME
find $TEMP_FROM_CBA -iname '*NZDESTAT*' -type f -exec /bin/mv '{}' $FROM_CBA_PATH/M3  \; >> $LOG_PATH/$LOG_FILENAME

# All other files - catch all
find $TEMP_FROM_CBA -iname '*' -type f -exec /bin/cp '{}' $ARCHIVE_PATH/Other  \; >> $LOG_PATH/$LOG_FILENAME
find $TEMP_FROM_CBA -iname '*' -type f -exec /bin/mv '{}' $FROM_CBA_PATH/Other  \; >> $LOG_PATH/$LOG_FILENAME

