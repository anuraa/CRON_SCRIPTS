#!/bin/bash

# Script to PGP encrypt files
# Created for: The Accounts Payable (AP) project (in particular Qantas files)
# Developed by: Hamish Osborne and Junaid Qamar (FORLOOP)
# Last modified: 2012-01-04

# Purpose: To encrypt files before sending to Qantas via FTP
# Installation:
# Context: Used in conjunction with MFT transfers

# Local paths
# When adding or subtracting paths below be sure to include the path in both INPUT_DIRS, OUTPUT_DIRS and ARCHIVE_DIRS
# Also note that the ordering matters as the position is relative in the three paths
declare -a INPUT_DIRS=( /mnt/corpdfs/esb09/PROD/ESBAP/fromMphasiS/Qantas/IF341original /mnt/corpdfs/esb09/PROD/ESBAP/fromMphasiS/Qantas/IF342original )
declare -a OUTPUT_DIRS=( /mnt/corpdfs/esb09/PROD/ESBAP/fromMphasiS/Qantas/IF341 /mnt/corpdfs/esb09/PROD/ESBAP/fromMphasiS/Qantas/IF342 )
declare -a ARCHIVE_DIRS=( /mnt/corpdfs/esb09/PROD/ESBAP/Archive/fromMphasiS/Qantas/IF341 /mnt/corpdfs/esb09/PROD/ESBAP/Archive/fromMphasiS/Qantas/IF342 )

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
  TO_ENCRYPT_FOLDER=${INPUT_DIRS[$index-1]}
  OUTPUT_FOLDER=${OUTPUT_DIRS[$index-1]}
  ARCHIVE_FOLDER=${ARCHIVE_DIRS[$index-1]}

  # Debugging section
  echo $TO_ENCRYPT_FOLDER
  echo $OUTPUT_FOLDER
  echo $ARCHIVE_FOLDER
  echo "--end loop--"

  # Cut-and-paste of previous individual encryption scripts (proven in UAT)
  # Now that the variables are populated from the outer array
  for f in $TO_ENCRYPT_FOLDER/*
  do
    echo "Attempting to encrypt $f"
    gpg --yes --batch --no-tty --output $OUTPUT_FOLDER/${f##*/}.pgp --encrypt --recipient interface@eqplx004.eqs.qantas.com.au $f
    RETURN_CODE=$?
    if [ $RETURN_CODE -ne 0 ]; then 
      echo "Failed to encrypt $f"
    else
      echo "$f encrypted and moved to $OUTPUT_FOLDER"
      echo "$f moving to archive"
      mv $f $ARCHIVE_FOLDER/
    fi
  done

done
