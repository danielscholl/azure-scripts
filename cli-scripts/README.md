# Helpful Azure CLI Snippets

### General Items

```bash
# Use Command Line in Interactive Mode
az interactive

# Search CLI Commands for a word
az find -q vm
az find -q storage

# Configure the CLI with a default setting
az configure
az configure -d group:533

az account list-locations -o table
```


### Resource Groups

```bash
# List Resource Groups
az groups list -otable

# List Locations
az account list-locations -o table

# Create Resource Group
ResourceGroup="533"
Location="southcentralus"
az group create --name ${ResourceGroup} \
  --location ${Location}

# List all Resources in a Group
az resource list --resource-group ${ResourceGroup}
```

### Storage Accounts and Containers

```bash
# Create a Storage Account
StorageAccount="533storage"$(date "+%m%d%Y")
az storage account check-name --name ${StorageAccount}
az storage account create --name ${StorageAccount} \
  --resource-group ${ResourceGroup} \
  --location ${Location} \
  --sku "Standard_LRS"

# Set Storage Account Context
export AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string --name ${StorageAccount} \
    --resource-group ${ResourceGroup})

# Create Storage Container using Current Storage Account
Source="source"
Destination="destination"
az storage container create --name ${Source}
az storage container create --name ${Destination}

# Get Storage Account Key
az storage account keys list --account-name ${StorageAccount} \
  --resource-group ${ResourceGroup} \
  --query '[0].value' \
  --output tsv

# Regenerate Storage Key
az storage account keys renew --account-name ${StorageAccount} \
  --resource-group ${ResourceGroup} \
  --key secondary
```

### Working with Resources

```bash
# Create a Tag
az tag create --name test
az tag add-value --name test --value 532
az tag add-value --name test --value 533

# Tag a Resource
az group update --name ${ResourceGroup} --set tags.test=533

# List all Resourcew with a Tag
az resource list --tag test=533
```

### Copy a Blob

```bash
Blob="file.txt"
az storage blob upload --file ${Blob}\
  --container-name ${Source} \
  --name ${Blob}

# Retrieve the current status of the copy operation ###
az storage blob show --container-name ${Source} --name ${Blob}

# List the blobs
az storage blob list --container-name ${Source} --output table
```

### Get a SAS Token

```bash
az storage blob generate-sas \
  --account-name ${StorageAccount} \
  -c ${StorageContainer} \
  -n ${StorageBlob} \
  --permissions r \
  --expiry 2018-01-01T00:00:00Z
```

### Create a SQL Server DB

```bash
# Create a SQL Server
ServerName="dbServer-"$RANDOM
Admin="ServerAdmin"
Password="PasswordAzure@123!"  # Change as Needed

az sql server create \
  --name ${ServerName} \
  --resource-group ${ResourceGroup} \
  --location ${Location} \
  --admin-user ${Admin} \
  --admin-password ${Password}
  
# Configure a firewall rule for the server
IP=$(curl ifconfig.me/ip)

az sql server firewall-rule create \
  --resource-group ${ResourceGroup} \
  --server ${ServerName} \
  -n $HOSTNAME \
  --start-ip-address ${IP} \
  --end-ip-address ${IP}

# Configure a Database
DbName="AdventureWorks"
DbSchema="AdventureWorksLT"

az sql db create \
  --resource-group ${ResourceGroup} \
  --server ${ServerName} \
  --name ${DbName} \
  --sample-name ${DbSchema} \
  --service-objective S0
```

#### Run a DSC Configuration on a Windows Server

```bash
VMName = "vm1"
URL="https://<your_account>.blob.core.windows.net/scripts/iisinstall.ps1.zip"

az vm extension set \
   --name DSC \
   --publisher Microsoft.Powershell \
   --version 2.19 \
   --vm-name ${VMName} \
   --resource-group ${ResourceGroup} \
   --settings '{"ModulesURL":"${URL}", "configurationFunction": "iisinstall.ps1\\IIIISInstallS", "Properties": {"MachineName": "${VMName"} }'
```

### Configure a Local Git Web Deployment

```bash
ResourceGroup=ds-533-web
Location=southcentralus

# Create a resource group.
az group create --name ${ResourceGroup} \
  --location ${Location}

# Create an App Service plan in FREE tier.
Plan=ds-533-web-plan
az appservice plan create --name ${Plan} \
  --resource-group ${ResourceGroup} \
  --sku FREE

# Create a web app.
WebApp=ds-533-web
az webapp create --name ${WebApp} \
  --resource-group ${ResourceGroup} \
  --plan ${Plan}


# Configure local Git and get deployment URL
URL=$(az webapp deployment source config-local-git --name ${WebApp} \
--resource-group ${ResourceGroup} --query url --output tsv)

# Push up the Git Repo
git remote add azure ${URL}
git push azure master

# Browse to the deployed web app.
az webapp browse --name ${WebApp} --resource-group ${ResourceGroup}

```

### Linux App Service App Using Docker

```bash
# Create a Resource Group
GROUP=community
az group create --name ${GROUP} --location westus

# Create a CosmosDB with Mongo Connector
DB=community-db
az cosmosdb create --name ${DB} --resource-group ${GROUP} --kind MongoDB

CONNECTION=$(az cosmosdb list-connection-strings --name ${DB} --query "connectionStrings[0].connectionString" -o tsv)

# Create a Linux App Service Plan
PLAN=community-plan
az appservice plan create --name ${PLAN} --resource-group ${GROUP} --is-linux

# Create a WebApp with Docker Container
WEBSITE=ccit-nodebb
IMAGE=danielscholl/nodebb:latest
az webapp create --name ${WEBSITE} --resource-group ${GROUP} --plan ${PLAN} -i ${IMAGE}

# Setup Environment Settings
NODEBB_URL=http://${WEBSITE}.azurewebsites.net
NODEBB_SECRET=bdbd1bbc-fe03-41bf-9a0e-b345fd3b6262
NODEBB_DBTYPE=mongo
NODEBB_DB=${CONNECTION}

az webapp config appsettings set -n ${WEBSITE} --settings \
  url=${NODEBB_URL} \
  secret=${NODEBB_SECRET} \
  database=${NODEBB_DBTYPE} \
  mongo__database=${CONNECTION}

```

### Deploy an ARM Template

```bash

ResourceGroup="533"
Location="southcentralus"
URL="https://raw.githubusercontent.com/danielscholl/azure-scripts/master/arm-templates/2-tier-linux/azuredeploy.json"

az group create --name ${ResourceGroup} \
  --location ${Location}

az group deployment create -g ${ResourceGroup} \
  --template-uri ${URL} \
  --parameters MyValue=This MyArray=@array.json

az group deployment create -g ${ResourceGroup} \
  --template-file  azuredeploy2.json \
  --parameters @params.json


```
