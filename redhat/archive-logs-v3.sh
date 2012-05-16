#!/bin/sh
#
# Script:           JQ log archive script
# Author:           base2Services
# Last updated:     17/02/12
#
# CHANGELOG:
# - Added temporary functionality to prepend gzipped files with 'olddc_'
# - Removed SCP rate limiting functionality
# - Fixed mail function to allow more than 1 recipient
#

# Get system short hostname and split
SERVER_NAME=`hostname -s | sed s/melexh//g`

#################################
# DO NOT MODIFY ABOVE THIS LINE #
#################################

# Current environment
# PROD or TEST
ENVIRONMENT="PROD"

# Email recipients for result of backup
MAIL_RECIPIENT="itsupport@base2services.com,junaid.qamar@4loop.com.au"

# Source and destination directories
SRC_DIR=/usr/local/jboss/jboss-soa-p.4.3.0/jboss-as/server/production/log/
DST_DIR=/mnt/corpdfs/esb09/${ENVIRONMENT}/DATA/Logs/${SERVER_NAME}/

function log {
	logger -t "$0" "$1" 
}

# Does source directory exist?
if [ ! -d ${SRC_DIR} ]; then
    	log "Cannot stat logs source directory, exiting. (${SRC_DIR})"
	exit 0
fi

# Does destination directory exist?
if [ ! -d ${DST_DIR} ]; then
    	log "Cannot stat logs destination directory, exiting. (${DST_DIR})"
	exit 0
fi

# Compress log files
log "Compressing log files..."
find ${SRC_DIR} -iname "*.log.*-??" -exec gzip \{\} \;
if [ "$?" -ne "0" ]; then
	log "There was an error trying to compress log files.  Exited with error ${?}"
	exit 0
fi

# Temporarily rename gzipped files for DC migration
log "Temporarily renaming gzipped log files for DC ESB migration"
for FILE in `find ${SRC_DIR} -iname "*.gz"`;
do
    mv "${FILE}" "${SRC_DIR}/`basename $FILE`"
    log "Moving ${FILE} to ${SRC_DIR}/`basename $FILE`"
done

if [ "$?" -ne "0" ]; then
    log "An error occured when attempting to rename gzipped files.  Exited with error ${?}"
    exit 0
fi

# Move all archived logs
log "Moving log files from ${SRC_DIR} to ${DST_DIR}"
find ${SRC_DIR} -iname "*.gz" -exec cp \{\} ${DST_DIR} \;
if [ "$?" -ne "0" ]; then
	log "There was an error trying to move the compressed log files.  Exited with error ${?}"
	exit 0
fi

# Remove source archived logs
log "Not Deleting redundant archived logs from ${SRC_DIR}"
find ${SRC_DIR} -iname "*.gz" -exec rm -f \{\} \;
if [ "$?" -ne "0" ]; then
	log "There was an error trying to delete the redundant source logs.  Exited with error ${?}"
	exit 0
fi

# Mail notification
printf "Logs were successfully archived on '${SERVER_NAME}'" | mail -s "JQ logs archived! (${SERVER_NAME})" "${MAIL_RECIPIENT}"

log "Finished archiving logs on host."
exit 0
