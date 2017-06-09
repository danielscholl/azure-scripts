#!/bin/bash

if [ -z "$1" ]
  then
    echo '$1 Unique string Argument required.'
    exit 1
fi

UNIQUE=$1
AZURE_LOCATION=southcentralus
AZURE_GROUP=${UNIQUE}-ansible
AZURE_STORAGE_ACCOUNT=${UNIQUE}ansiblestorage
AZURE_VM=$2
AZURE_KEYVAULT=${UNIQUE}ansiblevault


# Create the Virtual Machine
tput setaf 1; echo 'Creating a Virtual Machine...' ; tput sgr0
tput setaf 1; echo '-----------------------------' ; tput sgr0
az vm create -n ${AZURE_VM} -g ${AZURE_GROUP} \
             --image UbuntuLTS \
             --generate-ssh-keys \
             --custom-data myscript.sh

# Copy Scripts to the server
IP=$(az vm list-ip-addresses -g ${AZURE_GROUP} -n ${AZURE_VM} --query [0].virtualMachine.network.publicIpAddresses[0].ipAddress -o tsv)
az vm restart --resource-group ${AZURE_GROUP} --name ${AZURE_VM}

# Output to next steps.
echo "You can now ssh to your server with:

    ssh ${IP}"
