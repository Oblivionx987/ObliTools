#region Script Info
$Script_Name = ""
$Description = "Secu"
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
Write-Output "--------------------"
Write-Output "$Author" | Yellow
Write-Output "$Script_Name"
Write-Output "$version , $last_tested" | Yellow
Write-Output "$live , $bmgr"
Write-Output "$Description" | Yellow
Write-Output "--------------------"
## END Main Descriptor
#endregion


# Function to generate HTML report from security policies
function Generate-SecurityPolicyReport {
    param (
        [string]$outputDir = "C:\temp",
        [string]$outputFile = "SecurityPolicy.html",
        [string]$htmlTitle = "Local Security Policy Report"
    )

    try {
        # Get the security policy settings
        $secPolicies = Get-LocalGroupPolicy
        if (-not $secPolicies) {
            throw "No security policies found."
        }

        # Ensure the output directory exists
        if (-not (Test-Path -Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        # Convert the output to HTML format with customizable title and style
        $htmlStyle = "<style>body {font-family: Arial, sans-serif;}</style>"
        $htmlOutput = $secPolicies | ConvertTo-Html -Property Name, Setting -Head $htmlStyle -Title $htmlTitle

        # Output the HTML content to a log file
        $outputFilePath = Join-Path -Path $outputDir -ChildPath $outputFile
        $htmlOutput | Out-File -FilePath $outputFilePath -Encoding UTF8

        Write-Host "HTML report generated at $outputFilePath"
    } catch {
        Write-Error "An error occurred: $_"
        exit 1
    }
}

# Call the function to generate the report
Generate-SecurityPolicyReport

