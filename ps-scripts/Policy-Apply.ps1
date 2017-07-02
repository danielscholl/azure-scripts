<# Copyright (c) 2017, cloudcodeit.com
.Synopsis
   Applys Policies to a Subscription
.DESCRIPTION
   This script will apply a policy onto the current subscription
.EXAMPLE
   ./Policy-Apply.ps1 <your_unique_string>
#>

param([string]$unique = $(throw "Unique Parameter required."),
  [string]$Prefix = "policy-")

$Suffix = "-" + $unique

$Context = Get-AzureRmContext
$SubName = $Context.Subscription.SubscriptionName
$Scope = "/subscriptions/" + $Context.Subscription.SubscriptionId
Write-Output "Policies applying to: $SubName"

$Policies = @()
$Policies += , @("approved-regions", "Allow only approved regions", "$PSScriptRoot\..\policies\approved-regions.json")
$Policies += , @("approved-storageSKUs", "Allow only approved storage SKUs", "$PSScriptRoot\..\policies\approved-storageSku.json")
$Policies += , @("require-storageEncryption", "Require Storage Encryption to be on", "$PSScriptRoot\..\policies\require-storageEncryption.json")

foreach ($Item in $Policies.GetEnumerator()) {
  $Name = $Item[0]
  $Description = $Item[1]
  $Policy = $Item[2]

  Write-Output "Creating Policy Definition: $Name"
  $Definition = New-AzureRmPolicyDefinition -Name $Name `
    -Description $Description `
    -Policy $Policy

  Write-Output "Creating Policy Assignment: $Prefix$Name$Suffix"
  $Result = New-AzureRmPolicyAssignment -Name "$Prefix$Name$Suffix" `
    -PolicyDefinition $Definition `
    -Scope $Scope
}
