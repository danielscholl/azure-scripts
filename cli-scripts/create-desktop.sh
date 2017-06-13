#!/usr/bin/env bash
# Copyright (c) 2017, cloudcodeit.com
#
#  Purpose: Install a VM Ready to act as a Windows Desktop Station
#  Usage:
#    create-desktop.sh <unique> <location> <vm_name>
#

if [ -z "$1" ]; then echo '$1 Unique string Argument required.'; exit 1; fi


###############################
## SCRIPT SETUP              ##
###############################

# Set Environment Variables
UNIQUE=$1
DATE=$(date "+%Y-%m-%d-%H-%M-%S")
AZURE_GROUP=${UNIQUE}-lab
AZURE_STORAGE_ACCOUNT=${UNIQUE}labstorage$(date "+%m%d%Y")
if [ ! -z $2 ]; then AZURE_LOCATION=$2; else AZURE_LOCATION=southcentralus; fi
if [ ! -z $3 ]; then AZURE_VM=$3; else AZURE_VM=WorkStation; fi

CUSTOM_SCRIPT=../configurations/workstation.ps1


###############################
## Create Resource Group     ##
###############################

# Create Resource Group
tput setaf 2; echo 'Creating the Resource Group...' ; tput sgr0
tput setaf 2; echo '------------------------------' ; tput sgr0

# Create the Resource Group
az group create \
    --name ${AZURE_GROUP} \
    --location ${AZURE_LOCATION}



###############################
## Create Network            ##
###############################

# Create the Network
tput setaf 2; echo 'Creating the Network...' ; tput sgr0
tput setaf 2; echo '------------------------------' ; tput sgr0

# Create a Virtual network
az network vnet create \
    --name ${AZURE_GROUP}VNet \
    --subnet-name Subnet \
    --resource-group ${AZURE_GROUP}

# Create a network security group.
az network nsg create \
  --name ${AZURE_GROUP}-nsg \
  --resource-group ${AZURE_GROUP}

# Create a public IP address.
az network public-ip create \
  --name ${AZURE_GROUP}-ip \
  --resource-group ${AZURE_GROUP}

# Create a virtual network card and associate with public IP address and NSG.
az network nic create \
  --name ${AZURE_GROUP}-nic \
  --resource-group ${AZURE_GROUP}\
  --vnet-name ${AZURE_GROUP}VNet \
  --subnet Subnet \
  --network-security-group ${AZURE_GROUP}-nsg \
  --public-ip-address ${AZURE_GROUP}-ip


###############################
## Create Virtual Machine    ##
###############################

# Create the Virtual Machine
tput setaf 2; echo 'Creating a Virtual Machine...' ; tput sgr0
tput setaf 2; echo '-----------------------------' ; tput sgr0

AZURE_IMAGE=MicrosoftVisualStudio:VisualStudio:VS-2017-Ent-Win10-N:2017.05.24
#AZURE_IMAGE=Win2012R2Datacenter

# Create a virtual machine.
az vm create \
    --name ${AZURE_VM} \
    --resource-group ${AZURE_GROUP} \
    --location ${AZURE_LOCATION} \
    --image ${AZURE_IMAGE} \
    --nics ${AZURE_GROUP}-nic \
    --nsg-rule rdp \
    --admin-username $(whoami) \
    --authentication-type password


# Open port 3389 to allow RDP traffic to host.
## NOTE: Works but causes an Error Due to Issue #3322
##  https://github.com/Azure/azure-cli/issues/3322
az vm open-port \
  --name ${AZURE_VM}  \
  --resource-group ${AZURE_GROUP} \
  --port 3389


## Reboot the VM Server  (Optional)
tput setaf 2; echo 'Rebooting the Server...' ; tput sgr0
tput setaf 2; echo '------------------------' ; tput sgr0
az vm restart --resource-group ${AZURE_GROUP} --name ${AZURE_VM}



# Output how to monitor the encryption status and next steps.
IP=$(az vm list-ip-addresses -g ${AZURE_GROUP} -n ${AZURE_VM} --query [0].virtualMachine.network.publicIpAddresses[0].ipAddress -o tsv)
echo "You can now RDP to your server with:

    RDP://${IP}

"
