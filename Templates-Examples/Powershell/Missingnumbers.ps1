
#region Script Info
$Script_Name = "Missingnumbers.ps1"
$Description = "This script will check active directory for missing assigned numbers"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "1.0.0"
$live = "Restricted"
$bmgr = "Restricted"
#endregion

#region Text Colors 
function Red     { process { Write-Host $_ -ForegroundColor Red }}
function Green   { process { Write-Host $_ -ForegroundColor Green }}
function Yellow  { process { Write-Host $_ -ForegroundColor Yellow }}
function Blue    { process { Write-Host $_ -ForegroundColor Blue }}
function Cyan    { process { Write-Host $_ -ForegroundColor Cyan }}
function Magenta { process { Write-Host $_ -ForegroundColor Magenta }}
function White   { process { Write-Host $_ -ForegroundColor White }}
function Gray    { process { Write-Host $_ -ForegroundColor Gray }}
#endregion

#region Main Descriptor
## START Main Descriptor
Write-Output "--------------------" | Yellow
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "$version , $last_tested" | Yellow
Write-Output "$live , $bmgr" | Yellow
Write-Output "$Description" | Yellow
Write-Output "--------------------" | Yellow
## END Main Descriptor
#endregion




# Import the Active Directory module
Import-Module ActiveDirectory

# Define the output CSV file path
$outputCsv = "C:\temp\AD_TelephoneInfo.csv"

# Get all user accounts in AD
$adUsers = Get-ADUser -Filter * -Property DisplayName, TelephoneNumber

# Create an array to hold the results
$result = @()

# Iterate through each user and check for telephone information
foreach ($user in $adUsers) {
    $userDetails = [PSCustomObject]@{
        DisplayName     = $user.DisplayName
        TelephoneNumber = $user.TelephoneNumber
    }
    
    # Add the user details to the results array
    $result += $userDetails
}

# Export the results to a CSV file
$result | Export-Csv -Path $outputCsv -NoTypeInformation

Write-Host "Telephone information has been exported to $outputCsv"
