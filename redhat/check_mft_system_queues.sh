#!/bin/bash
#
# Checks the MFT system queues for stale/stuck files
# base2Services (t.johnson@base2services.com)
#
# Last updated:
# 22/02/12 - base2Services
#

MFT_DEFINITIONS_XML=/opt/base2/jboss/conf/jq-mft-filetransfer-producer-consumer-definition.xml
MFT_QUEUE_DIR=/mnt/corpdfs/esb09/PROD/MSG/MFTsystemQueue/
MFT_SEARCH_MIN_DEPTH=1
MFT_SEARCH_MOD_TIME=10
MFT_SEARCH_CONTENT_EXCLUDES="SCOM TEST"
MFT_SEARCH_FILENAME_EXCLUDES="duplicate test"
MFT_SEARCH_FILENAME_REQUIRES="@"
MFT_QUEUE_ALERT_RECIPIENTS="itsupport@base2services.com,jq-sms2@base2services.com,amsterdam.jon@4loop.com.au,esbalerts@jetstar.com"

echo_log() {
    logger -t $0 "${1}"
    echo "${1}"
}

function exit_email_log() {
    printf "An error occured with performing MFT system queue verification checks\n\nDetails:\n$1" | mail -s "MFT System Queue Alert" ${MFT_QUEUE_ALERT_RECIPIENTS}
    echo_log "${1}"
    exit 1
}

echo_log "*** Checking for valid system queue directory..."
if [[ ! -d $MFT_QUEUE_DIR ]]; then
        exit_email_log "Cannot find MFT System Queue directory. Exiting."
fi

echo_log "*** Validating minimum find depth..."
if [[ $MFT_SEARCH_MIN_DEPTH -lt 0 || $MFT_SEARCH_MIN_DEPTH -gt 10 ]]; then
        exit_email_log "The minimum find depth is invalid. Exiting."
fi

echo_log "*** Checking MFT XML definitions file..."
if [ ! -f $MFT_DEFINITIONS_XML ]; then
    exit_email_log "Unable to find the MFT XML consumer/producer definitions file. Exiting."
fi

echo_log "*** Building search query..."
FILENAME_EXCLUDES_QUERY=""
for FILENAME_EXCLUDE in $MFT_SEARCH_FILENAME_EXCLUDES; do
    FILENAME_EXCLUDES_QUERY="${FILENAME_EXCLUDES_QUERY} ! -name *${FILENAME_EXCLUDE}*"
done
FILENAME_REQUIRES_QUERY=""
for FILENAME_REQUIRE in $MFT_SEARCH_FILENAME_REQUIRES; do
    FILENAME_REQUIRES_QUERY="${FILENAME_REQUIRES_QUERY} -name *${FILENAME_REQUIRE}*"
done
CONTENT_EXCLUDES_QUERY=""
for CONTENT_EXCLUDE in $MFT_SEARCH_CONTENT_EXCLUDES; do
    CONTENT_EXCLUDES_QUERY="-e ${CONTENT_EXCLUDES_QUERY} "
done

echo_log "*** Checking MFT system queues..."
echo_log "Queue search path is '${MFT_QUEUE_DIR}*'"
echo_log ""
echo_log "Files in queues:"

COUNT_OVER_ZERO=0
SYSTEM_QUEUE_DETAILS=""

for DEFINITION in `grep "<locationConfig " $MFT_DEFINITIONS_XML | grep -v $CONTENT_EXCLUDES_QUERY | cut -f2 -d\"`; do
    # Make sure defined consumer/producer has a corresponding directory
    if [ -d "${MFT_QUEUE_DIR}${DEFINITION}" ]; then
        QUEUE_COUNT=`find ${MFT_QUEUE_DIR}${DEFINITION} -mindepth ${MFT_SEARCH_MIN_DEPTH} -mmin +${MFT_SEARCH_MOD_TIME} ${FILENAME_EXCLUDES_QUERY} ${FILENAME_REQUIRES_QUERY} ! -size 0 | wc -l`
        if [ $QUEUE_COUNT -gt 0 ]; then
            COUNT_OVER_ZERO=$((COUNT_OVER_ZERO + 1))
            SYSTEM_QUEUE_DETAILS="${SYSTEM_QUEUE_DETAILS}${DEFINITION}: ${QUEUE_COUNT} files\n`ls -1 ${MFT_QUEUE_DIR}${DEFINITION}/`\n\n"
        fi
    fi
    
    echo_log "${DEFINITION}: ${QUEUE_COUNT}"
done

# Notify recipients if queue counter is greater than zero for any queue directories
if [[ $COUNT_OVER_ZERO -gt 0 ]]; then
    printf "There were MFT System Queue directories with 1 or more files older than 10 minutes\n\n-----Details-----\n\n${SYSTEM_QUEUE_DETAILS}\n" | mail -s "MFT System Queue Alert" ${MFT_QUEUE_ALERT_RECIPIENTS}
fi

exit 0
