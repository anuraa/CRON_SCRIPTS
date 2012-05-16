#!/bin/bash

# Script to PGP decrypt files
# Created for: The Accounts Payable (AP) project (in particular Qantas files)
# Developed by: Hamish Osborne and Junaid Qamar (FORLOOP)
# Last modified: 2012-01-04

# Purpose: To decrypt files before sending to Qantas via FTP
# Installation:
# Context: Used in conjunction with MFT transfers

# Local paths
# When adding or subtracting paths below be sure to include the path in both INPUT_DIRS, OUTPUT_DIRS and ARCHIVE_DIRS
# Also note that the ordering matters as the position is relative in the three paths
declare -a INPUT_DIRS=( /mnt/corpdfs/esb09/PROD/ESBAP/toMphasiS/Qantas/IF334 /mnt/corpdfs/esb09/PROD/ESBAP/toMphasiS/Qantas/IF335 /mnt/corpdfs/esb09/PROD/ESBAP/toMphasiS/Qantas/IF336 /mnt/corpdfs/esb09/PROD/ESBAP/toMphasiS/Qantas/IF337 /mnt/corpdfs/esb09/PROD/ESBAP/toMphasiS/Qantas/IF338 /mnt/corpdfs/esb09/PROD/ESBAP/toMphasiS/Qantas/IF339 /mnt/corpdfs/esb09/PROD/ESBAP/toMphasiS/Qantas/IF340 /mnt/corpdfs/esb09/PROD/ESBAP/toMphasiS/Qantas/IF343  )
declare -a OUTPUT_DIRS=( /mnt/corpdfs/esb09/PROD/ESBAP/toMphasiS/Qantas/IF334decrypted /mnt/corpdfs/esb09/PROD/ESBAP/toMphasiS/Qantas/IF335decrypted /mnt/corpdfs/esb09/PROD/ESBAP/toMphasiS/Qantas/IF336decrypted /mnt/corpdfs/esb09/PROD/ESBAP/toMphasiS/Qantas/IF337decrypted /mnt/corpdfs/esb09/PROD/ESBAP/toMphasiS/Qantas/IF338decrypted /mnt/corpdfs/esb09/PROD/ESBAP/toMphasiS/Qantas/IF339decrypted /mnt/corpdfs/esb09/PROD/ESBAP/toMphasiS/Qantas/IF340decrypted /mnt/corpdfs/esb09/PROD/ESBAP/toMphasiS/Qantas/IF343decrypted )
declare -a ARCHIVE_DIRS=( /mnt/corpdfs/esb09/PROD/ESBAP/Archive/toMphasiS/Qantas/IF334decrypted2 /mnt/corpdfs/esb09/PROD/ESBAP/Archive/toMphasiS/Qantas/IF335decrypted2 /mnt/corpdfs/esb09/PROD/ESBAP/Archive/toMphasiS/Qantas/IF336decrypted2 /mnt/corpdfs/esb09/PROD/ESBAP/Archive/toMphasiS/Qantas/IF337decrypted2 /mnt/corpdfs/esb09/PROD/ESBAP/Archive/toMphasiS/Qantas/IF338decrypted2 /mnt/corpdfs/esb09/PROD/ESBAP/Archive/toMphasiS/Qantas/IF339decrypted2 /mnt/corpdfs/esb09/PROD/ESBAP/Archive/toMphasiS/Qantas/IF340decrypted2 /mnt/corpdfs/esb09/PROD/ESBAP/Archive/toMphasiS/Qantas/IF343decrypted2 )

#TO_ENCRYPT_FOLDER="/mnt/corpdfs/esb09/PROD/ESBAP/fromMphasiS/Qantas/IF342original"
#OUTPUT_FOLDER="/mnt/corpdfs/esb09/PROD/ESBAP/fromMphasiS/Qantas/IF342"
#ARCHIVE_FOLDER="/mnt/corpdfs/esb09/PROD/ESBAP/Archive/fromMphasiS/Qantas/IF342"

# Loop through the INPUT_DIRS array then assume the count/index is the same spot in OUTPUT_DIRS and ARCHIVE_DIRS
# See note/comment about the array declarations 
for i in "${INPUT_DIRS[@]}"
do
  # Increment counter/index for referencing the location with OUTPUT_DIRS and ARCHIVE_DIRS
  # Zero-indexed so need to increment counter straight away to start at 1
  let index=$index+1

  # Using existing encryption script
  # Match variables from outer array into expected variable names
  TO_DECRYPT_FOLDER=${INPUT_DIRS[$index-1]}
  OUTPUT_FOLDER=${OUTPUT_DIRS[$index-1]}
  ARCHIVE_FOLDER2=${ARCHIVE_DIRS[$index-1]}

  # Debugging section
  echo $TO_DECRYPT_FOLDER
  echo $OUTPUT_FOLDER
  echo $ARCHIVE_FOLDER2
  echo "--end loop--"

  # Cut-and-paste of previous individual encryption scripts (proven in UAT)
  # Now that the variables are populated from the outer array

  for f in $TO_DECRYPT_FOLDER/*
  do
    echo "Attempting to decrypt $f"
    echo "was ${f%.pgp}"
    FILENAME_WITHOUT_EXTENSION=${f%.pgp}
    echo "now ${FILENAME_WITHOUT_EXTENSION##*/}"
    gpg --yes --batch --no-tty --passphrase "Testing PGP with ESB for AP and QF" --output $OUTPUT_FOLDER/${FILENAME_WITHOUT_EXTENSION##*/} --decrypt $f
    RETURN_CODE=$?
    if [ $RETURN_CODE -ne 0 ]; then
      echo "Failed to decrypt $f"
    else
      echo "$f decrypted and moved to $OUTPUT_FOLDER"
      echo "$f moving to archive2"
      mv $f $ARCHIVE_FOLDER2/
    fi
  done


done
