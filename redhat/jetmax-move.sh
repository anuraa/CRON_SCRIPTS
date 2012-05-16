#!/bin/bash

# Final stage in Jetmax Sync
# Script moves files delivered by MFT into final destination folder
# Workaround since MFT is unable to overwrite files at destination 

# Installation: Expected to run in crontab, 
# 			if deployed on both servers:
#                       schedule cron on alternate intervals, e.g. minutes,
#                       to avoid clashes and provide pseudo-high availablity

# Developed by: Hamish Osborne and Junaid Qamar (FORLOOP)
# Last modified: 2011-07-26

# Folders for transfers
SOURCE_DIRECTORY="/mnt/corpdfs/itn04/Jetmax-MFT-Incoming"
DESTINATION_DIRECTORY="/mnt/corpdfs/itn04"

# For email
TEXT_FOR_EMAIL="/usr/local/redhat/bin/jetmax/jetmax-email.txt"
TIMESTAMP_FOR_EMAIL=$(date +%F)
MAIL_TO="amsterdam.jon@4loop.com.au"

# Overwrite previous email text
echo "Jetmax Script - Started" > $TEXT_FOR_EMAIL

# Check directories exist
cd $SOURCE_DIRECTORY
DIR_RETURN_CODE=$?
if [ $DIR_RETURN_CODE -eq 0 ]; then
  # Continue to check directories exist
  cd $DESTINATION_DIRECTORY
  DEST_DIR_RETURN_CODE=$?
  if [ $DEST_DIR_RETURN_CODE -eq 0 ]; then
    echo "Source and destination directory are reachable" >> $TEXT_FOR_EMAIL
    # Check if there is anything to be moved
    NUMBER_TO_MOVE=`ls $SOURCE_DIRECTORY | wc -l`
    echo "$NUMBER_TO_MOVE file(s) to move" >> $TEXT_FOR_EMAIL
    if [ $NUMBER_TO_MOVE -ne 0 ]; then
      # As per Ahmad's email request of 2011-08-16 14:20 - keep all files
      # echo "Deleting existing files in $DESTINATION_DIRECTORY..." >> $TEXT_FOR_EMAIL
      # rm -vf $DESTINATION_DIRECTORY/* >> $TEXT_FOR_EMAIL
      echo "Moving files..." >> $TEXT_FOR_EMAIL
      mv -vf $SOURCE_DIRECTORY/* $DESTINATION_DIRECTORY >> $TEXT_FOR_EMAIL 
      MOVE_RETURN_CODE=$?
      if [ $MOVE_RETURN_CODE -eq 0 ]; then
        echo "Move successful $DESTINATION_DIRECTORY now contains:" >> $TEXT_FOR_EMAIL
        ls -la $DESTINATION_DIRECTORY >> $TEXT_FOR_EMAIL 
        mutt -s "Jetmax move script run at $TIMESTAMP_FOR_EMAIL - Passed" $MAIL_TO < $TEXT_FOR_EMAIL
        else 
          echo "Move failed" >> $TEXT_FOR_EMAIL
          mutt -s "Jetmax move script run at $TIMESTAMP_FOR_EMAIL - Failed" $MAIL_TO < $TEXT_FOR_EMAIL
      fi
      else
        echo "No files to move" >> $TEXT_FOR_EMAIL
        mutt -s "Jetmax move script run at $TIMESTAMP_FOR_EMAIL - No files to move" $MAIL_TO < $TEXT_FOR_EMAIL
    fi
    else
      echo "Couldn't find $DESTINATION_DIRECTORY" >> $TEXT_FOR_EMAIL
      mutt -s "Jetmax move script run at $TIMESTAMP_FOR_EMAIL - Failed" $MAIL_TO < $TEXT_FOR_EMAIL
  fi 
  else
    echo "Couldn't find $SOURCE_DIRECTORY" >> $TEXT_FOR_EMAIL
    mutt -s "Jetmax move script run at $TIMESTAMP_FOR_EMAIL - Failed" $MAIL_TO < $TEXT_FOR_EMAIL
fi
