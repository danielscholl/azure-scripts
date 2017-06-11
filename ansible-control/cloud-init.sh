#!/bin/sh
# Copyright (c) 2017, cloudcodeit.com
## This Script will install
# - Support for SMB 3.0 File Share Mounts
# - Ansible
# - Ansible Azure Module Support

# Update and Install Packages
apt-get -y update
apt-get -y install apt-transport-https libssl-dev libffi-dev python-dev build-essential python-pip ansible cifs-utils

# Install required Python Modules
pip install --upgrade pip
pip install azure==2.0.0rc5 msrestazure dnspython

echo "Cloud-Init Completed -- $(date -R)!"
