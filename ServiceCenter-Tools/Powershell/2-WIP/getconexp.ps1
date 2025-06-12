
#region Script Info
$Script_Name = "getconexp.ps1"
$Description = "This script will check active directory for expiring accounts"
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
