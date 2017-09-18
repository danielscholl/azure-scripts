#!/usr/bin/env bash
# Copyright (c) 2017, cloudcodeit.com
#
#  Purpose: Create a App Service Web App
#  Usage:
#    jenkins.sh <unique> <location>


###############################
## SCRIPT SETUP              ##
###############################

if [ -f ~/.azure/.env ]; then source ~/.azure/.env; fi

if [ ! -z $1 ]; then USER=$1; fi
if [ ! -z $2 ]; then LOCATION=$2; else LOCATION=southcentralus; fi


RESOURCE_GROUP=jenkins
NAME=jenkinsVM
IMG=UbuntuLTS
SIZE=Standard_DS1_v2
HOST=$(az vm show --resource-group ${RESOURCE_GROUP} --name ${NAME} -d --query [publicIps] --o tsv)

if [ -z ${HOST} ]; then
  az group create -n ${RESOURCE_GROUP} --location ${LOCATION}

  az vm create --resource-group ${RESOURCE_GROUP} \
      --name ${NAME} \
      --image UbuntuLTS \
      --admin-username ${USER} \
      --generate-ssh-keys \
      --custom-data jenkins-init.txt

  az vm open-port --resource-group ${RESOURCE_GROUP} --name ${NAME} --port 8080 --priority 1001
  az vm open-port --resource-group ${RESOURCE_GROUP} --name ${NAME} --port 1337 --priority 1002
  echo 'Wait for 1 minute while server configures then rerun script for password'
  exit 0;
fi

echo "http://${HOST}:8080"
echo "Password: $(ssh -t ${USER}@${HOST} sudo cat /var/lib/jenkins/secrets/initialAdminPassword)"
#ssh -t ${USER}@${HOST} sudo cat /var/lib/jenkins/secrets/initialAdminPassword

