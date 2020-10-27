<#
.SYNOPSIS
Written By John Lewis
email: jonos@live.com
Ver 1.0
This script outputs a csv file (skus-date.csv) of all Azure Market Place Images available in a Region. The script uses the directory it is executed from to create the Publisher.csv, Offers.csv and Skus.csv (which contains the final list of images). The Offers.csv and the Publishers.csv are temporary files and will removed when the script finishes processing.

.DESCRIPTION

.PARAMETER skus

.PARAMETER Publishers

.PARAMETER Offers

.PARAMETER Profile

.PARAMETER Location

.EXAMPLE
\.Get-MarketPlaceImages-csv.ps1 -Location EastUs
#>

[CmdletBinding()]
Param(
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
$skus = 'sku',
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
$Publishers = 'Publishers',
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
$Offers = 'Offers',
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
$Profile = 'profile',
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
$Location = 'WestUs'

)
# Global
$date = Get-Date -UFormat "%Y-%m-%d"
$workfolder = Split-Path $script:MyInvocation.MyCommand.Path
$CSVPublisher = $workfolder+'\'+$Publishers+'.csv'
$CSVOffers = $workfolder+'\'+$Offers+'.csv'
$CSVSKUs = $workfolder+'\'+$Skus+'-'+$date+'.csv'
$ProfileFile = $workfolder+'\'+$profile+'.json'

Function validate-profile {
$comparedate = (Get-Date).AddDays(-14)
$fileexist = Test-Path $ProfileFile -NewerThan $comparedate
  if($fileexist)
  {
  Select-AzureRmProfile -Path $ProfileFile | Out-Null
  }
  else
  {
  Write-Host "Please enter your credentials"
  Add-AzureRmAccount
  Save-AzureRmProfile -Path $ProfileFile -Force
  Write-Host "Saved Profile to $ProfileFile"
	continue
  }
}

Function Verify-AzureVersion {
$name='Azure'
if(Get-Module -ListAvailable |
	Where-Object { $_.name -eq $name })
{
$ver = (Get-Module -ListAvailable | Where-Object{ $_.Name -eq $name }) |
	select version -ExpandProperty version
	Write-Host "current Azure PowerShell Version:" $ver
$currentver = $ver
	if($currentver-le '2.0.0'){
	Write-Host "expected version 2.0.1 found $ver" -ForegroundColor DarkRed
	exit
	}
}
else
{
	Write-Host “The Azure PowerShell module is not installed.”
	exit
}
}

Verify-AzureVersion
validate-profile

if(Test-Path -Path $CSVPublisher)
{ Remove-Item -Path $CSVPublisher -Force }

if(Test-Path -Path $CSVOffers)
{ Remove-Item -Path $CSVOffers -Force }

Write-Host "Getting Publisher Info...."
Get-AzureRmVMImagePublisher -Location $Location | Select-Object PublisherName | Export-csv -Path $CSVPublisher -NoTypeInformation
Write-Host "Getting Offer Info...."
import-csv -Path $CSVPublisher -Delimiter ',' | ForEach-Object{Get-AzureRmVMImageOffer -Location $Location -PublisherName $_.PublisherName} | Export-csv -Path $CSVOffers -NoTypeInformation -Append
Write-Host "Getting SKU Info...."
import-csv -Path $CSVOffers -Delimiter ',' | ForEach-Object{Get-AzureRmVMImageSku -Location $Location -PublisherName $_.PublisherName -Offer $_.Offer } | Export-csv -Path $CSVSKUs -NoTypeInformation -Append

Remove-Item -Path $CSVPublisher -Force
Remove-Item -Path $CSVOffers -Force