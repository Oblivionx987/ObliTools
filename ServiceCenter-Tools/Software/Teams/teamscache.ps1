$OutlookRunning = get-process outlook -erroraction silentlycontinue
$TeamsRunning = get-process teams -erroraction silentlycontinue
if ($OutlookRunning -gt $null)
{echo "Stopping Outlook..."
taskkill /im outlook.exe /f > $null}
start-sleep -seconds 4
if ($TeamsRunning -gt $null)
{echo "Stopping Teams..."
taskkill /im teams.exe /f > $null}
start-sleep -seconds 4
if (Test-Path -Path "$env:AppData\Microsoft\Teams")
{echo "Clearing Teams cache..."
remove-item -path "$env:AppData\Microsoft\Teams" -recurse}
echo "Reopening programs..."
start-sleep -seconds 4
start-process -file "$env:LOCALAPPDATA\Microsoft\Teams\update.exe" -ArgumentList '--processStart "Teams.exe"'
start-process outlook
exit