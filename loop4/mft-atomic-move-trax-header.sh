#!/bin/bash

# Originally created for AP Project, based on jetmax-move.sh
# Script moves files delivered by MFT into final destination folder
# MFT workaround for large file transfers and concerns about atomic transfers
# i.e. since linux mv is atomic and MFT appears not to be, first transfer with MFT then linux mv

# Installation: Expected to run in crontab, 
# 			if deployed on both servers:
#                       schedule cron on alternate intervals, e.g. minutes,
#                       to avoid clashes and provide pseudo-high availablity

# Developed by: Hamish Osborne and Junaid Qamar (FORLOOP)
# Last modified: 2011-12-01

# Folders for transfers
SOURCE_DIRECTORY="/mnt/corpdfs/esb09/PROD/ESBAP/fromMphasiS/Trax-temp/Header"
DESTINATION_DIRECTORY="/mnt/corpdfs/esb09/PROD/ESBAP/fromMphasiS/Trax/Header"

# For email
TEXT_FOR_EMAIL="/usr/local/redhat/bin/mft-atomic-email.txt"
TIMESTAMP_FOR_EMAIL=$(date +%F)
MAIL_TO="hamish.osborne@4loop.com.au, junaid.qamar@4loop.com.au, esbalerts@jetstar.com"

# Overwrite previous email text
echo "MFT atomic move script - Started" > $TEXT_FOR_EMAIL

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
      echo "Moving files..." >> $TEXT_FOR_EMAIL 
      for f in $SOURCE_DIRECTORY/*
      do
	if [ -f "$f" ]; then
	  ls $DESTINATION_DIRECTORY/${f##*/}
	  FILE_EXISTS=$?
	  if [ $FILE_EXISTS -eq 0 ]; then
	    echo "Moved failed for ${f##*/} as it already exists at $DESTINATION_DIRECTORY" >> $TEXT_FOR_EMAIL
	    ERROR_OCCURRED="1"
	  else
            mv -v $SOURCE_DIRECTORY/${f##*/} $DESTINATION_DIRECTORY >> $TEXT_FOR_EMAIL 
            MOVE_RETURN_CODE=$?
            if [ $MOVE_RETURN_CODE -eq 0 ]; then
              echo "${f##*/} Moved successfully" >> $TEXT_FOR_EMAIL
            else 
              echo "${f##*/} Move failed" >> $TEXT_FOR_EMAIL
	    fi
	  fi
        fi
      done
      echo "ls -la $DESTINATION_DIRECTORY" >> $TEXT_FOR_EMAIL 
      ls -la $DESTINATION_DIRECTORY >> $TEXT_FOR_EMAIL 
      if [ "$ERROR_OCCURRED" = "1" ]; then
        mutt -s "MFT atomic move script run at $TIMESTAMP_FOR_EMAIL - Failed" $MAIL_TO < $TEXT_FOR_EMAIL
      else
	mutt -s "MFT atomic move script run at $TIMESTAMP_FOR_EMAIL - Passed" $MAIL_TO < $TEXT_FOR_EMAIL
      fi
    else
      echo "No files to move at $TIMESTAMP_FOR_EMAIL." >> $TEXT_FOR_EMAIL
      # No need to send an email when there is nothing to do
      # mutt -s "MFT atomic move script run at $TIMESTAMP_FOR_EMAIL - No files to move" $MAIL_TO < $TEXT_FOR_EMAIL
    fi
    else
      echo "Couldn't find the destination directory - $DESTINATION_DIRECTORY" >> $TEXT_FOR_EMAIL
      mutt -s "MFT atomic move script run at $TIMESTAMP_FOR_EMAIL - Failed" $MAIL_TO < $TEXT_FOR_EMAIL
  fi 
  else
    echo "Couldn't find the source directory - $SOURCE_DIRECTORY" >> $TEXT_FOR_EMAIL
    mutt -s "MFT atomic move script run at $TIMESTAMP_FOR_EMAIL - Failed" $MAIL_TO < $TEXT_FOR_EMAIL
fi
