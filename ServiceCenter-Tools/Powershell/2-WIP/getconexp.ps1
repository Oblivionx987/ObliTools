$author = "Seth Burns - System Administrator II - Service Center"
$description = "This script will check active directory for expiring accounts"
$last_tested = "5-27-2025
$live = "Restriced"
$Version = "1.0.1"
$bmgr = "Restricted"

# Import Active Directory module
Import-Module ActiveDirectory

# Define the number of days to check for password last set
$daysThreshold = 90

# Get the current date
$currentDate = Get-Date

# Get the date 90 days before the current date
$thresholdDate = $currentDate.AddDays(-$daysThreshold)

# Get all user accounts
$users = Get-ADUser -Filter * -Property Name, PasswordLastSet

# Array to store accounts with password last set 90 days ago or more
$accountsWithOldPasswords = @()

foreach ($user in $users) {
    $passwordLastSetDate = $user.PasswordLastSet

    if ($passwordLastSetDate) {
        if ($passwordLastSetDate -le $thresholdDate) {
            # Password was last set 90 days ago or more
            $accountsWithOldPasswords += $user
        }
    }
}

# Output accounts with passwords last set 90 days ago or more
if ($accountsWithOldPasswords.Count -gt 0) {
    $accountsWithOldPasswords | Select-Object Name, PasswordLastSet,
    @{Name="PasswordAgeInDays"; Expression={(New-TimeSpan -Start $_.PasswordLastSet -End $currentDate).Days}} | Export-Csv -Path "C:\temp\accountsWithOldPasswords.csv" -NoTypeInformation
    Write-Output "Accounts with passwords last set 90 days ago or more have been exported to C:\temp\accountsWithOldPasswords.csv"
} else {
    Write-Output "No accounts with passwords last set 90 days ago or more found."
}
