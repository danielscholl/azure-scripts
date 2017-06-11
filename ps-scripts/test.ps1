
param([string]$unique = $(throw "Unique Parameter required."), [string]$bar = "bar")
Write-Host "Arg: $unique"
Write-Host "Arg: $bar"
