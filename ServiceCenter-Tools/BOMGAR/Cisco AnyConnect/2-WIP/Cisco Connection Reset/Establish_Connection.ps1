
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

