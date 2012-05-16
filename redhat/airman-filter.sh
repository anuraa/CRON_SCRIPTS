#!/bin/bash

# Airman filter (then transfer) script
# Requested by: Paul Harris (Jetstar)
# Developed by: Hamish Osborne and David Hardham (4LOOP)
# Last modified: 2011-01-06

# Purpose: Airman doesn't require all JACARS messages
# Filter by: Only on-send JACARS messages which contain either
# 		"CFD", "DEP", "ARR", "FML" or "DFD" on the third line
# Installation: Expected to run in crontab, if deployed on both servers
#			schedule cron on alternative intervals, e.g. minutes,
#			to avoid clashes and provide pseudo-high availablity
# Context: Used in conjunction with MFT transfers:
#		1. MFT transfer from JACARS to Airman/In
#		2. This script copies filtered JACARS messages to Airman/Out
#		3. MFT transfer from Airman/Out to MELEXHARM01/esbdownlink 


FILTER=( "CFD" "DEP" "ARR" "FML" "DFD" )  # Provided by Paul Harris
JACARS_PATH="/mnt/corpdfs/esb09/PROD/MSG/Airman/In"
AIRMAN_PATH="/mnt/corpdfs/esb09/PROD/MSG/Airman/Out"
AIRMAN_LOG_PATH="/mnt/corpdfs/esb09/PROD/MSG/Airman/Log"
AIRMAN_MAIL_PATH="/mnt/corpdfs/esb09/PROD/MSG/Airman/Mail"
PROCESSED=0  # used for log file
CFD=0
DEP=0
ARR=0
FML=0
DFD=0
IGNORED=0
FULL_TIMESTAMP=$(date +%F-%H-%M)
TIMESTAMP=$(date +%F)  # used for duplicate files

# Only process files a minute old to avoid files still being written
for i in `find $JACARS_PATH -type f -cmin +1`
do
  let PROCESSED=$PROCESSED+1
  THIRD_LINE=$(awk 'NR==3' $i | cut -c -3)  # Filter on third line
  for f in "${FILTER[@]}"
  do
    if [ $THIRD_LINE = $f ]; then
      let $f=$f+1
      if [ -f $AIRMAN_PATH/${i##*/} ]; then  # check if filename already exists
        cp "$i" "$AIRMAN_PATH/${i##*/}-$TIMESTAMP"  # if so append timestamp
        mv "$i" "$AIRMAN_MAIL_PATH/${i##*/}-$TIMESTAMP"  # if so append timestamp
      else
        cp "$i" "$AIRMAN_PATH"  # if not, move as is
        mv "$i" "$AIRMAN_MAIL_PATH"  # if not, move as is
      fi
    fi
  done

  # If file still exists, delete it because it doesn't qualify for filter
  if [ -f $i ]; then
    rm "$i"
    let IGNORED=$IGNORED+1
  fi 
done

# Create log file for this run - a log file for every run
echo "airman-filter.sh processed this run:" >> $AIRMAN_LOG_PATH/airman-filter-$FULL_TIMESTAMP.log
echo "Total: $PROCESSED" >> $AIRMAN_LOG_PATH/airman-filter-$FULL_TIMESTAMP.log
echo "CFD's: $CFD" >> $AIRMAN_LOG_PATH/airman-filter-$FULL_TIMESTAMP.log
echo "DEP's: $DEP" >> $AIRMAN_LOG_PATH/airman-filter-$FULL_TIMESTAMP.log
echo "ARR's: $ARR" >> $AIRMAN_LOG_PATH/airman-filter-$FULL_TIMESTAMP.log
echo "FML's: $FML" >> $AIRMAN_LOG_PATH/airman-filter-$FULL_TIMESTAMP.log
echo "DFD's: $DFD" >> $AIRMAN_LOG_PATH/airman-filter-$FULL_TIMESTAMP.log
echo "Ignored: $IGNORED" >> $AIRMAN_LOG_PATH/airman-filter-$FULL_TIMESTAMP.log

