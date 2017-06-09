#!/bin/bash

if [ -z "$1" ]
  then
    echo '$1 AZURE_STORAGE_ACCOUNT Argument required.'
    exit 1
  else
    storage_account="$1"
fi

if [ -z "$2" ]
  then
    echo '$2 AZURE_STORAGE_KEY Argument required.'
    exit 1
  else
    storage_key="$2"
fi

if [ -z "$3" ]
  then
    share_name="scripts"
  else
    share_name="$3"
fi

#
# Locally mount the file share
#
if [ ! -d "/mnt/${share_name}" ]; then mkdir "/mnt/${share_name}" fi

mount -t cifs \
	"//${storage_account}.file.core.windows.net/${share_name}" \
	"/mnt/${share_name}" \
	-o "vers=3.0,user=${storage_account},password=${access_key},dir_mode=0777,file_mode=0777"
