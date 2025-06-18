#region Script Info
$Script_Name = "Compare-SecurityPolicies.ps1"
$Description = "This script will compare two security policy files and output the differences."
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

# Compare-SecurityPolicies.ps1

param (
    [string]$file1,
    [string]$file2
)

if (-not (Test-Path $file1)) {
    Write-Error "File 1 not found: $file1"
    exit
}
if (-not (Test-Path $file2)) {
    Write-Error "File 2 not found: $file2"
    exit
}

# Read the content of both files
$content1 = Get-Content $file1
$content2 = Get-Content $file2

# Compare the contents
$comparison = Compare-Object -ReferenceObject $content1 -DifferenceObject $content2

# Output the differences
if ($comparison) {
    Write-Output "Differences found:"
    $comparison | ForEach-Object {
        if ($_.SideIndicator -eq "=>") {
            Write-Output "Only in File 2: $($_.InputObject)"
        }
        elseif ($_.SideIndicator -eq "<=") {
            Write-Output "Only in File 1: $($_.InputObject)"
        }
    }
} else {
    Write-Output "No differences found."
}
