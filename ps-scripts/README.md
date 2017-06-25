# Helpful PowerShell Snipperts

### General Items

```powershell
# Get AzureRM Modules installed
Get-Module AzureRm.* -list

# Get AzureRM Commands in a Module
Get-Command -Module AzureRm.Profile
Get-Command -Module AzureRm.Storage

# Get Help about a Command
Get-Help Login-AzureRmAccount

# Login to Azure
Login-AzureRmAccount

# List Subscriptions
Get-AzureRmSubscription

# Select Subscription Context
$Subscription = 'MSDN'
Set-AzureRmContext -SubscriptionName $Subscription
```

### Resource Groups

```powershell
# List Resource Groups
Get-AzureRmResourceGroup

# List Locations
Get-AzureRmLocation | Select-Object Location

# Create Resource Group
$ResourceGroup = '533'
$Location = 'westus'
New-AzureRmResourceGroup -Name $ResourceGroup `
  -Location $Location

# List all Resources in a Group
Find-AzureRmResource -ResourceGroupNameContains $ResourceGroup | Select-Object Name, Kind
```

### Virtual Networks

```powershell
$VNetName  = 'DefaultVNet'
$VNetPrefix = '10.10.0.0/16'
$GatewayPrefix = '192.168.200.0/29'

$Subnet1Name = 'Subnet'
$Subnet1Prefix = '10.10.1.0/24'

# Create Subnets
$GatewaySub = New-AzureRmVirtualNetworkSubnetConfig -Name 'GatewaySubnet' `
    -AddressPrefix $GatewayPrefix
$Subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $Subnet1Name `
    -AddressPrefix $Subnet1Prefix


# Create a Virtual Network
$VNet = New-AzureRmVirtualNetwork -Name $VNetName `
    -ResourceGroupName $ResourceGroup `
    -Location $Location `
    -AddressPrefix $VNetPrefix,$GatewayPrefix `
    -Subnet $Subnet,$GatewaySub


# Get a Virtual Network and Subnet
$VNet = Get-AzureRmVirtualNetwork -Name $VNetName `
    -ResourceGroupName $ResourceGroup
$GatewaySub = Get-AzureRmVirtualNetworkSubnetConfig -Name 'GatewaySubnet' `
    -VirtualNetwork $VNet


# ------------------------------------
# Configure a Point to Site Connection
# ------------------------------------
$FullPath = "C:\Certs\P2SRootCert.cer"
$CertName = 'P2SRootCert.cer'

# Create a self-signed root certificate
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject "CN=P2SRootCert" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

# NOTE: Manually export to C:\Certs\P2SRootCert.cer

# Get Certificate for Import
$Cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2($FullPath)
$CertBase64 = [system.convert]::ToBase64String($Cert.RawData)
$P2SiteRootCert = New-AzureRmVpnClientRootCertificate -Name $CertName -PublicCertData $CertBase64


# Create a Public IP Address for the VPN Gateway
$GatewayIPName = 'gw-ip'
$Ip = New-AzureRmPublicIpAddress -Name $GatewayIPName `
    -ResourceGroupName $ResourceGroup `
    -Location $Location `
    -AllocationMethod Dynamic
$IpConf = New-AzureRmVirtualNetworkGatewayIpConfig -Name 'GatewaySubnet' `
    -Subnet $GatewaySub `
    -PublicIpAddress $Ip


# Create a Virtual Network Gateway
$VPNClientAddressPool = "172.16.201.0/28"
New-AzureRmVirtualNetworkGateway -Name $GatewayName `
    -ResourceGroupName $ResourceGroup `
    -Location $Location `
    -IpConfigurations $IpConf `
    -GatewayType Vpn `
    -VpnType RouteBased `
    -EnableBgp $false `
    -GatewaySku Basic `
    -VpnClientAddressPool $VPNClientAddressPool `
    -VpnClientRootCertificates $P2SiteRootCert


# Delete a Virtual Network
Remove-AzureRmVirtualNetwork -Name $VNetName `
    -ResourceGroupName $ResourceGroup
````

### Storage Accounts and Containers

```powershell
# Create a Storage Account
$StorageAccount = 'msdnstoragearm01'
New-AzureRmStorageAccount -Name $StorageAccount `
  -ResourceGroupName $ResourceGroup `
  -Location $Location `
  -SkuName 'Standard_LRS' `
  -Kind 'Storage'

# Set Storage Account Context
Set-AzureRmCurrentStorageAccount -Name $StorageAccount `
  -ResourceGroupName $ResourceGroup

# Create Storage Container using Current Storage Account
$Source='source'
New-AzureStorageContainer -Name $Source `
  -Permission Off

# List Storage Containers

# Option 2 - Containers with Storage Context
$Key = (Get-AzureRmStorageAccountKey -Name $StorageAccount `
  -ResourceGroupName $ResourceGroup).Value[0]
$Context = New-AzureStorageContext `
  -StorageAccountName $StorageAccount `
  -StorageAccountKey $Key

# Create Storage Container using Storage Context
$Destination='destination'
New-AzureStorageContainer -Name $Destination `
  -Context $storageAccountContext `
  -Permission Off
```

### Working with Resources

```powershell
# Tag a Resource
$Tag = @{ Environment="Training" } #Array Name/Value
Set-AzureRmResource `
  -ResourceGroupName $ResourceGroup `
  -ResourceName $StorageAccount `
  -ResourceType 'Microsoft.Storage/storageAccounts'
  -Tag $Tag

# List all Resources with a Tag
Find-AzureRmResource -TagName 'Environment' -TagValue 'Training'
```

### Copy a Blob

```powershell
$Blob='file.txt'
$BlobCopy = Start-AzureStorageBlobCopy `
    -Context $Context `
    -SrcContainer $Source `
    -SrcBlob $Blob `
    -DestContainer $Destination

### Retrieve the current status of the copy operation ###
$status = $BlobCopy | Get-AzureStorageBlobCopyState
```

#### Copy a Blob using AZCopy

```
AzCopy /Source:https://myaccount.blob.core.windows.net/source /Dest:https://myaccount.blob.core.windows.net/destination /SourceKey:Act1_Key /DestKey:Act2_key /Pattern:file.txt
```

## Regenerate Storage Keys

```powershell
Get-AzureRmStorageAccountKey -Name $StorageAccountName `
  -ResourceGroupName $ResourceGroup

New-AzureRmStorageAccountKey -Name $StorageAccountName `
  -ResourceGroupName $ResourceGroup  `
  -KeyName 'key1'
```


## Working with File Shares

```powershell
# Create a File Share
$Share = New-AzureStorageShare 'myShare'

# Create a Directory
New-AzureStorageDirectory `
  -Share $Share `
  -Path 'appLogs'

# Upload a File
Set-AzureStorageFileContent `
  -Share $Share `
  -Path 'appLogs' `
  -Source 'file.txt'

# Directory Listing
Get-AzureStorageFile `
  -Share $share `
  -Path 'appLogs' | Get-AzureStorageFile

# Download files from azure storage file service
Get-AzureStorageFileContent `
  -Share $share `
  -Path 'appLogs/file.txt'

# persist your storage account credentials
(Get-AzureStorageKey -StorageAccountName $StorageAccountName).Primary
cmdkey /add:<your_account>.file.core.windows.net /U:<your_account> /pass:<your_key>

net use t: \\<your_account>.file.core.windows.net\logs

net use t: \\<your_account>.file.core.windows.net\logs /u:<your_account

net use t: \\<your_account>.file.core.windows.net\admintools /u:<your_account>  <your_key>

```


### Working with Sass Tokens

```powershell
# Get Storage Account Context
$Key = (Get-AzureRmStorageAccountKey -Name $StorageAccountName `
          -ResourceGroupName $ResourceGroup).Value[0]
$Context = New-AzureStorageContext `
  -StorageAccountName $StorageAccountName `
  -StorageAccountKey $Key


# Create a Stored Access policy (Container)
New-AzureStorageContainerStoredAccessPolicy -Context $Context `
   -Container 'source' `
   -Policy 'myPolicy' `
   -Permission rwd `
   -StartTime (Get-Date) `
   -ExpiryTime (Get-Date).AddHours(1)

# Create a SAS Token from a Policy (Container)
  New-AzureStorageContainerSASToken -Name 'myToken' `
  -Policy "myPolicy"
  -FullUri

# Create an Adhoc SAS Token (Blob)
New-AzureStorageBlobSASToken -Context $Context `
  -Container 'source' `
  -Blob 'file.txt' `
  -Permission rwd `
  -StartTime (Get-Date) `
  -ExpiryTime (Get-Date).AddHours(1) `
  -FullUri
```

### Misc Commands

#### DSC File to install IIS

```powershell
configuration IISInstall
{
    node "localhost"
    {
        WindowsFeature IIS
        {
            Ensure = "Present"
            Name = "Web-Server"
        }
    }
}
```

** Install Via Portal **

1. Configuration Module or Script
  > ie: dsc.zip

2. Module-qualified Name of Configuration
  > ie:  dsc_iis.ps1\Main

3. Version
  > ie:  2.21

#### Run a DSC Configuration on a Windows Server

1. Create a Powershell DSC File

```powershell
configuration IISInstall
{
    node "localhost"
    {
        WindowsFeature IIS
        {
            Ensure = "Present"
            Name = "Web-Server"
        }
    }
}
```

2. Upload the DSC to Storage and Execute on the Server

```powershell
$ResourceGroup = "ds-533"
$Name = "vm1"
$Storage = "ds533disks"

#Publish the configuration script into user storage
Publish-AzureRmVMDscConfiguration -ConfigurationPath .\iisinstall.ps1 `
    -ResourceGroupName $ResourceGroup `
    -StorageAccountName $Storage `
    -force

#Set the VM to run the DSC configuration
Set-AzureRmVmDscExtension -Version 2.21 `
    -ResourceGroupName $ResourceGroup `
    -VMName $Name `
    -ArchiveStorageAccountName $Storage `
    -ArchiveBlobName iisinstall.ps1.zip `
    -AutoUpdate:$true `
    -ConfigurationName "IISInstall"
```


#### Resize a Virtual Machine

```
$ResourceGroupName = "Production"
$VMName = "Prod1"
$NewVMSize = "Standard_A2"

$vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName
$vm.HardwareProfile.vmSize = $NewVMSize
Update-AzureRmVM -ResourceGroupName $ResourceGroupName -VM $vm
```

#### Add a Disk to a Windows Virtual Machine

```powershell
$ResourceGroup = "ds533"
$Name = "VM1"
$VM = Get-AzureRmVM -ResourceGroupName $ResourceGroup -Name $Name

$Storage = "ds533disks"
$DiskName = "vm1data.vhd"
Add-AzureRmVMDataDisk -VM $VM -Name "data" `
    -VhdUri "https://$Storage.blob.core.windows.net/vhds/$DiskName" `
    -CreateOption Empty `
    -DiskSizeinGB 1 `
    -Lun 2

Update-AzureRmVM -ResourceGroupName $ResourceGroup -VM $VM
```

#### Lock a Resource

```powershell
$ResourceGroup = "ds-533"
$Storage = "ds533disks"

New-AzureRmResourceLock -LockName "DoNotDelete" -LockLevel CanNotDelete `
  -ResourceGroupName $ResourceGroup `
  -ResourceName $Storage `
  -ResourceType microsoft.storage/storageaccounts
```
>Note: Must run as Administrator



#### Install the BGInfo Extension

```powershell
Set-AzureRmVMBginfoExtension -resourcegroup "proddata" -vmname "web2"
```

#### Manually install IIS as a Windows Feature from within a server

```powershell
Install-WindowsFeature -Name "Web-Server" -IncludeAllSubFeature -IncludeManagementTools
```

#### Create a VMSS

```powershell
 Get-AzureLocation | Sort Name | Select Name
 $locName = "location name from the list, such as Central US"
 $rgName = "resource group name"
 New-AzureRmResourceGroup -Name $rgName -Location $locName

 $saName = "storage account name"
 Get-AzureRmStorageAccountNameAvailability $saName
 New-AzureRmStorageAccount -Name $saName -ResourceGroupName $rgName –Type $saType -Location $locName

 $subnetName = "subnet name"
 $subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24
 $netName = "virtual network name"
 $vnet = New-AzureRmVirtualNetwork -Name $netName -ResourceGroupName $rgName -Location $locName -AddressPrefix 10.0.0.0/16 -Subnet $subnet

 $ipName = "IP configuration name"
 $ipConfig = New-AzureRmVmssIpConfig -Name $ipName -LoadBalancerBackendAddressPoolsId $null -SubnetId $vnet.Subnets[0].Id

 $vmssConfig = "Scale set configuration name"
 Add-AzureRmVmssNetworkInterfaceConfiguration -VirtualMachineScaleSet $vmss -Name $vmssConfig -Primary $true -IPConfiguration $ipConfig
 $computerName = "computer name prefix"
 $adminName = "administrator account name"
 $adminPassword = "password for administrator accounts"
 Set-AzureRmVmssOsProfile -VirtualMachineScaleSet $vmss -ComputerNamePrefix $computerName -AdminUsername $adminName -AdminPassword $adminPassword

 $storageProfile = "storage profile name"
 $imagePublisher = "MicrosoftWindowsServer"
 $imageOffer = "WindowsServer"
 $imageSku = "2012-R2-Datacenter"
 $vhdContainers = @("https://myst1.blob.core.windows.net/vhds","https://myst2.blob.core.windows.net/vhds","https://myst3.blob.core.windows.net/vhds")
 Set-AzureRmVmssStorageProfile -VirtualMachineScaleSet $vmss -ImageReferencePublisher $imagePublisher -ImageReferenceOffer $imageOffer -ImageReferenceSku $imageSku -ImageReferenceVersion "latest" -Name $storageProfile -VhdContainer $vhdContainers -OsDiskCreateOption "FromImage" -OsDiskCaching "None"

 $vmssName = "scale set name"
 New-AzureRmVmss -ResourceGroupName $rgName -Name $vmssName -VirtualMachineScaleSet $vmss
```

