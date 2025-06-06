$author = "Seth Burns - System Administrator II - Service Center"
$description = "This script will check active directory for missing assigned numbers"
$live = "Restriced"
$Version = "1.0.0"
$bmgr = "Restricted"





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
