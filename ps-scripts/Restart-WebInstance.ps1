<# 
.Synopsis
   .
.DESCRIPTION
   This is a script created by David Burg to recycle Web Instances
   https://blogs.msdn.microsoft.com/david_burgs_blog/2018/07/11/powershell-script-to-restart-role-instances-for-webapp/
.EXAMPLE
   ./Restart-WebInstance.ps1 <webapp_name>
#>

Param( [Parameter(Mandatory=$True)][string]$webAppName )


$webApp = Get-AzureRmWebApp -Name $webAppName
$rgGroup = $webApp.ResourceGroup

$webSiteInstances = @()

#This gives you list of instances
$webSiteInstances = Get-AzureRmResource -ResourceGroupName $rgGroup -ResourceType Microsoft.Web/sites/instances -ResourceName $webAppName -ApiVersion 2015-11-01 

$sub = (Get-AzureRmContext).Subscription.SubscriptionId 

foreach ($instance in $webSiteInstances)
{
    $instanceId = $instance.Name
    "Going to enumerate all processes on {0} instance" -f $instanceId 

    # This gives you list of processes running
    # on a particular instance
    $processList =  Get-AzureRmResource `
                    -ResourceId /subscriptions/$sub/resourceGroups/$rgGroup/providers/Microsoft.Web/sites/$webAppName/instances/$instanceId/processes `
                    -ApiVersion 2015-08-01 

    foreach ($process in $processList)
    {               
        if ($process.Properties.Name -eq "w3wp")
        {            
            $resourceId = "/subscriptions/$sub/resourceGroups/$rgGroup/providers/Microsoft.Web/sites/$webAppName/instances/$instanceId/processes/" + $process.Properties.Id            
            $processInfoJson = Get-AzureRmResource -ResourceId  $resourceId  -ApiVersion 2015-08-01

            # is_scm_site is a property which is set
            # on the worker process for the KUDU 

            $computerName = $processInfoJson.Properties.Environment_variables.COMPUTERNAME

            if ($processInfoJson.Properties.is_scm_site -ne $true)
            {
                $computerName = $processInfoJson.Properties.Environment_variables.COMPUTERNAME
                "Instance ID" + $instanceId  + "is for " +   $computerName

                "Going to stop this process " + $processInfoJson.Name + " with PID " + $processInfoJson.Properties.Id

                # Remove-AzureRMResource finally STOPS the worker process
                $result = Remove-AzureRmResource -ResourceId $resourceId -ApiVersion 2015-08-01 -Force 

                if ($result -eq $true)
                { 
                    "Process {0} stopped " -f $processInfoJson.Properties.Id
                }

                "Sleep for 5 minutes"
                Start-Sleep -s 300
            }
       }
    }
}