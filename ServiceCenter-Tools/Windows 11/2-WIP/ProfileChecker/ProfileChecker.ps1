# Function to get user profiles from the registry
function Get-RegistryUserProfiles {
    $profiles = @()
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
    
    if (Test-Path $regPath) {
        $profileList = Get-ChildItem -Path $regPath
        foreach ($profile in $profileList) {
            $profileProps = Get-ItemProperty -Path $profile.PSPath
            $profiles += [PSCustomObject]@{
                Source = "Registry"
                SID = $profile.PSChildName
                Path = $profileProps.ProfileImagePath
                RegistryPath = $profile.PSPath
            }
        }
    }
    return $profiles
}

# Function to get user profiles from C:\Users
function Get-FolderUserProfiles {
    $profiles = @()
    $userFolders = Get-ChildItem -Path "C:\Users" -Directory
    
    foreach ($folder in $userFolders) {
        $profiles += [PSCustomObject]@{
            Source = "C:\Users"
            SID = $null
            Path = $folder.FullName
            RegistryPath = $null
        }
    }
    return $profiles
}

# Get profiles from both sources
$registryProfiles = Get-RegistryUserProfiles
$folderProfiles = Get-FolderUserProfiles

# Combine profiles
$allProfiles = $registryProfiles + $folderProfiles

# Display profiles
Write-Host "User Profiles Found:" -ForegroundColor Green
$allProfiles | Format-Table -AutoSize

# Export to HTML
$htmlFilePath = "UserProfiles.html"
$registryHtml = $registryProfiles | ConvertTo-Html -Property Source, SID, Path, RegistryPath -Title "Registry User Profiles"
$folderHtml = $folderProfiles | ConvertTo-Html -Property Source, SID, Path -Title "C:\Users User Profiles"

$htmlContent = @"
<html>
<head>
    <title>User Profiles Report</title>
</head>
<body>
    <h1>User Profiles Report</h1>
    <h2>Registry User Profiles</h2>
    $registryHtml
    <h2>C:\Users User Profiles</h2>
    $folderHtml
</body>
</html>
"@

$htmlContent | Out-File -FilePath $htmlFilePath

Write-Host "User profiles have been exported to $htmlFilePath" -ForegroundColor Green

Start-Process UserProfiles.html