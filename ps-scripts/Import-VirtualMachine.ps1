<# Copyright (c) 2017, cloudcodeit.com
.Synopsis
   Creates a Virtual Image from a on-prem vhd file
.DESCRIPTION
   This script will import a virtual machine
.EXAMPLE
   ./Import-VirtualMachine.ps1
#>

param([string]$Location = "eastus2",
  [string]$vhd = "Win10_Base.vhd",
  [string]$ResourceGroupName = "images",
  [string]$ContainerName = "vhds",
  [string]$StorageType = "Standard_LRS",
  [string]$VhdPath = "C:\Users\Public\Documents\Hyper-V\Virtual Hard Disks\" + $vhd)

function Get-UniqueString ([string]$id, $length=13)
{
    $hashArray = (new-object System.Security.Cryptography.SHA512Managed).ComputeHash($id.ToCharArray())
    -join ($hashArray[1..$length] | ForEach-Object { [char]($_ % 26 + [byte][char]'a') })
}

# Create a Resource Group
Get-AzureRmResourceGroup -Name $ResourceGroupName -ev notPresent -ea 0 | Out-null
if ($notPresent) {
  Write-Warning -Message "Creating Resource Group $ResourceGroupName..."
  New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
}

$Unique=$(Get-UniqueString -id $(Get-AzureRmResourceGroup -Name $ResourceGroupName))
$StorageName = "$($unique.ToString().ToLower())storage"

# Creating a Storage Account
$StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName
if (!$StorageAccount) {
  Write-Warning -Message "Storage Container $ContainerName not found. Creating the Storage Account $StorageName"
  $StorageAccount = New-AzureRmStorageAccount -Name $StorageName -ResourceGroupName $ResourceGroupName -Location $location -SkuName $StorageType -Kind "Storage" 
}


# Creating a Container
$Access = "Off"
$Keys = Get-AzureRmStorageAccountKey -Name $StorageAccount.StorageAccountName -ResourceGroupName $ResourceGroupName
$StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccount.StorageAccountName -StorageAccountKey $Keys[0].Value
$Container = Get-AzureStorageContainer -Name $ContainerName -Context $StorageContext -ErrorAction SilentlyContinue
if (!$Container) {
  Write-Warning -Message "Storage Container $ContainerName not found. Creating the Container $ContainerName"
  New-AzureStorageContainer -Name $ContainerName -Context $StorageContext -Permission $Access
}


# Uploading a VHD
$Destination = ('https://' + $StorageName + '.blob.core.windows.net/' + $ContainerName + '/' + $Vhd)
$Blob = Get-AzureStorageBlob -Container $ContainerName -Context $StorageContext  -Blob $Vhd
if (!$Blob) {
  Write-Warning -Message "Storage Blob $Vhd not found. Uploading the VHD $Vhd ...."
  Add-AzureRmVhd -ResourceGroupName $ResourceGroupName -Destination $Destination -LocalFilePath $VhdPath -NumberOfUploaderThreads 4  -Verbose
}


# Create a managed image from the uploaded VHD
$ImageName = $Vhd.TrimEnd('.vhd')
$Image = Get-AzureRmImage -ImageName $ImageName -ResourceGroupName $ResourceGroupName
if (!$Image) {
  Write-Warning -Message "Image $Image not found. Creating the Image $ImageName ...."
  $ImageConfig = New-AzureRmImageConfig -Location $Location
  $ImageConfig = Set-AzureRmImageOsDisk -Image $ImageConfig -OsType Windows -OsState Generalized -BlobUri $Destination
  New-AzureRmImage -ImageName $imageName -ResourceGroupName $ResourceGroupName -Image $imageConfig
}
