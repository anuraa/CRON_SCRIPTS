#!/bin/bash
#

JFIDS_LOG=/opt/base2/jboss/log/JFIDS.log
JFIDS_CURRENT_TIME=`date +%k:%M -d "1 min ago"`
JFIDS_MSG_TYPES="ERROR FATAL"
JFIDS_GREP=/bin/grep

JFIDS_TO_EMAIL="jq-sms@base2services.com, alerts-jq@base2services.com, diego.tognola@4loop.com.au, ESBAlerts@jestar.com"

for MSG in $JFIDS_MSG_TYPES
do
    DATA=`$JFIDS_GREP -e "^${JFIDS_CURRENT_TIME}.*${MSG}." ${JFIDS_LOG} | grep -v "jfids.service.validation.atom3"`
    echo -e "${MSG} entries:"
    echo $DATA

    if [[ $DATA != "" ]]; then
        echo -e "${DATA}" | mail -s "JQ JFIDS Manual Alert" "${JFIDS_TO_EMAIL}" -r "noreply@base2services.com"
        echo "Sending email(s) to ${JFIDS_TO_EMAIL}..."
    fi
done
