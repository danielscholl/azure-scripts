<# 
.Synopsis
   List Web Site Instances Processes.
.DESCRIPTION
   This script iterates through all the Web Sites in the subscription and lists the processes running
.EXAMPLE
   ./List-WebProcess.ps1
#>

Param( [Parameter(Mandatory=$True)][string]$webAppName )

$websites = Get-AzureRmResource -ResourceType Microsoft.Web/sites -Name $webAppName
 
foreach($website in $websites)
{
    $resoureGroupName = $website.ResourceGroupName  
    $websiteName = $website.Name
     
    Write-Host "Website : " -ForegroundColor Blue -NoNewline
    Write-Host $websiteName -ForegroundColor Red -NoNewline
    Write-Host " in ResourceGroup : " -ForegroundColor Blue -NoNewline
    Write-Host $resoureGroupName -ForegroundColor Red
 
    $instances = Get-AzureRmResource -ResourceGroupName $resoureGroupName `
                                     -ResourceType Microsoft.Web/sites/instances `
                                     -ResourceName $websiteName `
                                     -ApiVersion 2018-02-01
 
 
    foreach($instance in $instances)
    {
        $instanceName = $instance.Name
        Write-Host "`tVM Instance ID : " $instanceName
 
        try
        {
            $processes = Get-AzureRmResource -ResourceGroupName $resoureGroupName `
                                            -ResourceType Microsoft.Web/sites/instances/processes `
                                            -ResourceName $websiteName/$instanceName `
                                            -ApiVersion 2018-02-01 `
                                            -ErrorAction Ignore 
        }
        catch
        {
               continue
        }
         
 
        foreach($process in $processes)
        {
            $exeName = $process.Properties.Name
            Write-Host "`t`tEXE Name `t`t: " $exeName
 
            $processId = $process.Properties.id
            Write-Host "`t`t`tProcess ID `t: " $processId
 
            try {                
                $processDetails = Get-AzureRmResource -ResourceGroupName $resoureGroupName `
                                                        -ResourceType Microsoft.Web/sites/instances/processes `
                                                        -ResourceName $websiteName/$instanceName/$processId `
                                                        -ApiVersion 2018-02-01 `
                                                        -ErrorAction Ignore 
                                                         
 
                Write-Host "`t`t`tFile Name `t: " $processDetails.Properties.file_name
                Write-Host "`t`t`tCMD Line `t: " $processDetails.Properties.command_line
                Write-Host "`t`t`tComputer Name `t: " $processDetails.Properties.environment_variables.COMPUTERNAME
                 
            }
            catch {
                 
            }
            
        }
    }
}