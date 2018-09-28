<# 
.Synopsis
   Recycle Individual Web Site Instances without recycling the entire web app pool.
.DESCRIPTION
   This script iterates through the Processes of the Web Sites in the subscription and lists the processes running and kills it
.EXAMPLE
   ./Restart-WebProcess.ps1
#>

Param( 
    [Parameter(Mandatory=$True)]
    [string]$webAppName,

    [int]$webProcessId
)

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
            if ($process.Properties.Name -eq "w3wp")
            {  
                $exeName = $process.Properties.Name
                Write-Host "`t`tEXE Name `t`t: " $exeName
     
                $processId = $process.Properties.id
                Write-Host "`t`t`tProcess ID `t: " $processId  -ForegroundColor Red

                try {                
                    $processDetails = Get-AzureRmResource -ResourceGroupName $resoureGroupName `
                                                            -ResourceType Microsoft.Web/sites/instances/processes `
                                                            -ResourceName $websiteName/$instanceName/$processId `
                                                            -ApiVersion 2018-02-01 `
                                                            -ErrorAction Ignore 
                                                             
     
                    Write-Host "`t`t`tExecutable `t: " $processDetails.Properties.file_name
                    Write-Host

                    if($webProcessId -eq $processId)
                    {
                        Write-Host "`tKilling Process Id: " $processId  -ForegroundColor Yellow
                        Remove-AzureRmResource -ResourceId $processDetails.ResourceId -ApiVersion 2018-02-01 -Force 
                    }   
                }
                catch {
                     
                }

            }  
        }
    }
}