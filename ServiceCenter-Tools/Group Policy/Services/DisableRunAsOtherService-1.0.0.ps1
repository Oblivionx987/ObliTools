Powershell

#region Script Info
$Script_Name = "DisableRunAsOtherService-1.0.0.ps1"
$Description = "This script will disable the Service Seconday Login which affects a users ability to run as other user"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "5.0.0"
$live = "Live"
$bmgr = "Live"
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

# Get the service object for "Secondary Logon"
$service = Get-Service -Name "seclogon"

# Check if the service exists
if ($service -ne $null) {
    # Change the startup type to "Automatic"
    Set-Service -Name "seclogon" -StartupType Disabled
    
    # Start the service if it is not already running
    if ($service.Status -ne 'Running') {
        Start-Service -Name "seclogon"
    }
    
    Write-Output "The 'Secondary Logon' service has been Disabled" | Green
} else {
    Write-Output "The 'Secondary Logon' service was not found on this system." | Red
}


