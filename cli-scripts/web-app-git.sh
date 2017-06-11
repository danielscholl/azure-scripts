#!/usr/bin/env bash
# Copyright (c) 2017, cloudcodeit.com
#
#  Purpose: Create a App Service Web App
#  Usage:
#    web-app-git.sh <unique> <src_directory> <location>


###############################
## SCRIPT SETUP              ##
###############################

if [ -f ~/.azure/.env ]; then source ~/.azure/.env; fi

if [ ! -z $1 ]; then UNIQUE=$1; fi
if [ ! -z $2 ]; then SOURCE=$2; fi
if [ ! -z $3 ]; then AZURE_LOCATION=$3; else AZURE_LOCATION=southcentralus; fi
if [ -z $AZURE_DEPLOY_USER ]; then echo 'Environment not set: AZURE_DEPLOY_USER'; exit; fi
if [ -z $AZURE_DEPLOY_PASSWORD ]; then echo 'Environment not set: AZURE_DEPLOY_PASSWORD'; exit; fi

AZURE_GROUP=${UNIQUE}-webapp
AZURE_WEB_APP=$UNIQUE-webapp


#######################
## Create Web App    ##
#######################

# Create Resource Group
# tput setaf 1; echo 'Creating the Resource Group...' ; tput sgr0
# tput setaf 1; echo '------------------------------' ; tput sgr0
# az group create -n ${AZURE_GROUP} \
#     --location ${AZURE_LOCATION}


# Create an App Service plan in FREE tier.
# tput setaf 1; echo 'Creating the App Service Plan...' ; tput sgr0
# tput setaf 1; echo '--------------------------------' ; tput sgr0
# az appservice plan create --name ${AZURE_WEB_APP} \
#   --resource-group ${AZURE_GROUP} \
#   --sku FREE

# Create a web app.
# tput setaf 1; echo 'Creating the Web App...' ; tput sgr0
# tput setaf 1; echo '-----------------------' ; tput sgr0
# az appservice web create --name ${AZURE_WEB_APP} \
#   --resource-group ${AZURE_GROUP} \
#   --plan ${AZURE_WEB_APP}

# Set the account-level deployment credentials
az appservice web deployment user set \
  --user-name ${AZURE_DEPLOY_USER} \
  --password ${AZURE_DEPLOY_PASSWORD}

# Configure local Git and get deployment URL
# GIT_URL=$(az appservice web source-control config-local-git \
#   --name ${AZURE_WEB_APP} \
#   --resource-group ${AZURE_GROUP} \
#   --query url --output tsv)

# Add the Azure remote to your local Git respository and push your code
cd ${SOURCE}
git remote add azure ${GIT_URL}
git push azure master

# When prompted for password, use the value of $password that you specified

# Browse to the deployed web app.
az appservice web browse --name ${AZURE_WEB_APP} \
  --resource-group ${AZURE_GROUP}
