#!/bin/bash
# Copyright (c) 2017, cloudcodeit.com

if [ -z "$1" ]
  then
    echo '$1 Unique string Argument required.'
    exit 1
fi
UNIQUE=$1
AZURE_STORAGE_ACCOUNT=${UNIQUE}ansiblestorage
AZURE_GROUP=${UNIQUE}-ansible
AZURE_STORAGE_KEY=$(az storage account keys list --account-name ${AZURE_STORAGE_ACCOUNT} --resource-group ${AZURE_GROUP} --query '[0].value' --output tsv)
DIRECTORY=~/.azure

if [ ! -d ${DIRECTORY} ]; then
 mkdir ${DIRECTORY}
fi

az storage blob download \
  --container-name scripts \
  --file ${DIRECTORY}/credentials \
  --name credentials \
  --account-name ${AZURE_STORAGE_ACCOUNT} \
  --account-key ${AZURE_STORAGE_KEY} \
  --output table
