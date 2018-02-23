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



###############################
## FUNCTIONS                 ##
###############################
function CreateResourceGroup() {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = LOCATION

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (RESOURCE_GROUP) not received'; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (LOCATION) not received'; tput sgr0
    exit 1;
  fi

  local _result=$(az group show --name $1)
  if [ "$_result"  == "" ]
    then
      OUTPUT=$(az group create --name $1 \
        --location $2 \
        -ojsonc)
    else
      tput setaf 3;  echo "Resource Group $1 already exists."; tput sgr0
    fi
}
function CreateAppServicePlan() {
  # Required Argument $1 = WEB_PLAN
  # Required Argument $2 = RESOURCE_GROUP

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (WEB_PLAN) not received'; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (RESOURCE_GROUP) not received'; tput sgr0
    exit 1;
  fi

  local _result=$(az appservice plan show --resource-group $2 --name $1)
  if [ "$_result"  == "" ]
    then
      OUTPUT=$(az appservice plan create --name $1 \
        --resource-group $2 \
        --sku FREE \
        -ojsonc)
    else
      tput setaf 3;  echo "App Service Plan $2 already exists."; tput sgr0
    fi
}
function CreateWebApp() {
  # Required Argument $1 = WEB_APP
  # Required Argument $2 = APP_PLAN
  # Required Argument $3 = RESOURCE_GROUP

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (WEB_APP) not received'; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (APP_PLAN) not received'; tput sgr0
    exit 1;
  fi
  if [ -z $3 ]; then
    tput setaf 1; echo 'ERROR: Argument $3 (RESOURCE_GROUP) not received'; tput sgr0
    exit 1;
  fi

  local _result=$(az webapp list --resource-group $2 -otsv)
  if [ "$_result"  == "" ]
    then
      OUTPUT=$(az webapp create --name $1 \
        --resource-group $3 \
        --plan $2 \
        -ojsonc)
    else
      tput setaf 3;  echo "Web App $2 already exists."; tput sgr0
    fi
}



#######################
## Create Web App    ##
#######################

# Create Resource Group
tput setaf 1; echo 'Creating the Resource Group...' ; tput sgr0
tput setaf 1; echo '------------------------------' ; tput sgr0
CreateResourceGroup ${AZURE_GROUP} ${AZURE_LOCATION}


# Create an App Service plan in FREE tier.
tput setaf 1; echo 'Creating the App Service Plan...' ; tput sgr0
tput setaf 1; echo '--------------------------------' ; tput sgr0
CreateAppServicePlan ${AZURE_WEB_APP} ${AZURE_GROUP}

# Create a web app.
tput setaf 1; echo 'Creating the Web App...' ; tput sgr0
tput setaf 1; echo '-----------------------' ; tput sgr0
CreateWebApp ${AZURE_WEB_APP} ${AZURE_WEB_APP} ${AZURE_GROUP}


# Configure local Git and get deployment URL
GIT_URL=$(az webapp deployment source config-local-git \
  --name ${AZURE_WEB_APP} \
  --resource-group ${AZURE_GROUP} \
  --query url --output tsv)

echo $GIT_URL
# Add the Azure remote to your local Git respository and push your code
git clone ${GIT_URL} $SOURCE
git remote add azure ${GIT_URL}

