#!/usr/bin/env bash
# Copyright (c) 2017, cloudcodeit.com
#
#  Purpose: SSH Connect to the Azure Virtual Machine
#  Usage:
#    connect.sh <unique>

###############################
## ARGUMENT INPUT            ##
###############################
usage() { echo "Usage: manage.sh <RESOURCE_GROUP> <command>" 1>&2; exit 1; }

if [ -f ~/.azure/.env ]; then source ~/.azure/.env; fi
if [ -f ./.env ]; then source ./.env; fi
if [ -f ./functions.sh ]; then source ./functions.sh; fi

if [ ! -z $1 ]; then RESOURCE_GROUP=$1; fi
if [ -z $RESOURCE_GROUP ]; then
  tput setaf 1; echo 'ERROR: RESOURCE_GROUP not found' ; tput sgr0
  usage;
fi
if [ -z ${AZURE_LOCATION} ]; then
  tput setaf 1; echo 'ERROR: Global Variable AZURE_LOCATION not set'; tput sgr0
  exit 1;
fi

#////////////////////////////////
RESOURCE_GROUP=${UNIQUE}-${CATEGORY}

VMS_IDS=$(az vm list -g ${RESOURCE_GROUP} --query "[].id" -o tsv)

case $2 in
start)
  echo "Starting all Virtual Machines in " ${RESOURCE_GROUP}
  az vm start --ids ${VMS_IDS}
  ;;
stop)
  echo "Stopping all Virtual Machines in " ${RESOURCE_GROUP}
  az vm stop --ids ${VMS_IDS}
  ;;
*)
  echo "Deallocating all Virtual Machines in " ${RESOURCE_GROUP}
  az vm deallocate --ids ${VMS_IDS}
  ;;
esac
