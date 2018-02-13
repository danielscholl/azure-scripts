# Reference: http://windowsitpro.com/azure/use-powershell-change-subnet-and-ip-arm-vm


param(
  [string]$MachineRG = $(throw "MachineRG required"),
  [string]$VNetRG = $(throw "VNetRG required"),
  [string]$VMName = $(throw "VNetRG required"),
  [string]$NICName = $(throw "NICName required"),
  [string]$VNetName = $(throw "VNetName required"),
  [string]$TargetSubnet = $(throw "VNetName required")
)

$VM = Get-AzureRmVM -Name $VMName -ResourceGroupName $MachineRG

$VNET = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $VNetRG
$TarSubnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $VNET -Name $TargetSubnet

$NIC = Get-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $MachineRG
$NIC.IpConfigurations[0].Subnet.Id = $TarSubnet.Id
Set-AzureRmNetworkInterface -NetworkInterface $NIC

#Once the subnet has been set and that applied can apply the static IP address
$NIC = Get-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $MachineRG
$NIC.IpConfigurations[0].PrivateIpAddress = '10.1.1.20'
$NIC.IpConfigurations[0].PrivateIPAllocationMethod = 'Static'
#$NIC.DnsSettings.DnsServers = '10.1.1.10'
Set-AzureRmNetworkInterface -NetworkInterface $NIC