#!/bin/bash

# Monitor consumer entry 
# Last modified: 2011-02-09


MFT_LOG="/usr/local/jboss/jboss-soa-p.4.3.0/jboss-as/server/production/log/MFT.log"
CONSUMER_DIRECTORY="MSG/Rocade/In"
#MAIL_TO="support@4loop.com.au"
MAIL_TO="itsupport@base2services.com, amsterdam.jon@4loop.com.au"
MAIL_MESSAGE="/usr/local/redhat/bin/mftmailmessage.txt"

LAST_CONSUMER_ENTRY=`grep $CONSUMER_DIRECTORY $MFT_LOG | tail -n 1`
LAST_CONSUMER_ENTRY_TIME=`grep $CONSUMER_DIRECTORY $MFT_LOG | tail -n 1 | cut -d " " -f 1`
CONSUMER_TIME_IN_EPOCH=$(date +%s -d "$LAST_CONSUMER_ENTRY_TIME")
TIME_NOW=$(date +%s)
TIME_DIFF=$(($TIME_NOW - $CONSUMER_TIME_IN_EPOCH))
#echo "last consumer entry was $LAST_CONSUMER_ENTRY"
#echo "last consumer entry time $LAST_CONSUMER_ENTRY_TIME"
#echo "last consumer entry time in epoch $CONSUMER_TIME_IN_EPOCH"
#echo "the time is $TIME_NOW"
#echo "and the difference is $TIME_DIFF"

if [ $TIME_DIFF -gt 300 ]; then
/usr/bin/mutt -s "MFT not sending to $CONSUMER_DIRECTORY" $MAIL_TO < $MAIL_MESSAGE
fi
