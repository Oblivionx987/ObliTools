## Prompt the user for asset tag
$UserInput = Read-Host "Please Input Asset Tag" 

## FUNCTIONS
function Red {
     process { Write-Host $_ -ForegroundColor Red }
    }
function Green {
     process { Write-Host $_ -ForegroundColor Green }
    }
function Blue   { 
    process { Write-Host $_ -ForegroundColor Blue}
}

## Display Input results
Write-Output "Asset Tag: $UserInput" | Red

## Display nslookup
nslookup $UserInput | Blue

## Attempt to locate machine via active directory
Get-AdComputer -Identity "$UserInput" 

## Resolve DNS and get the IP Address
Resolve-DnsName -Name "$UserInput" 
$dnsResult = Resolve-DnsName -Name "$UserInput" 
foreach ($entry in $dnsResult) {
    if ($entry.QueryType -eq "A") {
        $ip1Address = $entry.IPAddress
        Write-Output "Located $UserInput on IPv4 Address $ip1Address" | Green
    }
}

## Display Asset to be pinged
Write-Output "Begining Ping test to: $UserInput" | Red

## Ping the Asset
ping $UserInput | Blue

## Display the Ip Address
$pingResult = Test-NetConnection -ComputerName $UserInput
$ip2Address = $pingResult.RemoteAddress
Write-Output "Located $UserInput on IPv4 Address $ip2Address" | Green

tracert $UserInput | Blue


param(
    [Parameter(Mandatory=$true)]
    [string]$MachineIP
)

function Test-IsMachineOnline {
    param(
        [Parameter(Mandatory=$true)]
        [string]$IPAddress
    )

    $pingStatus = Test-Connection -ComputerName $IPAddress -Count 2 -Quiet
    return $pingStatus
}

function Open-BomgarAndConnect {
    param(
        [Parameter(Mandatory=$true)]
        [string]$IPAddress
    )

    # Your code/logic to open Bomgar and connect to $IPAddress goes here.
    # Example: Start-Process "Path\To\Bomgar.exe" -ArgumentList "your_arguments_here"
    Write-Host "Logic to open Bomgar and connect to $IPAddress should be implemented here." -ForegroundColor Yellow
}

if (Test-IsMachineOnline -IPAddress $MachineIP) {
    Write-Host "Machine $MachineIP is online. Attempting to connect via Bomgar..." -ForegroundColor Green
    Open-BomgarAndConnect -IPAddress $MachineIP
} else {
    Write-Host "Machine $MachineIP is offline. Cannot connect via Bomgar." -ForegroundColor Red
}

Read-Host -Prompt "Press any key to exit"