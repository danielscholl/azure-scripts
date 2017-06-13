break
# #############################################################################
# Configure VM Networking
# NAME: PS-70533-VMs-MOD04.ps1
#
# AUTHOR:  Tim Warner
# DATE:  2016/04/01
# EMAIL: timothy-warner@pluralsight.com
#
# COMMENT:
#
# VERSION HISTORY
# 1.0 2016.04.01 Initial Version
# #############################################################################

# Press CTRL+M to expand/collapse regions

#region Connect to Azure

Add-AzureAccount

# Login to Azure (programmatically)
Get-AzurePublishSettingsFile
Import-AzurePublishSettingsFile -PublishSettingsFile '.\50dollar1-150dollar-50dollar2-3-28-2016-credentials.publishsettings'

# Choose your default subscription (I'm using mine here; adjust as needed)
Set-AzureSubscription -SubscriptionName '150dollar' -CurrentStorageAccountName '704psstorage'
Select-AzureSubscription -SubscriptionName '150dollar' -Default
Get-AzureSubscription -Default

#endregion

#region Create two-node ASM pod

$family = "Windows Server 2012 R2 Datacenter"

$image = Get-AzureVMImage | Where-Object { $_.ImageFamily -eq $family } | Sort-Object -Property PublishedDate -Descending | Select-Object -ExpandProperty ImageName -First 1

$vmname = "web1"

$vmsize = "Small"

$ip = 10.0.1.20

$vm1 = New-AzureVMConfig -Name $vmname -InstanceSize $vmsize -ImageName $image

$cred = Get-Credential -Message "Type the name and password of the local administrator account."

$vm1 | Add-AzureProvisioningConfig -Windows -AdminUsername $cred.Username -Password $cred.GetNetworkCredential().Password

$vm1 | Set-AzureSubnet -SubnetNames "Subnet-1"

$vm1 | Set-AzureStaticVNetIP '10.0.1.20'

#$vm1 | Add-AzureEndpoint -Name 'RDP' -Protocol tcp -PublicPort 33891 -LocalPort 3389

#$vm1 | Add-AzureEndpoint -Name 'WINRM' -Protocol tcp -PublicPort 59861 -LocalPort 5986

$disksize = 20
$disklabel = "DataDisk"
$lun = 0
$hcaching = "None"

$vm1 | Add-AzureDataDisk -CreateNew -DiskSizeInGB $disksize -DiskLabel $disklabel -LUN $lun -HostCaching $hcaching

$svcname = 'pscloudservice704'

$vnetname = 'psvnet'

New-AzureVM –ServiceName $svcname -VMs $vm1 -VNetName $vnetname

# DSC extension (assumes settings storage context and running Publish-AzureVMDSCConfiguration)
$vmDSC = Get-AzureVM -ServiceName $svcname -Name $vmname
Set-AzureVMDscExtension -VM $vmDSC -ConfigurationArchive AzureVMConfiguration.ps1.zip -ConfigurationName AzureVMConfiguration -Verbose -StorageContext $StorageContext -ContainerName $StorageContainer -Force -ConfigurationDataPath 'ConfigData.psd1' | Update-AzureVM

Start-Azurevm -Name 'dc1' -ServiceName 'pscloudservice704'
Start-AzureVM -Name 'mem1' -ServiceName 'pscloudservice704'

#endregion

#region Create a load-balanced set

Get-AzureVM -ServiceName $svcname -Name 'web1' | Add-AzureEndpoint -Name 'HTTP' -Protocol 'TCP' -PublicPort 80 -LocalPort 80 -LBSetName 'Web-Front-End2' -DefaultProbe | Update-AzureVM
Get-AzureVM -ServiceName $svcname -Name 'web2' | Add-AzureEndpoint -Name 'HTTP' -Protocol 'TCP' -PublicPort 80 -LocalPort 80 -LBSetName 'Web-Front-End2' -DefaultProbe    | Update-AzureVM
#endregion

#region Reserved IPs

# instance reserved IP (existing VM)
Get-AzureVM -ServiceName 'pscloudservice704' -Name 'web1' | Set-AzurePublicIP -PublicIPName ftpip | Update-AzureVM

# instance reserved IP (new VM)
New-AzureVMConfig -Name "FTPInstance" -InstanceSize Small -ImageName $images[50].ImageName | Add-AzureProvisioningConfig -Windows -AdminUsername xyz -Password abcd123! | Set-AzurePublicIP -PublicIPName "ftpip" | New-AzureVM -ServiceName "FTPinAzure" -Location "North Central US"

# cloud service reserved IP (new CS)
New-AzureReservedIP –ReservedIPName MyReservedIP –Location "Central US"
$image = Get-AzureVMImage|? {$_.ImageName -like "*RightImage-Windows-2012R2-x64*"}
New-AzureVMConfig -Name TestVM -InstanceSize Small -ImageName $image.ImageName `
  | Add-AzureProvisioningConfig -Windows -AdminUsername adminuser -Password MyP@ssw0rd!! `
  | New-AzureVM -ServiceName TestService -ReservedIPName MyReservedIP -Location "Central US"

# cloud service reserved IP (existing CS)
New-AzureReservedIP –ReservedIPName MyReservedIP –Location "Central US" -ServiceName TestService

# remove reserved IP from cloud service
Remove-AzureReservedIPAssociation -ReservedIPName MyReservedIP -ServiceName TestService

#endregion

#region Stop, deallocate, and remove VMs

$vm1Name = 'dc1'
$vm2Name = 'mem1'

#Stop the VM and force deallocate
Stop-AzureVM -ServiceName $svcname -Name $vm1Name -Force
Stop-AzureVM -ServiceName $svcname -Name $vm2Name -Force

#Remove a VM and delete VHD(s) - does not delete the cloud service
Remove-AzureVM -ServiceName $svcname -Name $vm1Name -DeleteVHD
Remove-AzureVM -ServiceName $svcname -Name $vm2Name -DeleteVHD

#endregion

