#!/bin/bash

if [ -z "$1" ]
  then
    echo '$1 Unique string Argument required.'
    exit 1
fi

UNIQUE=$1
AZURE_LOCATION=eastus
AZURE_GROUP=${UNIQUE}-ansible
AZURE_STORAGE_ACCOUNT=${UNIQUE}ansiblestorage
AZURE_VM=Control
AZURE_KEYVAULT=${UNIQUE}ansiblevault

# Register the provider
az provider register -n Microsoft.KeyVault



# Create Resource Group
tput setaf 1; echo 'Creating the Resource Group...' ; tput sgr0
tput setaf 1; echo '------------------------------' ; tput sgr0
az group create -n ${AZURE_GROUP} \
    --location ${AZURE_LOCATION}

# Create a Key Vault for storing keys and enabled for disk encryption.
tput setaf 1; echo 'Creating the Key Vault...' ; tput sgr0
tput setaf 1; echo '------------------------------' ; tput sgr0
az keyvault create --name ${AZURE_KEYVAULT} \
  --resource-group ${AZURE_GROUP} \
  --location ${AZURE_LOCATION} \
  --enabled-for-disk-encryption True


# Create an Azure Active Directory service principal for authenticating requests to Key Vault.
# Read in the service principal ID and password for use in later commands.
tput setaf 1; echo 'Creating the Service Principals...' ; tput sgr0
tput setaf 1; echo '------------------------------' ; tput sgr0
read AZURE_SP_ID AZURE_SP_PASSWORD <<< $(az ad sp create-for-rbac --query [appId,password] -o tsv)

# Grant permissions on the Key Vault to the AAD service principal.
az keyvault set-policy --name ${AZURE_KEYVAULT} \
  --spn ${AZURE_SP_ID} \
  --key-permissions all \
  --secret-permissions all

# Create Storage Account and obtain the Storage Key
tput setaf 1; echo 'Creating the Storage Account...' ; tput sgr0
tput setaf 1; echo '-------------------------------' ; tput sgr0
az storage account create -n ${AZURE_STORAGE_ACCOUNT} -g ${AZURE_GROUP} \
    --location ${AZURE_LOCATION} \
    --sku Standard_LRS \
    --kind Storage \
    --encryption {file,blob}
AZURE_STORAGE_KEY=$(az storage account keys list --account-name ${AZURE_STORAGE_ACCOUNT} --resource-group ${AZURE_GROUP} --query '[0].value' --output tsv)

# Upload the Custom Update Script to the Storage Container
tput setaf 1; echo 'Uploading Scripts to Blob...' ; tput sgr0
tput setaf 1; echo '------------------------' ; tput sgr0
az storage container create --n scripts \
  --account-name ${AZURE_STORAGE_ACCOUNT} \
  --account-key ${AZURE_STORAGE_KEY} \
  --public-access off

az storage blob upload \
  --container-name scripts \
  --file ./scripts/mount.sh \
  --name mount.sh \
  --account-name ${AZURE_STORAGE_ACCOUNT} \
  --account-key ${AZURE_STORAGE_KEY}

az storage blob upload \
  --container-name scripts \
  --file ./scripts/update.sh \
  --name update.sh \
  --account-name ${AZURE_STORAGE_ACCOUNT} \
  --account-key ${AZURE_STORAGE_KEY}

# Create a File Share to be mounted
tput setaf 1; echo 'Creating a File Share...' ; tput sgr0
tput setaf 1; echo '------------------------' ; tput sgr0
az storage share create -n scripts \
    --account-name ${AZURE_STORAGE_ACCOUNT} \
    --account-key ${AZURE_STORAGE_KEY}

# Create the Virtual Machine
# OPTION 1 is to run a custom data script at create time.
tput setaf 1; echo 'Creating a Virtual Machine...' ; tput sgr0
tput setaf 1; echo '-----------------------------' ; tput sgr0
az vm create -n ${AZURE_VM} -g ${AZURE_GROUP} \
             --image UbuntuLTS \
             --generate-ssh-keys \
             --custom-data cloud-init.yml

# OPTION 2 is to run a Custom Script Extension with an  Embedded Command
SETTINGS='{"storageAccountName":"'${AZURE_STORAGE_ACCOUNT}'","storageAccountKey":"'${AZURE_STORAGE_KEY}'"}'
az vm extension set --name CustomScript \
  --publisher Microsoft.Azure.Extensions  \
  --version 2.0 \
  --settings '{ "commandToExecute":"echo ""From command $(date -R)!"" | tee /var/log/custom-script-option2.log"}' \
  --protected-settings ${SETTINGS} \
  --vm-name ${AZURE_VM} \
  --resource-group ${AZURE_GROUP}

# OPTION 3 is to run a Custom Script Extension from an Uploaded Blob File
az vm extension set --name CustomScript \
  --publisher Microsoft.Azure.Extensions \
  --version 2.0 \
  --settings '{"fileUris": ["https://'${AZURE_STORAGE_ACCOUNT}'.blob.core.windows.net/scripts/update.sh"], "commandToExecute":"sh ./update.sh"}' \
  --protected-settings ${SETTINGS} \
  --vm-name ${AZURE_VM} \
  --resource-group ${AZURE_GROUP}


az vm restart --resource-group ${AZURE_GROUP} --name ${AZURE_VM}

# Add Key to KeyVault and Encrypt
az keyvault key create --vault-name ${AZURE_KEYVAULT} --name ${AZURE_VM}Encrypt --protection software

# Encrypt the VM disks.
tput setaf 1; echo 'Encrypting the VM Disks...' ; tput sgr0
tput setaf 1; echo '-----------------------------' ; tput sgr0

# az vm encryption enable --resource-group ${AZURE_GROUP} --name ${AZURE_VM} \
#   --aad-client-id ${AZURE_SP_ID} \
#   --aad-client-secret ${AZURE_SP_PASSWORD} \
#   --disk-encryption-keyvault ${AZURE_KEYVAULT} \
#   --key-encryption-key ${AZURE_VM}Encrypt \
#   --volume-type all

# Output how to monitor the encryption status and next steps.
IP=$(az vm list-ip-addresses -g ${AZURE_GROUP} -n ${AZURE_VM} --query [0].virtualMachine.network.publicIpAddresses[0].ipAddress -o tsv)
echo "The encryption process is underway and can take some time. View status with:

    az vm encryption show --resource-group ${AZURE_GROUP} --name ${AZURE_VM} --query [osDisk] -o tsv

When encryption status shows \`VMRestartPending\`, restart the VM with:

    az vm restart --resource-group ${AZURE_GROUP} --name ${AZURE_VM}

You can now ssh to your server with:

    ssh ${IP}"
