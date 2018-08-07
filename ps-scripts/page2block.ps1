<#
.SYNOPSIS
  Page Blob to Block Blob Copy Script
.DESCRIPTION
  Using a Data Factory copy a blob from one place to another

  ** DOWNLOAD IT  **
  $url = "https://gist.githubusercontent.com/danielscholl/d9f26bb5ae13980ad5f09ece7582fccd/raw/fb3447098251838a9a5c9fdb94c745e86339cfca/page2block.ps1"
  Invoke-WebRequest -Uri $url -OutFile page2block.ps1

  This Script requires the following environment variables to be set.
  $Env:AZURE_SUBSCRIPTION = ""     #  Azure Subscription ID
  $Env:AZURE_STORAGE_GROUP = ""    #  Storage Account Resource Group      
  $Env:AZURE_STORAGE_NAME = ""     #  Storage Account Name
.EXAMPLE
  .\page2block.ps1 -ContainerSource "input" -ContainerDest "output"
  Version History
  v1.0   - Initial Release
#>
#Requires -Version 5.1
#Requires -Module @{ModuleName='AzureRM.Resources'; ModuleVersion='5.0'}

Param(
  [string]$Subscription = $env:AZURE_SUBSCRIPTION,
  [string]$StorageGroup = $env:AZURE_STORAGE_GROUP,
  [string]$StorageAccountName = $env:AZURE_STORAGE_NAME,

  [string]$ResourceGroupName = "page2block",
  [string]$TempDir = "temp",

  [Parameter(Mandatory = $true)]
  [string]$ContainerSource,

  [Parameter(Mandatory = $true)]
  [string]$ContainerDest
)

Get-ChildItem Env:AZURE*

if ( !$Subscription) { throw "env:AZURE_SUBSCRIPTION not set" }
if ( !$StorageGroup) { throw "env:AZURE_STORAGE_GROUP not set" }
if ( !$StorageAccountName) { throw "env:AZURE_STORAGE_NAME not set" }
if(!(Test-Path $TempDir)) { New-Item -ItemType Directory -Force -Path $TempDir }


###############################
## FUNCTIONS                 ##
###############################
function Write-Color([String[]]$Text, [ConsoleColor[]]$Color = "White", [int]$StartTab = 0, [int] $LinesBefore = 0, [int] $LinesAfter = 0, [string] $LogFile = "", $TimeFormat = "yyyy-MM-dd HH:mm:ss") { 
  $DefaultColor = $Color[0]
  if ($LinesBefore -ne 0) {  for ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline } } # Add empty line before
  if ($StartTab -ne 0) {  for ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewLine } }  # Add TABS before text
  if ($Color.Count -ge $Text.Count) {
    for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine }
  }
  else {
    for ($i = 0; $i -lt $Color.Length ; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine }
    for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $DefaultColor -NoNewLine }
  }
  Write-Host
  if ($LinesAfter -ne 0) {  for ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host "`n" } }  # Add empty line after
  if ($LogFile -ne "") {
    $TextToFile = ""
    for ($i = 0; $i -lt $Text.Length; $i++) {
      $TextToFile += $Text[$i]
    }
    Write-Output "[$([datetime]::Now.ToString($TimeFormat))]$TextToFile" | Out-File $LogFile -Encoding unicode -Append
  }
}
function Get-ScriptDirectory {
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}
function UniqueString ([string]$ResourceGroupName, $length=13)
{
  $id = $(Get-AzureRmResourceGroup $ResourceGroupName).ResourceID
  $hashArray = (new-object System.Security.Cryptography.SHA512Managed).ComputeHash($id.ToCharArray())
    -join ($hashArray[1..$length] | ForEach-Object { [char]($_ % 26 + [byte][char]'a') })
}
function LoginAzure() {
  Write-Color -Text "Logging in and setting subscription..." -Color Green
  if ([string]::IsNullOrEmpty($(Get-AzureRmContext).Account)) {
    if ($env:AZURE_TENANT) {
      Login-AzureRmAccount -TenantId $env:AZURE_TENANT
    }
    else {
      Login-AzureRmAccount
    }
  }
  Set-AzureRmContext -SubscriptionId ${Subscription} | Out-null
}
function CreateResourceGroup([string]$ResourceGroupName, [string]$Location) {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = LOCATION

  Get-AzureRmResourceGroup -Name $ResourceGroupName -ev notPresent -ea 0 | Out-null

  if ($notPresent) {

    Write-Host "Creating Resource Group $ResourceGroupName..." -ForegroundColor Yellow
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
  }
  else {
    Write-Color -Text "Resource Group ", "$ResourceGroupName ", "already exists." -Color Green, Red, Green
  }
}
function GetStorageAccountKey([string]$ResourceGroupName, [string]$StorageAccountName) {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = STORAGE_ACCOUNT

  if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }
  if ( !$StorageAccountName) { throw "StorageAccountName Required" }

  return (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName).Value[0]
}
function ListBlobs([string]$ResourceGroupName, [string]$StorageAccountName, [string]$ContainerName) {
  Write-Color -Text "`r`n---------------------------------------------------- "-Color Yellow
  Write-Color -Text "Blob Listing for the ", "$ContainerName ", "container." -Color Green, Red, Green
  Write-Color -Text "---------------------------------------------------- "-Color Yellow

  $Keys = Get-AzureRmStorageAccountKey -Name $StorageAccountName -ResourceGroupName $ResourceGroupName
  $StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $Keys[0].Value
  Get-AzureStorageBlob -Context $StorageContext -Container $ContainerName | Select-Object -Property  Name, BlobType, Length | Format-Table -AutoSize
}
function CreateContainer ([string]$ResourceGroupName, [string]$StorageAccountName, [string]$ContainerName, $Access = "Off") {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = CONTAINER_NAME

  # Get Storage Account
  $StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
  if (!$StorageAccount) {
    Write-Error -Message "Storage Account in $ResourceGroupName not found. Please fix and continue"
    return
  }

  $Keys = Get-AzureRmStorageAccountKey -Name $StorageAccount.StorageAccountName -ResourceGroupName $ResourceGroupName
  $StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccount.StorageAccountName -StorageAccountKey $Keys[0].Value

  $Container = Get-AzureStorageContainer -Name $ContainerName -Context $StorageContext -ErrorAction SilentlyContinue
  if (!$Container) {
    Write-Warning -Message "Storage Container $ContainerName not found. Creating the Container $ContainerName"
    New-AzureStorageContainer -Name $ContainerName -Context $StorageContext -Permission $Access
  }
}
function CreateDataFactory([string]$FactoryName, [string]$ResourceGroupName, [string]$Location) {
  # Required Argument $1 = FACTORY_NAME
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = LOCATION
    
  Get-AzureRmDataFactoryV2 -Name $FactoryName -ResourceGroupName $ResourceGroupName -ev notPresent -ea 0 | Out-null

  if ($notPresent) {

      Write-Host "Creating Data Factory $FactoryName..." -ForegroundColor Yellow
      Set-AzureRmDataFactoryV2 -Name $DataFactoryName `
      -ResourceGroupName $ResourceGroupName `
      -Location $Location
    }
    else {
      Write-Color -Text "Data Factory ", "$FactoryName ", "already exists." -Color Green, Red, Green
    }
}
function ImportPipeline([string]$PipelineName, [string]$FactoryName, [string]$ResourceGroupName, [string]$FilePath) {
  # Required Argument $1 = PIPELINE_NAME
  # Required Argument $2 = FACTORY_NAME
  # Required Argument $3 = RESOURCE_GROUP
  # Required Argument $4 = ARTIFACT_PATH

  $LinkedService = "${FilePath}\LinkedService.json"
  $DataSet = "${FilePath}\DataSet.json"
  $Pipeline = "${FilePath}\Pipeline.json"

  Write-Color -Text "Importing LinkedService using file: ", "$LinkedService" -Color Green, Red
  Set-AzureRmDataFactoryV2LinkedService -Name "AzureStorageLinkedService" `
  -File $LinkedService `
  -DataFactoryName $FactoryName `
  -ResourceGroupName $ResourceGroupName | Out-null

  Write-Color -Text "Importing DataSet using file: ", "$DataSet" -Color Green, Red
  Set-AzureRmDataFactoryV2Dataset -Name "BlobDataset" `
    -File $DataSet `
    -DataFactoryName $FactoryName `
    -ResourceGroupName $ResourceGroupName | Out-null

  Write-Color -Text "Creating PipeLine ", $PipelineName, " using file: ", "$Pipeline" -Color Green, Red, Green, Red
  Set-AzureRmDataFactoryV2Pipeline -Name $PipelineName `
    -File $Pipeline `
    -DataFactoryName $FactoryName `
    -ResourceGroupName $ResourceGroupName | Out-null
}
function ExecutePipeline([string]$PipelineName, [string]$FactoryName, [string]$ResourceGroupName, [string]$FilePath) {
  # Required Argument $1 = PIPELINE_NAME
  # Required Argument $2 = FACTORY_NAME
  # Required Argument $3 = RESOURCE_GROUP
  # Required Argument $4 = ARTIFACT_PATH

  $Parameters = "${FilePath}\Parameters.json"

  Write-Color -Text "`r`n---------------------------------------------------- "-Color Yellow
  Write-Color -Text "Executing ", "$PipelineName ", "pipeline." -Color Green, Red, Green
  Write-Color -Text "---------------------------------------------------- "-Color Yellow
  
  $Id = Invoke-AzureRmDataFactoryV2Pipeline -PipelineName $PipelineName `
  -ParameterFile $Parameters `
  -DataFactoryName $FactoryName `
  -ResourceGroupName $ResourceGroupName

  while ($True) {
    $Result = Get-AzureRmDataFactoryV2ActivityRun -DataFactoryName $FactoryName `
      -ResourceGroupName $ResourceGroupName `
      -PipelineRunId $Id -RunStartedAfter (Get-Date).AddMinutes(-30) -RunStartedBefore (Get-Date).AddMinutes(30)
  
    if (($Result | Where-Object { $_.Status -eq "InProgress" } | Measure-Object).count -ne 0) {
      Write-Color -Text "Status: In Progress " -Color Cyan
      Start-Sleep -Seconds 30
    }
    else {
      Write-Color -Text "Execution Completed  ", $PipelineName -Color Green, Red
      Write-Color -Text "---------------------------------------------------- "-Color Yellow
      $Result
      break
    }
  }  
  # Get the activity run details
  $result = Get-AzureRmDataFactoryV2ActivityRun -DataFactoryName $FactoryName `
    -ResourceGroupName $ResourceGroupName `
    -PipelineRunId $Id `
    -RunStartedAfter (Get-Date).AddMinutes(-10) `
    -RunStartedBefore (Get-Date).AddMinutes(10) `
    -ErrorAction Stop
  
  $result
  if($result.Status -eq "Succeeded") { $result.Output -join "`r`n"}
  else {$result.Error -join "`r`n"}
}

## Retrieve Storage Key
$StorageAccountKey = GetStorageAccountKey $StorageGroup $StorageAccountName

###############################
## JSON DEFINITIONS          ##
###############################
@"
{
    "name": "AzureStorageLinkedService",
    "properties": {
        "type": "AzureStorage",
        "typeProperties": {
            "connectionString": {
                "value": "DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$StorageAccountKey",
                "type": "SecureString"
            }
        }
    }
}
"@ | Out-File "${TempDir}\LinkedService.json"

@"
{
    "name": "BlobDataset",
    "properties": {
        "type": "AzureBlob",
        "typeProperties": {
            "folderPath": {
                "value": "@{dataset().path}",
                "type": "Expression"
            }
        },
        "linkedServiceName": {
            "referenceName": "AzureStorageLinkedService",
            "type": "LinkedServiceReference"
        },
        "parameters": {
            "path": {
                "type": "String"
            }
        }
    }
}
"@ | Out-File "${tempDir}/Dataset.json"

@"
{
    "name": "$pipelineName",
    "properties": {
        "activities": [
            {
                "name": "CopyFromBlobToBlob",
                "type": "Copy",
                "inputs": [
                    {
                        "referenceName": "BlobDataset",
                        "parameters": {
                            "path": "@pipeline().parameters.inputPath"
                        },
                    "type": "DatasetReference"
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "BlobDataset",
                        "parameters": {
                            "path": "@pipeline().parameters.outputPath"
                        },
                        "type": "DatasetReference"
                    }
                ],
                "typeProperties": {
                    "source": {
                        "type": "BlobSource"
                    },
                    "sink": {
                        "type": "BlobSink"
                    }
                }
            }
        ],
        "parameters": {
            "inputPath": {
                "type": "String"
            },
            "outputPath": {
                "type": "String"
            }
        }
    }
}
"@ | Out-File "${tempDir}/Pipeline.json"

@"
{
    "inputPath": "$ContainerSource",
    "outputPath": "$ContainerDest"
}
"@ | Out-File "${tempDir}/Parameters.json"



###############################
## Implementation            ##
###############################
LoginAzure

# Set Variables Up
$BASE_DIR = Get-ScriptDirectory
$Location = (Get-AzureRmResourceGroup -ResourceGroupName $StorageGroup).Location
$Parameters = @{}
$Parameters.add('inputPath', $ContainerSource)
$Parameters.add('outputPath', $ContainerDest)
$PipelineName = "Page2Block"


ListBlobs $StorageGroup $StorageAccountName $ContainerSource
CreateContainer $StorageGroup $StorageAccountName $ContainerDest
CreateResourceGroup $ResourceGroupName $Location


$DataFactoryName = "factory-$(UniqueString $ResourceGroupName)"
CreateDataFactory $DataFactoryName $ResourceGroupName $Location
ImportPipeline $PipelineName $DataFactoryName $ResourceGroupName "${BASE_DIR}\$TempDir"
ExecutePipeline $PipelineName $DataFactoryName $ResourceGroupName "${BASE_DIR}\$TempDir"


ListBlobs $StorageGroup $StorageAccountName $ContainerDest

### Comment out the following if you want to preserve the datafactory after the copy.
if(!(Test-Path $TempDir)) { Remove-Item $TempDir -Force  -Recurse -ErrorAction SilentlyContinue }
Remove-AzureRmResourceGroup -ResourceGroupName $ResourceGroupName
