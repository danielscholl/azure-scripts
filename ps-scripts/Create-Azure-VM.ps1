<# Copyright (c) 2017, cloudcodeit.com
.Synopsis
   Installs a Virtual Machine to an isolated Resource Group.
.DESCRIPTION
   This script will install a virtual machine, Storage, Network
   into its own resource group. To ensure uniqueness you must pass
   a unique string parameter.
.EXAMPLE
   ./Create-Azure-VM.ps1 <your_unique_string> <your_group> <your_vmname> <your_location>
#>

param([string]$Prefix = $(throw "Unique Parameter required."),
  [string]$ResourceGroupName = "533",
  [string]$_name = "vm",
  [string]$Location = "southcentralus")


## SET OS TYPE  LINUX/WINDOWS
$OS = "WINDOWS" 

If ($OS -eq "LINUX") {
  $Publisher = "Canonical"
  $Offer = "UbuntuServer"
  $SKU = "16.04-LTS"
  $Version = "latest"
  $PORT_NAME = "SSH"
  $PORT = 22
}
else {
  #MicrosoftWindowsServer:WindowsServer:2012-R2-Datacenter:4.127.20170510
  $Publisher = "MicrosoftWindowsServer"
  $Offer = "WindowsServer"
  $SKU = "2012-R2-Datacenter"
  $Version = "4.127.20170510"
  $PORT_NAME = "RDP"
  $PORT = 3389
}

## SETUP VARIABLES
$CommonName = $Prefix.ToLower() + $ResourceGroupName.ToLower()
## Storage
$StorageName = $CommonName + "storage"
$DiagnosticsName = $CommonName + "diagnostics"
$StorageType = "Standard_LRS"
## Compute
$AVSetName = $CommonName + "AVset"
$VMName = $CommonName + "-" + $_name
$VMSize = "Standard_A1"
$OSDiskName = $VMName + "-OSDisk"
## Network Security Group
$NetworkSecurityGroupName = $VMName + "-nsg"
## Network
$InterfaceName = $VMName + "-nic"
$PublicIPName = $VMName + "-ip"
$SubnetName = "Subnet"
$VNetName = $CommonName + "VNet"
$VNetAddressPrefix = "10.0.0.0/16"
$VNetSubnetAddressPrefix = "10.0.0.0/24"


# Login to Azure
Login-AzureRmAccount

# Resource Group
$ResourceGroup = New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location

# Storage
$StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName -Type $StorageType -Location $Location
$DiagnosticsAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $DiagnosticsName -Type $StorageType -Location $Location


# Network Security Group
$Rules = @()
$Rules += New-AzureRmNetworkSecurityRuleConfig -Name $PORT_NAME -Description "Allow Inbound Connection." -Access Allow -Direction Inbound -Priority 100 -Protocol Tcp -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange $PORT
$NSG = New-AzureRmNetworkSecurityGroup -Name $NetworkSecurityGroupName -ResourceGroupName $ResourceGroupName -Location $Location -SecurityRules $Rules

# Network
$Pip = New-AzureRmPublicIpAddress -Name $PublicIPName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic
$SubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $VNetSubnetAddressPrefix
$VNet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefix -Subnet $SubnetConfig
$Interface = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $Pip.Id

# Compute
$AVSet = New-AzureRmAvailabilitySet -Name $AVSetName -ResourceGroupName $ResourceGroupName -Location $Location

# Credential Collection
$Credential = Get-Credential

## Setup local VM Configuration
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetId $AVSet.Id

If ($OS -eq "LINUX") {
  $VirtualMachine = Set-AzureRmVMOperatingSystem -Linux -VM $VirtualMachine -ComputerName $VMName  -Credential $Credential
}
else {
  $VirtualMachine = Set-AzureRmVMOperatingSystem -Windows -VM $VirtualMachine -ComputerName $VMName  -Credential $Credential
}

$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface.Id
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName $Publisher -Offer $Offer -Skus $SKU -Version $Version


## Create the VM
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine
