##powershell

#region Script Info
$Script_Name = "Get-GPProcessingLogs.ps1"
$Description = "This script will gather Group Policy processing logs and export them to a zip file."
# This includes the Group Policy Service verbose logs, RSOP reports, and event logs related to Group Policy.
# The script will create a timestamped folder in C:\temp, gather the logs, and then compress them into a zip file.
# The zip file will be saved in C:\temp with the name format GPProcessLogs_<timestamp>.zip.
# The script will also clean up any temporary files created during the process. 
$Author = "Seth Burns - System Administrator II - Service Center"
$last_tested = "06-17-25"
$version = "1.0.0"
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
Write-Output "--------------------"
Write-Output "$Author" | Yellow
Write-Output "$Script_Name" | Yellow
Write-Output "$version , $last_tested" | Yellow
Write-Output "$live , $bmgr" | Yellow
Write-Output "$Description" | Yellow
Write-Output "--------------------"
## END Main Descriptor
#endregion

function Get-Timestamp {
    [CmdletBinding()]
    param()
    begin {
        $tzAbbrMap = @{
            'Pacific Standard Time' = 'PST'
            'Pacific Daylight Time' = 'PDT'
            'Central Standard Time' = 'CST'
            'Central Daylight Time' = 'CDT'
            'Eastern Standard Time' = 'EST'
            'Eastern Daylight Time' = 'EDT'
        }
        $tzAbbr = $tzAbbrMap[[System.TimeZoneInfo]::Local.Id]
    }
    process { "$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss")_$tzAbbr" }
}
function Invoke-CommandLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $ExePath,
        [Parameter(Mandatory)]
        [System.Array]
        $ExeArgs
    )
    process {
        $output = & $ExePath @ExeArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            $tempOutput = foreach ($line in $output) {
                
                $lineIsEmpty = [string]::IsNullOrWhiteSpace($line)
                if (-not $lineIsEmpty) { $line }
            }
            $formattedOutput = $tempOutput -join "`n"
            throw $formattedOutput
        }
        $output
    }
}
function Get-GPProcessingLogs {
    [CmdletBinding()]
    param()
    begin {
        # get timestamp
        $timestamp = Get-Timestamp
        $folderName = "GPProcessLogs_$timestamp"
        $savePath = "C:\temp\$folderName"
        $debugPath = 'C:\Windows\debug\usermode'
        $regPath = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Diagnostics'
    }
    
    process {
        # create folder in C:\temp if it doesn't exist
        if (-not (Test-Path -Path $savePath)) { $null = New-Item -ItemType 'Directory' -Path $savePath -Force }
        # enable Group Policy Service verbose logging
        Write-Host "Enabling Group Policy Service verbose logging..." -ForegroundColor 'Yellow'
        
        $null = New-Item -ItemType 'Directory' -Path $debugPath -Force
        $null = New-Item -Path $regPath -Force
        try {
            
            Set-ItemProperty -Path $regPath -Name 'GPSvcDebugLevel' -Value 0x00030002 -Type 'DWord'
            Write-Host "Enabling Group Policy Service verbose logging was successful." -ForegroundColor 'Green'
        }
        catch { Write-Error "Failed to enable Group Policy Service verbose logging: $_" }
        # run gpupdate /force
        Write-Host "Running gpupdate /force..." -ForegroundColor 'Yellow'
        $exePath = 'C:\Windows\System32\gpupdate.exe'
        $exeArgs = @( '/force' )
        try {
            
            $null = Invoke-CommandLine -ExePath $exePath -ExeArgs $exeArgs
            Write-Host "Running gpupdate /force was successful." -ForegroundColor 'Green'
        }
        catch { Write-Error "Failed to run gpupdate /force:`n$_" }
        finally { Remove-Variable -Name @('exePath', 'exeArgs') }
        # save RSOP report to html file
        Write-Host "Running gpresult /h $savePath\GPResult.htm..." -ForegroundColor 'Yellow'
        $exePath = 'C:\Windows\System32\gpresult.exe'
        $exeArgs = @( '/h', "$savePath\GPResult.htm" )
        try {
            
            $null = Invoke-CommandLine -ExePath $exePath -ExeArgs $exeArgs
            Write-Host "Running gpresult /h $savePath\GPResult.htm was successful." -ForegroundColor 'Green'
        }
        catch { Write-Error "Failed to run gpresult /h $savePath\GPResult.htm:`n$_" }
        finally { Remove-Variable -Name @('exePath','exeArgs') }
        # save RSOP summary report to txt file
        Write-Host "Running gpresult /r and storing in .txt file..." -ForegroundColor 'Yellow'
        $exePath = 'C:\Windows\System32\gpresult.exe'
        $exeArgs = @( '/r' )
        try {
            
            $output = Invoke-CommandLine -ExePath $exePath -ExeArgs $exeArgs
            $output | Out-File -FilePath "$savePath\GPResult.txt" -Encoding 'UTF8'
            Write-Host "Running gpresult /r and storing in .txt file was successful." -ForegroundColor 'Green'
        }
        catch { Write-Error "Failed to run gpresult /r and store in .txt file:`n$_" }
        finally { Remove-Variable -Name @('exePath','exeArgs', 'output') }
        # export GPExtensions registry keys
        Write-Host "Exporting GPExtensions registry keys..." -ForegroundColor 'Yellow'
        $exePath = 'C:\Windows\System32\reg.exe'
        $exeArgs = @(
            'export',
            'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\GPExtensions',
            "$savePath\GPExtensions.reg"
        )
        try {
            
            $null = Invoke-CommandLine -ExePath $exePath -ExeArgs $exeArgs
            Write-Host "Exporting GPExtensions registry keys was successful." -ForegroundColor 'Green'
        }
        catch { Write-Error "Failed to export GPExtensions registry keys:`n$_" }
        finally { Remove-Variable -Name @('exePath','exeArgs') }
        # export system, application, and Group Policy operation event logs
        Write-Host "Exporting Application event logs..." -ForegroundColor 'Yellow'
        $exePath = 'C:\Windows\System32\wevtutil.exe'
        $exeArgs = @(
            'export-log',
            'Application',
            "$savePath\Application.evtx",
            '/overwrite:true'
        )
        try {
            
            $null = Invoke-CommandLine -ExePath $exePath -ExeArgs $exeArgs
            Write-Host "Exporting Application event logs was successful." -ForegroundColor 'Green'
        }
        catch { Write-Error "Failed to export Application event logs:`n$_" }
        finally { Remove-Variable -Name @('exePath','exeArgs') }
        Write-Host "Exporting System event logs..." -ForegroundColor 'Yellow'
        $exePath = 'C:\Windows\System32\wevtutil.exe'
        $exeArgs = @(
            'export-log',
            'System',
            "$savePath\System.evtx",
            '/overwrite:true'
        )
        try {
            
            $null = Invoke-CommandLine -ExePath $exePath -ExeArgs $exeArgs
            Write-Host "Exporting System event logs was successful." -ForegroundColor 'Green'
        }
        catch { Write-Error "Failed to export System event logs:`n$_" }
        finally { Remove-Variable -Name @('exePath','exeArgs') }
        Write-Host "Exporting Group Policy event logs..." -ForegroundColor 'Yellow'
        $exePath = 'C:\Windows\System32\wevtutil.exe'
        $exeArgs = @(
            'export-log',
            'Microsoft-Windows-GroupPolicy/Operational',
            "$savePath\GroupPolicy.evtx",
            '/overwrite:true'
        )
        try {
            
            $null = Invoke-CommandLine -ExePath $exePath -ExeArgs $exeArgs
            Write-Host "Exporting Group Policy event logs was successful." -ForegroundColor 'Green'
        }
        catch { Write-Error "Failed to export Group Policy event logs:`n$_" }
        finally { Remove-Variable -Name @('exePath','exeArgs') }
        # copy gpsvc.log to save path
        Write-Host "Gathering Group Policy Service verbose logs..." -ForegroundColor 'Yellow'
        try {
            Copy-Item -Path "$debugPath\gpsvc.log" -Destination $savePath
            Write-Host "Gathering Group Policy Service verbose logs was successful." -ForegroundColor 'Green'
        }
        catch { Write-Error "Failed to gather Group Policy Service verbose logs: $_" }
        # stop group policy service logging
        Write-Host "Disabling Group Policy Service verbose logging..." -ForegroundColor 'Yellow'
        try {
            if (Test-Path -Path $regPath) { Remove-Item -Path $regPath -Force }
            if (Test-Path -Path "$debugPath\gpsvc.log") { Remove-Item -Path "$debugPath\gpsvc.log" -Force }
            if (Test-Path -Path $debugPath) { Remove-Item -Path $debugPath -Force }
            Write-Host "Disabling Group Policy Service verbose logging was successful" -ForegroundColor 'Green'
        }
        catch { Write-Error "Failed to disable Group Policy Service verbose logging: $_" }
        # gather all files into .zip file
        $zipDestinationPath = "C:\temp\$foldername.zip"
        Write-Host "Building zip file..." -ForegroundColor 'Yellow'
        try {
            
            Compress-Archive -Path "$savePath\*" -DestinationPath "C:\temp\$foldername.zip"
            Write-Host "Building zip file was successful. Path: $zipDestinationPath" -ForegroundColor 'Green'
        }
        catch { Write-Error "Failed to build zip file: $_" }
        # remove staging files
        Write-Host "Cleaning up left over files..." -ForegroundColor 'Yellow'
        try {
            
            if (Test-Path -Path $savePath) { Remove-Item -Path $savePath -Recurse -Force }
            Write-Host "Cleaning up left over files was successful" -ForegroundColor 'Green'
        }
        catch { Write-Error "Failed to clean up left over files: $_" }
    }
}
Get-GPProcessingLogs