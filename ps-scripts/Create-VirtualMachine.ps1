<# Copyright (c) 2017, cloudcodeit.com
.Synopsis
   Installs a Virtual Machine to an isolated Resource Group.
.DESCRIPTION
   This script will install a virtual machine, Storage, Network
   into its own resource group. To ensure uniqueness you must pass
   a unique string parameter.
.EXAMPLE
   ./Create-VirtualMachine.ps1 <your_unique_string> <location> <vmname>
#>

param([string]$unique = $(throw "Unique Parameter required."), 
  [string]$location = "southcentralus",
  [string]$name = "control",
  [string]$rgName = "$($unique)-$($name)")

#Global Variables
$image = "MicrosoftWindowsServer:WindowsServer:2012-R2-Datacenter:latest"
$vmSize = "Standard_A1"
# $date = Get-Date -format "yyyy-MM-dd-hh-mm-ss"


#Resource Group
New-AzureRmResourceGroup -Name $rgName `
  -Location $location

#Storage
$storageType = "Standard_LRS"
$storageName = "$($unique.ToString().ToLower())$($name.ToString().ToLower())storage"
$storageacc = New-AzureRmStorageAccount -Name $storageName `
  -ResourceGroupName $rgName `
  -Type $storageType `
  -Location $location

#Network
$vnetAddressPrefix = "10.0.0.0/16"
$vnetSubnetAddressPrefix = "10.0.0.0/24"

$publicIp = New-AzureRmPublicIpAddress -Name "$($name)PublicIP" `
  -ResourceGroupName $rgName `
  -Location $location `
  -AllocationMethod Dynamic

$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name "$($name)Subnet" `
  -AddressPrefix $vnetSubnetAddressPrefix

$vnet = New-AzureRmVirtualNetwork -Name "$($name)VNET" `
  -ResourceGroupName $rgName `
  -Location $location `
  -AddressPrefix $vnetAddressPrefix `
  -Subnet $subnetConfig

$nic = New-AzureRmNetworkInterface -Name "$($name)VMNic" `
  -ResourceGroupName $rgName `
  -Location $location `
  -SubnetId $vnet.Subnets[0].Id `
  -PublicIpAddressId $publicIp.Id


#Configure VM
# $osDiskName = $name + "osDisk"
$blobPath = "vhds/OsDisk.vhd"
$osDiskUri = $storageacc.PrimaryEndpoints.Blob.ToString() + $blobPath  #<-- Dependency On Storage Account
$publisher, $offer, $sku, $version = $image.Split("{:}")

$cred = Get-Credential -Message "Enter the admin username and password"

$vm = New-AzureRmVMConfig `
  -VMName $name `
  -VMSize $vmSize

$vm = Set-AzureRmVMOperatingSystem -VM $vm `
  -ComputerName $name `
  -Credential $cred `
  -Windows `
  -ProvisionVMAgent `
  -EnableAutoUpdate

$vm = Set-AzureRmVMSourceImage -VM $vm `
  -PublisherName $publisher `
  -Offer $offer `
  -Skus $sku `
  -Version $version

$vm = Add-AzureRmVMNetworkInterface -VM $vm `
  -Id $nic.Id

$vm = Set-AzureRmVMOSDisk -VM $vm `
  -Name "OsDisk" `
  -VhdUri $osDiskUri `
  -CreateOption fromImage

New-AzureRmVM -VM $vm `
  -ResourceGroupName $rgname `
  -Location $location 

Get-AzureRmVM -ResourceGroupName $rgName