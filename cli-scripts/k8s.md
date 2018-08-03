
# Instructions

Create a .env.ps1 file with the following settings as defined in the Tutorial Document

[https://docs.microsoft.com/en-us/azure/aks/aad-integration](https://docs.microsoft.com/en-us/azure/aks/aad-integration)

```powershell
## Sample Environment File
$Env:AZURE_AKSAADServerId = ""                  # Desired Service Principal Server Id
$Env:AZURE_AKSAADServerSecret = ""              # Desired Service Princiapl Server Key
$Env:AZURE_AKSAADClientId = ""                  # Desired Service Princiapl Client Id
$Env:AZURE_TENANT = ""                          # Desired Tenant Id
```


```powershell
# Assumes CLI Version = azure-cli (2.0.43)

$ResourceGroup="k8s"
$Location="eastus"

# Create a resource group.
az group create `
  --name $ResourceGroup `
  --location $Location


# Create a virtual network with a Container subnet.
$VNet="k8s-vnet"
$AddressPrefix="10.0.0.0/16"
$ContainerTier="10.0.1.0/24"

az network vnet create `
    --name $VNet `
    --resource-group $ResourceGroup `
    --location $Location `
    --address-prefix $AddressPrefix `
    --subnet-name ContainerTier `
    --subnet-prefix $ContainerTier


# Create a virtual network with a Backend subnet.
$BackendTier="10.0.2.0/24"

az network vnet subnet create `
    --name BackendTier `
    --address-prefix $BackendTier `
    --resource-group $ResourceGroup `
    --vnet-name $VNet


# Create a Kubernetes Cluster on the Container subnet with RBAC.
$Cluster="k8sCluster"
$NodeSize="Standard_D3_v2"
$DockerBridgeCidr="172.17.0.1/16"
$ServiceCidr="10.25.0.0/16"
$DNSServiceIP="10.25.0.10"
$SubnetId=$(az network vnet subnet show --resource-group $ResourceGroup --vnet-name $VNet --name ContainerTier --query id -otsv)

# Source the Environment File containing Service Principal and Tenant information
. ./.env.ps1

az aks create --name $Cluster `
    --resource-group $ResourceGroup `
    --location $Location `
    --enable-rbac `
    --aad-server-app-id $env:AZURE_AKSAADServerId  `
    --aad-server-app-secret $env:AZURE_AKSAADServerSecret  `
    --aad-client-app-id $env:AZURE_AKSAADClientId  `
    --aad-tenant-id $env:AZURE_TENANT `
    --generate-ssh-keys `
    --node-vm-size $NodeSize `
    --node-count 1 `
    --docker-bridge-address $DockerBridgeCidr `
    --service-cidr $ServiceCidr `
    --dns-service-ip $DNSServiceIP `
    --vnet-subnet-id $SubnetId `
    --network-plugin azure
```
