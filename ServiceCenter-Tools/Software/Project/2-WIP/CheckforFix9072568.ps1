# Script provided as is, no warranty.
# Get in touch: www.theprojectgroup.com - Your Project Experts
#
# [HKEY_CURRENT_USER\Software\Microsoft\Office\16.0\MS Project\Settings]
# "Fix9072568"=dword:00000001
# Confirmed to work with August 13, 2024 - Microsoft® Project 2019 MSO (Version 2407 Build 16.0.17830.20166) 64-bit.
# Probably caused by the fix for CVE-2024-38189: Microsoft Project Remote Code Execution vulnerability

# Powershell

try {
    if((Get-ItemPropertyValue -LiteralPath 'HKCU:\Software\Microsoft\Office\16.0\MS Project\Settings' -Name 'Fix9072568' -ea SilentlyContinue) -eq 1)
    {
        exit 0
    }
    else{
        exit 1
    }
}
catch{
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
