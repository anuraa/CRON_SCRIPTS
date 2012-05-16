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


AIRMAN_MAIL_SOURCE="/mnt/corpdfs/esb09/PROD/MSG/Airman/Mail/"
MAIL_TO="application.airman@airbus.com"
CC_TO="amsterdam.jon@4loop.com.au"
MAIL_MESSAGE="/usr/local/redhat/bin/mailmessage.txt"
FULL_TIMESTAMP=$(date +%F-%H-%M)
TIMESTAMP_FOR_MAIL=$(date +%F\ %H:%M)
ZIP_FILENAME="airman-$FULL_TIMESTAMP"

zip -m -j $AIRMAN_MAIL_SOURCE/$ZIP_FILENAME $AIRMAN_MAIL_SOURCE/* -x \*.zip
mutt -s "JQ Airman for $TIMESTAMP_FOR_MAIL" -a $AIRMAN_MAIL_SOURCE/$ZIP_FILENAME.zip $MAIL_TO -c $CC_TO < $MAIL_MESSAGE
