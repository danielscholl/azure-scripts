#!/bin/bash

if [ -z "$1" ]
  then
    echo '$1 Unique string Argument required.'
    exit 1
fi

# Set Environment Variables
UNIQUE=$1
AZURE_LOCATION=southcentralus
AZURE_GROUP=${UNIQUE}-ansible
AZURE_STORAGE_ACCOUNT=${UNIQUE}ansiblestorage
AZURE_VM=Control
AZURE_KEYVAULT=${UNIQUE}ansiblevault
CUSTOM_SCRIPT=azure-cli.sh


# Create Resource Group
tput setaf 1; echo 'Creating the Resource Group...' ; tput sgr0
tput setaf 1; echo '------------------------------' ; tput sgr0
az group create -n ${AZURE_GROUP} \
    --location ${AZURE_LOCATION}



# Create Storage Account and obtain the Storage Key
tput setaf 1; echo 'Creating the Storage Account...' ; tput sgr0
tput setaf 1; echo '-------------------------------' ; tput sgr0
az storage account create -n ${AZURE_STORAGE_ACCOUNT} -g ${AZURE_GROUP} \
    --location ${AZURE_LOCATION} \
    --sku Standard_LRS \
    --kind Storage \
    --encryption {file,blob}

AZURE_STORAGE_KEY=$(az storage account keys list --account-name ${AZURE_STORAGE_ACCOUNT} --resource-group ${AZURE_GROUP} --query '[0].value' --output tsv)


# Create a Storage Container
az storage container create --n scripts \
  --account-name ${AZURE_STORAGE_ACCOUNT} \
  --account-key ${AZURE_STORAGE_KEY} \
  --public-access off

# Create a File Share to be mounted
az storage share create -n scripts \
    --account-name ${AZURE_STORAGE_ACCOUNT} \
    --account-key ${AZURE_STORAGE_KEY}



# Create the Virtual Machine
tput setaf 1; echo 'Creating a Virtual Machine...' ; tput sgr0
tput setaf 1; echo '-----------------------------' ; tput sgr0
az vm create -n ${AZURE_VM} -g ${AZURE_GROUP} \
             --image UbuntuLTS \
             --generate-ssh-keys \
             --custom-data cloud-init.yml

############################
## Custom Script Option 1 ##
############################
# tput setaf 1; echo 'Executing CustomScript Extension...' ; tput sgr0
# tput setaf 1; echo '------------------------' ; tput sgr0
#
# az vm extension set --name CustomScript \
#   --publisher Microsoft.Azure.Extensions  \
#   --version 2.0 \
#   --settings '{ "commandToExecute":"echo ""From command $(date -R)!"" | tee /var/log/custom-script-option2.log"}' \
#   --protected-settings ${SETTINGS} \
#   --vm-name ${AZURE_VM} \
#   --resource-group ${AZURE_GROUP}



############################
## Custom Script Option 2 ##
############################
tput setaf 1; echo 'Uploading custom-script.sh to Blob and Executing CustomScript Extension...' ; tput sgr0
tput setaf 1; echo '------------------------' ; tput sgr0

az storage blob upload \
  --container-name scripts \
  --file ./${CUSTOM_SCRIPT} \
  --name custom-script.sh \
  --account-name ${AZURE_STORAGE_ACCOUNT} \
  --account-key ${AZURE_STORAGE_KEY}

# Get the Settings Information
SETTINGS='{"storageAccountName":"'${AZURE_STORAGE_ACCOUNT}'","storageAccountKey":"'${AZURE_STORAGE_KEY}'"}'

## Execute the Custom Script Extension
az vm extension set --name CustomScript \
  --publisher Microsoft.Azure.Extensions \
  --version 2.0 \
  --settings '{"fileUris": ["https://'${AZURE_STORAGE_ACCOUNT}'.blob.core.windows.net/scripts/custom-script.sh"], "commandToExecute":"bash ./custom-script.sh"}' \
  --protected-settings ${SETTINGS} \
  --vm-name ${AZURE_VM} \
  --resource-group ${AZURE_GROUP}

## Reboot the VM Server  (Optional)
tput setaf 1; echo 'Rebooting the Server...' ; tput sgr0
tput setaf 1; echo '------------------------' ; tput sgr0
az vm restart --resource-group ${AZURE_GROUP} --name ${AZURE_VM}



############################
## Encrypt the OS DISK    ##
############################
tput setaf 1; echo 'Encrypting the OS Disk...' ; tput sgr0
tput setaf 1; echo '------------------------' ; tput sgr0

# Register the provider
az provider register -n Microsoft.KeyVault

# Create an Azure Active Directory service principal for authenticating requests to Key Vault.
# Read in the service principal ID and password for use in later commands.
read AZURE_SP_ID AZURE_SP_PASSWORD <<< $(az ad sp create-for-rbac --query [appId,password] -o tsv)

# Create a Key Vault for storing keys and enabled for disk encryption.
tput setaf 1; echo 'Creating a Key Vault and setting a encryption key...' ; tput sgr0
tput setaf 1; echo '------------------------------' ; tput sgr0
az keyvault create --name ${AZURE_KEYVAULT} \
  --resource-group ${AZURE_GROUP} \
  --location ${AZURE_LOCATION} \
  --enabled-for-disk-encryption true

# Grant permissions on the Key Vault to the AAD service principal.
az keyvault set-policy --name ${AZURE_KEYVAULT} \
  --spn ${AZURE_SP_ID} \
  --key-permissions all \
  --secret-permissions all

# Add Key to KeyVault and Encrypt
az keyvault key create --vault-name ${AZURE_KEYVAULT} --name ${AZURE_VM}Encrypt --protection software


# Encrypt the VM disks.
az vm encryption enable --resource-group ${AZURE_GROUP} --name ${AZURE_VM} \
  --aad-client-id ${AZURE_SP_ID} \
  --aad-client-secret ${AZURE_SP_PASSWORD} \
  --disk-encryption-keyvault ${AZURE_KEYVAULT} \
  --key-encryption-key ${AZURE_VM}Encrypt \
  --volume-type all

# Output how to monitor the encryption status and next steps.
IP=$(az vm list-ip-addresses -g ${AZURE_GROUP} -n ${AZURE_VM} --query [0].virtualMachine.network.publicIpAddresses[0].ipAddress -o tsv)
echo "The encryption process is underway and can take some time. View status with:

    az vm encryption show --resource-group ${AZURE_GROUP} --name ${AZURE_VM} --query [osDisk] -o tsv

When encryption status shows \`VMRestartPending\`, restart the VM with:

    az vm restart --resource-group ${AZURE_GROUP} --name ${AZURE_VM}

You can now ssh to your server with:

    ssh ${IP}"
