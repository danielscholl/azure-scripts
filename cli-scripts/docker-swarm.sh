#!/usr/bin/env bash
# Copyright (c) 2017, cloudcodeit.com
#
#  Purpose: Create a App Service Web App
#  Usage:
#    docker-swarm.sh <unique> <location>


###############################
## SCRIPT SETUP              ##
###############################

if [ -f ~/.azure/.env ]; then source ~/.azure/.env; fi

if [ ! -z $1 ]; then UNIQUE=$1; fi
if [ ! -z $2 ]; then LOCATION=$2; else LOCATION=southcentralus; fi


RESOURCE_GROUP=${UNIQUE}-swarm
IMG=UbuntuLTS
SIZE=Standard_DS1_v2
VNET=${RESOURCE_GROUP}-vnet
ADDRESS_RANGE=10.10.0.0/16
SUBNET=Nodes
SUBNET_RANGE=10.10.0.0/24
LB=${RESOURCE_GROUP}-lb
NSG=${RESOURCE_GROUP}-nsg
IP=${LB}-ip
AV=${RESOURCE_GROUP}-av



az group create -n ${RESOURCE_GROUP} --location ${LOCATION}
az network vnet create -g ${RESOURCE_GROUP} -n ${VNET} --address-prefix ${ADDRESS_RANGE} --subnet-name ${SUBNET} --subnet-prefix ${SUBNET_RANGE}
az network nsg create -g ${RESOURCE_GROUP} -n ${NSG}
az network nsg rule create -g ${RESOURCE_GROUP} --nsg-name ${NSG} --name SSH --protocol tcp --direction inbound --priority 1000 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 --access allow
az network lb create -g ${RESOURCE_GROUP} -n ${LB} --location ${LOCATION} --frontend-ip-name ${LB}-fe --backend-pool-name ${LB}-be --public-ip-address ${IP} --public-ip-address-allocation Static
az vm availability-set create -g ${RESOURCE_GROUP} -n ${AV} --location ${LOCATION} --platform-update-domain-count 5 --platform-fault-domain-count 2



# Virtual Machine
VM=node1
NIC=$VM-NIC
IP=$VM-IP
PORT=10122

az network lb inbound-nat-rule create -g ${RESOURCE_GROUP} -n ssh-${VM} --protocol Tcp --lb-name ${LB} --backend-port 22 --frontend-port ${PORT} --frontend-ip-name ${LB}-fe
az network nic create -g ${RESOURCE_GROUP} -n ${NIC} --vnet-name ${VNET} --subnet ${SUBNET}  --lb-name ${LB} --lb-address-pools ${LB}-be --lb-inbound-nat-rules ssh-${VM}
az vm create -g ${RESOURCE_GROUP} -n ${VM} --generate-ssh-keys --location ${LOCATION} --image ${IMG} --size ${SIZE} --nics ${NIC} --availability-set ${AV}
az vm extension set --resource-group ${RESOURCE_GROUP} --vm-name ${VM} --name DockerExtension --publisher Microsoft.Azure.Extensions --version 1.1 --settings '{"docker": {"port": "2375"}}'



# Virtual Machine
VM=node2
NIC=$VM-NIC
PORT=10222

az network lb inbound-nat-rule create -g ${RESOURCE_GROUP} -n ssh-${VM} --protocol Tcp --lb-name ${LB} --backend-port 22 --frontend-port ${PORT} --frontend-ip-name ${LB}-fe
az network nic create -g ${RESOURCE_GROUP} -n ${NIC} --vnet-name ${VNET} --subnet ${SUBNET} --lb-name ${LB} --lb-address-pools ${LB}-be --lb-inbound-nat-rules ssh-${VM}
az vm create -g ${RESOURCE_GROUP} -n ${VM} --generate-ssh-keys --location ${LOCATION} --image ${IMG} --size ${SIZE} --nics ${NIC} --availability-set ${AV}
az vm extension set --resource-group ${RESOURCE_GROUP} --vm-name ${VM} --name DockerExtension --publisher Microsoft.Azure.Extensions --version 1.1 --settings '{"docker": {"port": "2375"}}'


# Load Balance Rule
PROBE=http-probe
RULE=http-rule
az network lb probe create -g ${RESOURCE_GROUP} -n ${PROBE} --lb-name ${LB} --protocol http --port 80 --path / --interval 15 --threshold 4
az network lb rule create -g ${RESOURCE_GROUP} -n ${RULE} --lb-name ${LB} --probe-name ${PROBE} --protocol Tcp --frontend-ip-name ${LB}-fe --frontend-port 80 --backend-pool-name ${LB}-be --backend-port 80
az network nsg rule create -g ${RESOURCE_GROUP} --nsg-name ${NSG} --name http --protocol tcp --direction inbound --priority 1010 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 80 --access allow


# Sample Application
#VMIP=$(az network public-ip show -g ${RESOURCE_GROUP} --name ${LB}-ip --query ipAddress -otsv)
#ssh ${VMIP} -p ${PORT} 'docker run -d -p 80:80 tutum/hello-world'
#ssh ${VMIP} -p ${PORT} 'docker run -d -p 80:80 tutum/hello-world'
