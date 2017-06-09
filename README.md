# Purpose

The purpose of this script is to create a secured Ansible Control Server that can be used to manage systems in Azure.

# Instructions

This script will run if you have the Azure CLI 2.0 installed.

```
curl -L https://aka.ms/InstallAzureCli | bash
```

To execute the script you must pass in a unique string (lowercase letters or numbers no special characters).

```
azure login
./install.sh <your_unique_string>
```
