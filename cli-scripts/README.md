# Helpful Azure CLI Snippets

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
