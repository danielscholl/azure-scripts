
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



<#
- Azure VNET can be as large as /8 but a cluster may only have 16,000 configured IP addresses
- Subnet must be large enough to accomodate the nodes, pods, and all k8s and Azure resources 
  that might be provisioned in the cluster.  ie: Load Balancer(s)

  (number of nodes) + (number of nodes * pods per node)
         (3)        +                (3*30)  = 93 IP Addresses     
#>

# Create a virtual network with a Container subnet.
$VNet="k8s-vnet"
$AddressPrefix="10.0.0.0/16"    # 65,536 Addresses
$ContainerTier="10.0.0.0/20"    # 4,096  Addresses


az network vnet create `
    --name $VNet `
    --resource-group $ResourceGroup `
    --location $Location `
    --address-prefix $AddressPrefix `
    --subnet-name ContainerTier `
    --subnet-prefix $ContainerTier


# Create a virtual network with a Backend subnet.
$BackendTier="10.0.16.0/24"      # 254 Addresses

az network vnet subnet create `
    --name BackendTier `
    --address-prefix $BackendTier `
    --resource-group $ResourceGroup `
    --vnet-name $VNet


<#
- ServiceCidr must be smaller then /12 and not used by any network element nor connected to VNET
- DNSServiceIP used by kube-dns  typically .10 in the ServiceCIDR range.
- DockerBridgeCidr used as the docker bridge IP address on nodes.  Default is typically used.

MAX PODS PER NODE for advanced networking is 30!!
#>

# Create a Kubernetes Cluster on the Container subnet with RBAC.
$Cluster="k8s-cluster"
$NodeSize="Standard_D3_v2"
$DockerBridgeCidr="172.17.0.1/16"
$ServiceCidr="10.2.0.0/24"
$DNSServiceIP="10.2.0.10"
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

# Create the RBAC Binding
az aks get-credentials --resource-group $ResourceGroup --name $Cluster --admin


```

Create the RBAC bindings necessary

```powershell
az aks get-credentials --resource-group $ResourceGroup --name $Cluster --admin
$USER=$(az account show --query user.name -otsv)

$yaml = @"
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: "$($USER)"
"@
$yaml | Out-file cluster-admins.yaml

kubectl create -f cluster-admins.yaml
az aks get-credentials --resource-group $ResourceGroup --name $Cluster
```
