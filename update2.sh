#!/bin/sh

# Update Packages and install Dependencies
apt-get -y update
# apt-get -y upgrade

# Install Azure File Share Support
apt-get -y install cifs-utils

# Install the Azure CLI
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | tee /etc/apt/sources.list.d/azure-cli.list
apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
apt-get install apt-transport-https
apt-get update && sudo apt-get install azure-cli


# Install Ansible
apt-get -y install libssl-dev libffi-dev python-dev build-essential python-pip ansible

# Install Azure for Ansible support
pip install --upgrade pip
pip install azure==2.0.0rc5 msrestazure dnspython

# Mount the File Share
#mkdir -p /mnt/scripts
#sudo mount -t cifs //$1.file.core.windows.net/scripts /scripts -o vers=3.0,username=$2,password=$3,dir_mode=0777,file_mode=0777

# Install the Azure CLI
curl -L https://aka.ms/InstallAzureCli | bash

echo 'All Finished' > /var/log/debug.log

# sudo apt-get update
# sudo apt-get upgrade
# sudo apt-get dist-upgrade
# sudo apt-get install -y libssl-dev libffi-dev python-dev build-essential python-pip
# curl -L https://aka.ms/InstallAzureCli | bash
