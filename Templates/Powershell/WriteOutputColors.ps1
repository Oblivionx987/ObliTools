#region > Script Info <
$Author = "Seth Burns"
$Version = "1.0.0"
$Description = "This is a test"
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


#region > Test < 
Write-Output "This is a test" | Red
Write-Output "This is a test" | Green
Write-Output "This is a test" | Yellow
Write-Output "This is a test" | Blue
Write-Output "This is a test" | Cyan
Write-Output "This is a test" | Magenta
Write-Output "This is a test" | White
Write-Output "This is a test" | Gray
#endregion