
# Instructions

__Create a Resource Group__
This resource group will be used to hold all our resources

>NOTE: Assumes CLI Version = azure-cli (2.0.43)  ** Required RBAC changes

```powershell
$ResourceGroup="k8s"
$Location="eastus"

# Create a resource group.
az group create `
  --name $ResourceGroup `
  --location $Location

# Get Unique Resource Group ID
function Get-UniqueString ([string]$id, $length=13)
{
    $hashArray = (new-object System.Security.Cryptography.SHA512Managed).ComputeHash($id.ToCharArray())
    -join ($hashArray[1..$length] | ForEach-Object { [char]($_ % 26 + [byte][char]'a') })
}
$Unique=$(Get-UniqueString -id $(az group show --name $ResourceGroup --query id -otsv))
```


__Create a Service Principal__
This Service Principal is required to allow Clusters to access the container registry.

```powershell
$PrincipalName = "AKS-$Unique"
$PrincipalSecret = $(az ad sp create-for-rbac --skip-assignment --name $PrincipalName --query password -otsv)
$PrincipalId = $(az ad sp list --display-name $PrincipalName --query [].appId -otsv)
```


__Create a Container Registry__
Create a Container Registry to host images for the cluster and allow Service Principal Access.

```powershell
$Registry="registry$Unique"

# Create the Registry
$RegistryServer = $(az acr create --resource-group $ResourceGroup --name $Registry --sku Basic --query loginServer -otsv)

# Allow Service Principal Read Access to the Registry
## LOGGED IN USER MUST HAVE OWNER RIGHTS ON THE SUBSCRIPTION TO DO THIS
$RegistryId = $(az acr show --name $Registry --resource-group $ResourceGroup --query "id" --output tsv)
az role assignment create --assignee $PrincipalId  --scope $RegistryId --role Reader

# Login to the Registry
az acr login --name $Registry
```


__Create an Application Image__
Download an application build the docker images and push it to the private registry and deploy a k8s manifest.

```powershell
# Clone a Sample Application
git clone https://github.com/Azure-Samples/azure-voting-app-redis.git src

# Create a Compose File
@"
version: '3'
services:
  azure-vote-back:
    image: redis
    container_name: azure-vote-back
    ports:
        - "6379:6379"

  azure-vote-front:
    build: ./src/azure-vote
    image: $RegistryServer/azure-vote-front
    container_name: azure-vote-front
    environment:
      REDIS: azure-vote-back
    ports:
        - "8080:80"
"@ | Out-file docker-compose.yaml

# Create the application image and push it to the registry
docker-compose build
docker-compose push

# Create a Kubernetes Deployment Manifest
@"
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: azure-vote-back
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: azure-vote-back
    spec:
      containers:
      - name: azure-vote-back
        image: redis
        ports:
        - containerPort: 6379
          name: redis
---
apiVersion: v1
kind: Service
metadata:
  name: azure-vote-back
spec:
  ports:
  - port: 6379
  selector:
    app: azure-vote-back
---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: azure-vote-front
spec:
  replicas: 1
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  minReadySeconds: 5 
  template:
    metadata:
      labels:
        app: azure-vote-front
    spec:
      containers:
      - name: azure-vote-front
        image: $RegistryServer/azure-vote-front
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 250m
          limits:
            cpu: 500m
        env:
        - name: REDIS
          value: "azure-vote-back"
---
apiVersion: v1
kind: Service
metadata:
  name: azure-vote-front
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: azure-vote-front
"@ | Out-file deployment.yaml
```


__Option A: Create a Basic Kubernetes Cluster__
Create a bare bones Kubernetes Cluster and deploy the application to it.

>Note: A Basic Kubernetes Cluster now has RBAC on by default.
>Burstable Machines can be used to save money for non-prod clusters.  [Documentation](https://azure.microsoft.com/en-us/blog/introducing-burstable-vm-support-in-aks/)

```powershell
$Cluster="k8s-cluster"
$NodeSize="Standard_B2S"

# Create the Registry
az aks create --name $Cluster `
    --resource-group $ResourceGroup `
    --location $Location `
    --generate-ssh-keys `
    --node-vm-size $NodeSize `
    --node-count 1 `
    --service-principal $PrincipalId `
    --client-secret $PrincipalSecret

# Pull down the kubeconfig Credentials
az aks get-credentials --resource-group $ResourceGroup --name $Cluster

# Validate Communication to the Cluster
kubectl get nodes  
kubectl get pods --all-namespaces   

# Deploy the application to the cluster
kubectl apply -f deployment.yaml
kubectl get service azure-vote-front --watch  # Wait for the External IP to come live


# Give the k8s dashboard Admin Rights by expanding the service account authorization
kubectl create clusterrolebinding kubernetes-dashboard `
    -n default `
    --clusterrole=cluster-admin `
    --serviceaccount=kube-system:kubernetes-dashboard

az aks browse --resource-group $ResourceGroup --name $Cluster  # Open the dashboard


# Alternately Enable Token Login Access for Dashboard **More Secure  (No Access via Dashboard to Pods)

# ---------------------------------- #
#  THIS IS NOT WORKING RIGHT NOW!!!  #
# ---------------------------------- #

# Create a Dashboard Service Account
kubectl create serviceaccount dashboard -n default
kubectl create clusterrolebinding dashboard-admin -n default --clusterrole=cluster-admin --serviceaccount=default:dashboard

# Startup the Dashboard Proxy and Browser
Start-Process kubectl proxy
Start http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/login


# Get a Login Token and Copy it to clipboard
$data = kubectl get secret $(kubectl get serviceaccount dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}"
[System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($data)) | clip
```


__Option B: Create a Basic Kubernetes Cluster with AAD RBAC__

Create a .env.ps1 file with the following settings as defined in the Tutorial Document

[https://docs.microsoft.com/en-us/azure/aks/aad-integration](https://docs.microsoft.com/en-us/azure/aks/aad-integration)


>Important things to note:

1. Follow the instructions "VERY" carefully.
2. Ensure you select Grant Permissions on both the Server Principal and the Client Principal
3. Only "Member" users will be supported and not "Guest" users

Track the Open Issue.
[RBAC AAD access error](https://github.com/Azure/AKS/issues/478)


```powershell
## Sample Environment File
$Env:AZURE_AKSAADServerId = ""                  # Desired Service Principal Server Id
$Env:AZURE_AKSAADServerSecret = ""              # Desired Service Princiapl Server Key
$Env:AZURE_AKSAADClientId = ""                  # Desired Service Princiapl Client Id
$Env:AZURE_TENANT = ""                          # Desired Tenant Id
```


Deploy and validate the Kubernetes Cluster with RBAC

```powershell
$Cluster="k8s-cluster-aad"
$NodeSize="Standard_B2s"

# Source the Service Principal Environment File
. ./.env.ps1

# Create the Cluster
az aks create --name $Cluster `
    --resource-group $ResourceGroup `
    --location $Location `
    --generate-ssh-keys `
    --node-vm-size $NodeSize `
    --node-count 1 `
    --service-principal $PrincipalId `
    --client-secret $PrincipalSecret `
    --aad-server-app-id $env:AZURE_AKSAADServerId  `
    --aad-server-app-secret $env:AZURE_AKSAADServerSecret  `
    --aad-client-app-id $env:AZURE_AKSAADClientId  `
    --aad-tenant-id $env:AZURE_TENANT 

# Pull the cluster admin context
az aks get-credentials --resource-group $ResourceGroup --name $Cluster --admin

<#
- RBAC is in Preview and it seems not all things are synced up yet and completed.
- Standard way of browsing to the dashboard doesn't work.  Must use a Token Login
- The token login mechanism bypasses the RBAC as it isn't using the clusterrolebinding created above :-(
#>

# Give the k8s dashboard Admin Rights by expanding the service account authorization
kubectl create clusterrolebinding kubernetes-dashboard `
    -n default `
    --clusterrole=cluster-admin `
    --serviceaccount=kube-system:kubernetes-dashboard

# AD User Assignment
kubectl create -f aduser-cluster-admin.yaml
kubectl create -f cluster-admin-group.yaml


# Pull the cluster context
az aks get-credentials --resource-group $ResourceGroup --name $Cluster

# Excercise commands
kubectl get pods --all-namespaces   # Allowed for the user
kubectl get nodes                   # Rejected by the user

# Deploy the application to the cluster
kubectl apply -f deployment.yaml
kubectl get service azure-vote-front --watch  # Wait for the External IP to come live

# Open the dashboard
az aks browse --resource-group $ResourceGroup --name $Cluster
```




__Create a Virtual Network that can be used with a Kubernetes Cluster__

```powershell
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

# Allow Service Principal Owner Access to the Network
$SubnetId=$(az network vnet subnet show --resource-group $ResourceGroup --vnet-name $VNet --name ContainerTier --query id -otsv)
az role assignment create --assignee $PrincipalId  --scope $SubnetId --role Contributor
```


__Option C: Create an Advanced Network Kubernetes Cluster__
>Note: Requires the Virutal Network

Create a  Kubernetes Cluster integrated with a custom vnet and deploy the application to it.


```powershell
$NodeSize="Standard_D3_v2"
$Cluster="k8s-cluster-network"
$DockerBridgeCidr="172.17.0.1/16"
$ServiceCidr="10.3.0.0/24"
$DNSServiceIP="10.3.0.10"

# Create the Cluster
az aks create --name $Cluster `
    --resource-group $ResourceGroup `
    --location $Location `
    --generate-ssh-keys `
    --node-vm-size $NodeSize `
    --node-count 1 `
    --service-principal $PrincipalId `
    --client-secret $PrincipalSecret `
    --disable-rbac `
    --network-plugin azure `
    --docker-bridge-address $DockerBridgeCidr `
    --service-cidr $ServiceCidr `
    --dns-service-ip $DNSServiceIP `
    --vnet-subnet-id $SubnetId `
    --enable-addons http_application_routing

# Pull the cluster admin context
az aks get-credentials --resource-group $ResourceGroup --name $Cluster --admin

# Deploy an internal Load Balancer
@"
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: azure-vote-back
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: azure-vote-back
    spec:
      containers:
      - name: azure-vote-back
        image: redis
        ports:
        - containerPort: 6379
          name: redis
---
apiVersion: v1
kind: Service
metadata:
  name: azure-vote-back
spec:
  ports:
  - port: 6379
  selector:
    app: azure-vote-back
---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: azure-vote-front
spec:
  replicas: 1
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  minReadySeconds: 5 
  template:
    metadata:
      labels:
        app: azure-vote-front
    spec:
      containers:
      - name: azure-vote-front
        image: registrymmpknpadipove.azurecr.io/azure-vote-front
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 250m
          limits:
            cpu: 500m
        env:
        - name: REDIS
          value: "azure-vote-back"
---
apiVersion: v1
kind: Service
metadata:
  name: azure-vote-front
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: azure-vote-front
"@ | Out-file deployment.yaml

# Deploy it to the cluster
kubectl apply -f deployment.yaml
kubectl get service azure-vote-front --watch  # Wait for the External IP to come live

az aks browse --resource-group $ResourceGroup --name $Cluster  # Open the dashboard
```
