powershell.exe


#region Script Info
$Script_Name = "Establish_Connection.ps1"
$Description = "Script to attempt a forced connection for citrix vpn"
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "05-27-25"
$version = "x.x.x"
$live = "WIP"
$bmgr = "WIP"
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




# Variables
$ipv4Address = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias (Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Select-Object -ExpandProperty Name))[0].IPAddress

## Functions
function Red { process { Write-Host $_ -ForegroundColor Red }}
function Green { process { Write-Host $_ -ForegroundColor Green }}


# Function to check IP Range
function CheckIPInRange { 
    param (
        [Parameter(Mandatory=$true)]
        [string]$IP
    )
    # split the IP address into its octets
    $octets = $IP.Split(".")

    If ($octets[0] -eq "10" -and $octets[1] -eq "100") {
        Return $true
    }
    Else {
        Return $false
    }

}

#get local IP Address
$localIP = (Test-Connection -ComputerName (hostname) -Count 1).IPV4Address.IPAddressToString

# check if the local IP is in range
if (CheckIPInRange -IP $localIP) {
    Write-Output "IP Address ($localIP) is in range"
}
Else {
    Write-Output "IP Address ($localIP) is not in range" | Red
    Get-Service vpnagent
    Net stop vpnagent
    Get-Service vpnagent
    Net start vpnagent
    Get-Service vpnagent
    Write-Output "Local IPv4 Address: $ipv4Address" | Green
}
Start-Sleep 
Exit

