# Helpful Azure CLI Snippets


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

# Set the account-level deployment credentials if needed
UserName=devops
az webapp deployment user set --user-name ${UserName}

# Configure local Git and get deployment URL
url=$(az webapp deployment source config-local-git --name ${WebApp} \
--resource-group myResourceGroup --query url --output tsv)
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
