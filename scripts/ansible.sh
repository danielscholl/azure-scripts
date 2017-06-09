#!/bin/sh
# Update Packages and install Dependencies

echo "From update.sh $(date -R)!" >> /var/log/custom-script.log

# Update
# sudo apt-get update -y
# echo "Completed apt-get update $(date -R)!" >> /var/log/debug.log

# Install Azure File Share Support
# sudo apt-get install -y libssl-dev libffi-dev python-dev build-essential python-pip ansible cifs-utils
# echo "Completed installing packages $(date -R)!" >> /var/log/debug.log

# Install Azure for Ansible support
# sudo pip install --upgrade pip
# sudo pip install azure==2.0.0rc5 msrestazure dnspython
# echo "Install Azure support for Ansible $(date -R)!" >> /var/log/debug.log

# Install Azure CLI
# echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | tee /etc/apt/sources.list.d/azure-cli.list
# apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
# apt-get install -y apt-transport-https
# apt-get update -y
# apt-get install -y azure-cli
# echo "Install Azure CLI $(date -R)!" >> /var/log/debug.log

#apt-get upgrade -y
echo "Completed.  The time is now $(date -R)!" >> /var/log/debug.log
