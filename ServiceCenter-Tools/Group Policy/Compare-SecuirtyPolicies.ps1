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
