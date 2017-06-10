#!/usr/bin/env bash
# Copyright (c) 2017, cloudcodeit.com
#
#  Purpose: Install PowerShell Preview and XPLAT CLI
#  Usage:
#    osxinstall.sh

#DotNet Core 6.1.0-/1
wget https://download.microsoft.com/download/1/4/1/141760B3-805B-4583-B17C-8C5BC5A876AB/Installers/dotnet-dev-osx-x64.1.0.1.pkg
sudo installer -pkg dotnet-dev-osx-x64.1.0.0-preview2-1-003177.pkg -target /

#PowerShell Core 6.14
wget https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.14/powershell-6.0.0-alpha.14.pkg
sudo installer -pkg powershell-6.0.0-alpha.14.pkg -target /

#Azure RM NetCore Preview Module Install
powershell Install-Module AzureRM.NetCore.Preview
powershell Import-Module AzureRM.NetCore.Preview
if [[ $? -eq 0 ]]
    then
        echo "Successfully installed PowerShell Core with AzureRM NetCore Preview Module."
    else
        echo "PowerShell Core with AzureRM NetCore Preview Module did not install successfully." >&2
fi

#Install Azure CLI 1.0
#Address https://azure.microsoft.com/en-us/documentation/articles/xplat-cli-install/

read -p "Do you want to install Azure CLI? y/n" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    sudo npm install -g azure-cli
    if [[ $? -eq 0 ]]
    then
        echo "Successfully installed Azure CLI"
    else
        echo "Azure CLI not installed successfully." >&2
fi
else
    echo "You chose not to install Azure CLI. Exiting now."
fi
