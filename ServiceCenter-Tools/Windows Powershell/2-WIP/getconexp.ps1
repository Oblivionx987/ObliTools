# Import Active Directory module
Import-Module ActiveDirectory

# Define the number of days to check for expiring accounts
$daysToCheck = 7

# Get the current date
$currentDate = Get-Date

# Get the date after the specified number of days
$futureDate = $currentDate.AddDays($daysToCheck)

# Get all user accounts
$users = Get-ADUser -Filter * -Property Name, AccountExpirationDate

# Arrays to store expired and expiring accounts
$expiredAccounts = @()
$expiringAccounts = @()

foreach ($user in $users) {
    $expirationDate = $user.AccountExpirationDate

    if ($expirationDate) {
        if ($expirationDate -lt $currentDate) {
            # Account is expired
            $expiredAccounts += $user
        } elseif ($expirationDate -le $futureDate) {
            # Account is expiring within the specified number of days
            $expiringAccounts += $user
        }
    }
}

# Output expired accounts
Write-Output "Expired Accounts:"
$expiredAccounts | ForEach-Object {
    Write-Output "Name: $($_.Name), Expiration Date: $($_.AccountExpirationDate)" | export-csv -path c:\temp\accntsexpired.csv
}

# Output expiring accounts
Write-Output "Accounts Expiring within $daysToCheck days:"
$expiringAccounts | ForEach-Object {
    Write-Output "Name: $($_.Name), Expiration Date: $($_.AccountExpirationDate)" | export-csv -path c:\temp\accntsgoingtoexpire.csv
}
