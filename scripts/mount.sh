#!/usr/bin/env bash
# Copyright (c) 2017, cloudcodeit.com
#
#  Purpose: Mount an Azure File Share
#  Usage:
#    sudo mount.sh <share> <account> <key>
#
#  Sample Environment File: ~/.azure/.env
#   -------------------------------
#    export AZURE_STORAGE_ACCOUNT=<your_account>
#    export AZURE_STORAGE_KEY=<your_key>
#

if [ -f ~/.azure/.env ]; then source ~/.azure/.env; fi

if [ ! -z $1 ]; then SHARE=$1; fi
if [ ! -z $2 ]; then AZURE_STORAGE_ACCOUNT=$2; fi
if [ ! -z $3 ]; then AZURE_STORAGE_KEY=$3; fi
if [ -z $SHARE ]; then SHARE=clouddrive; fi
if [ -z $AZURE_STORAGE_ACCOUNT ]; then echo 'Argument not Found: AZURE_STORAGE_ACCOUNT'; exit; fi
if [ -z $AZURE_STORAGE_KEY ]; then echo 'Argument not Found: AZURE_STORAGE_KEY'; exit; fi

# Debug
echo ${SHARE}
echo ${AZURE_STORAGE_ACCOUNT}
echo ${AZURE_STORAGE_KEY}
exit

# Locally mount the file share
if [ ! -d "/mnt/${SHARE}" ]; then
  mkdir "/mnt/${SHARE}"
fi
mount -t cifs \
	"//${AZURE_STORAGE_ACCOUNT}.file.core.windows.net/${SHARE}" \
	"/mnt/${SHARE}" \
	-o "vers=3.0,user=${AZURE_STORAGE_ACCOUNT},password=${AZURE_STORAGE_KEY},dir_mode=0777,file_mode=0777"
