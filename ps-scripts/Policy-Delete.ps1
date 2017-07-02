<# Copyright (c) 2017, cloudcodeit.com
.Synopsis
   Remove Policies from a Subscription
.DESCRIPTION
   This script will remove a policy from  the current subscription
.EXAMPLE
   ./Policy-Delete.ps1
#>

$Context = Get-AzureRmContext
$SubName = $Context.Subscription.SubscriptionName
$SubId = $Context.Subscription.SubscriptionId
Write-Output "Removing all Policies applying to: $SubName"


# Get all of the policy assignments with subscription scope.
$Scope = "/subscriptions/$SubId"
$Assignments = Get-AzureRmPolicyAssignment -Scope $Scope


# Iterate through each and delete.
foreach ($Policy in $Assignments) {
  $Name = $Policy.Name
  Write-Output "Deleting Policy Assignment: $Name"
  $Result = Remove-AzureRmPolicyAssignment `
    -Name $Name `
    -Scope $Scope `
    -ErrorAction SilentlyContinue
}

# Get and delete all of the policy definitions. Skip over the built in policy definitions.
$Definitions = Get-AzureRmPolicyDefinition

foreach ($Policy in $Definitions) {
  if ($Policy.Properties.policyType -ne 'BuiltIn') {
    $Name = $Policy.Name
    Write-Output "Deleting Policy Definition: $Name"
    $Result = Remove-AzureRmPolicyDefinition `
      -Name $Name `
      -Force `
      -ErrorAction SilentlyContinue
  }
}
