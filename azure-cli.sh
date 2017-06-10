#!/bin/sh

## This Script will install
# - Azure CLI 2.0

# Register the Azure Package Area
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | tee /etc/apt/sources.list.d/azure-cli.list
apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
apt-get -y update
apt-get -y install azure-cli
