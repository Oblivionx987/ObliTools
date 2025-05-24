

$live = "WIP"
$bmgr = "WIP"




$description = "PowerShell script to set Adobe Acrobat Reader as the default PDF handler"

# Ensure the script is run with administrative privileges
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Please run this script as an Administrator!"
    Break
}

# Define the path to the Adobe Acrobat Reader executable
$adobePath = "Path\To\Adobe\Acrobat\Reader\Executable.exe"

# Set the registry values
$classesRoot = "HKCU:\Software\Classes"
$extension = ".pdf"

# Create registry entries for Adobe Acrobat Reader
New-Item -Path "$classesRoot\$extension" -Force
New-ItemProperty -Path "$classesRoot\$extension" -Name "(Default)" -Value "AcroExch.Document.DC" -Force

New-Item -Path "$classesRoot\AcroExch.Document.DC" -Force
New-ItemProperty -Path "$classesRoot\AcroExch.Document.DC" -Name "(Default)" -Value "Adobe Acrobat Document" -Force

New-Item -Path "$classesRoot\AcroExch.Document.DC\Shell\Open\Command" -Force
New-ItemProperty -Path "$classesRoot\AcroExch.Document.DC\Shell\Open\Command" -Name "(Default)" -Value "`"$adobePath`" `"%1`"" -Force

# Notify Windows about the change
$null = New-Object -ComObject Shell.Application
$null.Namespace(0).Self.InvokeVerb("refresh")

Write-Host "Adobe Acrobat Reader is now set as the default PDF handler."