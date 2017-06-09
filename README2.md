# Instructions

# Create a Storage Account to host scripts and act as a file store.

**Step 1.** Create the Resource Group to use.

```
az login
AZURE_LOCATION=southcentralus
AZURE_GROUP=ansible
az group create -n ${AZURE_GROUP} --location ${AZURE_LOCATION}
```

**Step 2.** Create a Storage Account and obtain the Storage Key

```
UNIQUE=<your_unique_string>
AZURE_STORAGE_ACCOUNT=${UNIQUE}ansiblestorage
az storage account create -n ${AZURE_STORAGE_ACCOUNT} -g ${AZURE_GROUP} -l ${AZURE_LOCATION} --sku Standard_LRS --kind Storage
AZURE_STORAGE_KEY=$(az storage account keys list --account-name ${AZURE_STORAGE_ACCOUNT} --resource-group ${AZURE_GROUP} --query '[0].value' --output tsv)
```

**Step 3.** Create a Script Container and upload the script

```
az storage container create --n scripts --account-name ${AZURE_STORAGE_ACCOUNT} --account-key ${AZURE_STORAGE_KEY} --public-access off
az storage blob upload --container-name scripts --file ./update.sh --name update.sh --account-name ${AZURE_STORAGE_ACCOUNT} --account-key ${AZURE_STORAGE_KEY}
```

> NOTE: File Shares can be created also if desired, but you have to use Storage Explorer to upload files.
```
az storage share create -n scripts --account-name ${AZURE_STORAGE_ACCOUNT}  --account-key ${AZURE_STORAGE_KEY}
```


# Create a Control VM using Azure CLI

**Step 1.** Create the control machine using Azure CLI.

```
AZURE_VM=Control
az vm create -n ${AZURE_VM} -g ${AZURE_GROUP} --image UbuntuLTS --generate-ssh-keys
```

> NOTE: Keys for SSH can manually be created if desired.
```
PASSWORD=<your_password>
ssh-keygen -t rsa -b 2048 -C "user@ansible-sample.com" -f ~/.ssh/id_rsa -n ${PASSWORD}
```

**Step 2.** Execute the Custom Script Extension

```
SETTINGS='{"storageAccountName":"'${AZURE_STORAGE_ACCOUNT}'","storageAccountKey":"'${AZURE_STORAGE_KEY}'"}'

az vm extension set --publisher Microsoft.Azure.Extensions --name CustomScript --version 2.0 --settings '{"fileUris": ["https://'${AZURE_STORAGE_ACCOUNT}'.blob.core.windows.net/scripts/update.sh"], "commandToExecute":"./update.sh"}' --protected-settings ${SETTINGS} --vm-name ${AZURE_VM} --resource-group ${AZURE_GROUP}

az vm extension set --publisher Microsoft.Azure.Extensions --name CustomScript --version 2.0 --settings '{ "commandToExecute":"apt-get -y update"}' --protected-settings ${SETTINGS} --vm-name ${AZURE_VM} --resource-group ${AZURE_GROUP}

```

>Note: You can fire off Commands to execute as you wish
```
COMMAND='shutdown -r now'
az vm extension set --publisher Microsoft.Azure.Extensions --name CustomScript --version 2.0 --settings '{ "commandToExecute":"${COMMAND}"}' --protected-settings ${SETTINGS} --vm-name ${AZURE_VM} --resource-group ${AZURE_GROUP}
```

>Note: Of course you could just ssh to the box mount the fileshare and execute scripts also.
```

```


**Step 2.** Connect to the control Machine.

```
ssh $(az vm list-ip-addresses -o table |grep "${AZURE_VM} " |awk '{print $2}')
```

>NOTE: DNS Name will be {HOSTNAME}.{LOCATION}.cloudapp.azure.com

**Step 3.** Upgrade the Machine and install Azure CLI

```
sudo apt-get update
sudo apt-get upgrade
sudo apt-get dist-upgrade
sudo apt-get install -y libssl-dev libffi-dev python-dev build-essential python-pip
curl -L https://aka.ms/InstallAzureCli | bash
sudo shutdown -r now
```
